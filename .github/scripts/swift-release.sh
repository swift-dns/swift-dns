#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly swift_version="${SWIFT_VERSION:?SWIFT_VERSION must be the Swift release line to resolve the newest release of, e.g. '6.3'}"

readonly releases_url="https://www.swift.org/api/v1/install/releases.json"

if [[ ! "${swift_version}" =~ ^[0-9]+\.[0-9]+$ ]]; then
  fatal "SWIFT_VERSION must be a 'major.minor' Swift release line, e.g. '6.3', got '${swift_version}'"
fi

if ! releases_json="$(curl --silent --show-error --fail --location --retry 3 "${releases_url}")"; then
  fatal "Failed to fetch the Swift releases from '${releases_url}'"
fi
readonly releases_json

# 'jq' on Windows ends every line it prints with a carriage return, which '--join-output' avoids by
# printing no line end at all.
if ! release="$(
  printf -- '%s' "${releases_json}" | jq --join-output --arg line "${swift_version}" '
    [.[].name | select(test("^[0-9]+(\\.[0-9]+)+$")) | select(. == $line or startswith($line + "."))]
    | sort_by(split(".") | map(tonumber))
    | last // ""
  '
)"; then
  fatal "Failed to read the Swift releases of '${swift_version}' out of '${releases_url}'"
fi
readonly release

if [[ -z "${release}" ]]; then
  fatal "'${releases_url}' names no Swift release of '${swift_version}'"
fi

if [[ ! "${release}" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
  fatal "The newest Swift release of '${swift_version}' is named '${release}', which is not a version"
fi

log "The newest Swift release of '${swift_version}' is '${release}'."

printf -- '%s\n' "version=${release}"
