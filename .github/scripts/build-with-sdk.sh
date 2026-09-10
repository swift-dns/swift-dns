#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly sdk="${SDK:?SDK must be 'static' for the Static Linux SDK, 'wasm' for the WASI SDK, or 'embedded-wasm' for the Embedded Swift SDK for WASI}"
readonly swift_version="${SWIFT_VERSION:?SWIFT_VERSION must be the toolchain to install, e.g. '6.3' or 'nightly-main'}"
readonly build_mode="${BUILD_MODE:?BUILD_MODE must be 'debug' or 'release'}"
readonly build_flags="${BUILD_FLAGS:?BUILD_FLAGS must be the 'swift build' flags to use, e.g. '--build-tests -Xswiftc -require-explicit-sendable'}"

readonly workflows_tag="0.0.15"
readonly installer_url="https://raw.githubusercontent.com/swiftlang/github-workflows/refs/tags/${workflows_tag}/.github/workflows/scripts/install-and-build-with-sdk.sh"

case "${sdk}" in
  static | wasm | embedded-wasm) ;;
  *) fatal "SDK must be 'static', 'wasm' or 'embedded-wasm', got '${sdk}'" ;;
esac

case "${build_mode}" in
  debug | release) ;;
  *) fatal "BUILD_MODE must be 'debug' or 'release', got '${build_mode}'" ;;
esac

log "Building with the '${sdk}' SDK on Swift ${swift_version} in ${build_mode} mode."

curl --silent --show-error --fail --location "${installer_url}" \
  | bash -s -- \
    "--${sdk}" \
    --build-command="swift build" \
    --flags="${build_flags} -c ${build_mode}" \
    "${swift_version}"
