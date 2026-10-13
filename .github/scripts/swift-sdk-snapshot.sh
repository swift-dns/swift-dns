#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly sdk="${SDK:?SDK must be 'android', 'static' for the Static Linux SDK, 'wasm' for the WASI SDK, or 'embedded-wasm' for the Embedded Swift SDK for WASI}"
readonly swift_version="${SWIFT_VERSION:?SWIFT_VERSION must be the nightly toolchain the SDK is resolved for, e.g. 'nightly-main'}"

readonly api_root="https://www.swift.org/api/v1/install"

# 'install-and-build-with-sdk.sh' and 'skiptools/swift-android-action' both resolve the toolchain a
# nightly job builds with from these files, so the snapshot named here is the one that compiles.
case "${sdk}" in
  android | static | wasm) sdk_name="${sdk}" ;;
  embedded-wasm) sdk_name="wasm" ;;
  *) fatal "SDK must be 'android', 'static', 'wasm' or 'embedded-wasm', got '${sdk}'" ;;
esac
readonly sdk_name

if [[ "${swift_version}" != nightly-* ]]; then
  fatal "SWIFT_VERSION must name a nightly toolchain, e.g. 'nightly-main', got '${swift_version}'"
fi

readonly branch="${swift_version#nightly-}"
readonly sdk_url="${api_root}/dev/${branch}/${sdk_name}-sdk.json"

if ! sdk_json="$(curl --silent --show-error --fail --location --retry 3 "${sdk_url}")"; then
  fatal "Failed to fetch the '${sdk_name}' Swift SDK snapshots of '${branch}' from '${sdk_url}'"
fi
readonly sdk_json

if ! snapshot="$(printf -- '%s' "${sdk_json}" | jq --raw-output '.[0].dir')"; then
  fatal "Failed to read the newest '${sdk_name}' Swift SDK snapshot out of '${sdk_url}'"
fi
readonly snapshot

if [[ -z "${snapshot}" || "${snapshot}" == "null" ]]; then
  fatal "'${sdk_url}' names no '${sdk_name}' Swift SDK snapshot for '${branch}'"
fi

log "The newest '${sdk_name}' Swift SDK snapshot of '${branch}' is '${snapshot}'."

printf -- '%s\n' "${snapshot}"
