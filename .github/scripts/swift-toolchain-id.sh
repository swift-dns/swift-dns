#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly source_description="${SOURCE_DESCRIPTION:?SOURCE_DESCRIPTION must name what was piped in, e.g. 'swift --version'}"

# A cache key rejects commas, which 'swift --version' prints, and the identifying part of a snapshot
# name is far shorter than the name itself, so the identity is reduced to a digest of this length.
readonly digest_length=16

sha256_of_stdin() {
  if command -v sha256sum > /dev/null 2>&1; then
    sha256sum
  elif command -v shasum > /dev/null 2>&1; then
    shasum --algorithm 256
  else
    fatal "Neither 'sha256sum' nor 'shasum' is available to digest the toolchain identity"
  fi
}

identity="$(cat)"
readonly identity

if [[ -z "${identity//[[:space:]]/}" ]]; then
  fatal "'${source_description}' produced nothing to identify the Swift toolchain with"
fi

log "Identified the Swift toolchain by '${source_description}':" "${identity}"

if ! toolchain_id="$(printf -- '%s' "${identity}" | sha256_of_stdin | cut -c "1-${digest_length}")"; then
  fatal "Failed to digest the toolchain identity of '${source_description}'"
fi
readonly toolchain_id

if [[ "${#toolchain_id}" -ne "${digest_length}" ]]; then
  fatal "Digesting '${source_description}' gave '${toolchain_id}', which is not ${digest_length} characters long"
fi

printf -- '%s\n' "toolchain-id=${toolchain_id}"
