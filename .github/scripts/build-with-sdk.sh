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

# Before retrying an install, the installer removes the Swift SDK by its ID, which in a bundle of
# several Swift SDKs, like the Wasm one, asks for a confirmation CI never gives and removes nothing.
# shellcheck disable=SC2016
readonly removal_by_sdk_id='sdk remove "$sdk_name"'
# shellcheck disable=SC2016
readonly removal_by_bundle_name='sdk remove "${sdk_filename%.tar.gz}"'

case "${sdk}" in
  static | wasm | embedded-wasm) ;;
  *) fatal "SDK must be 'static', 'wasm' or 'embedded-wasm', got '${sdk}'" ;;
esac

case "${build_mode}" in
  debug | release) ;;
  *) fatal "BUILD_MODE must be 'debug' or 'release', got '${build_mode}'" ;;
esac

log "Building with the '${sdk}' SDK on Swift ${swift_version} in ${build_mode} mode."

if ! installer="$(curl --silent --show-error --fail --location "${installer_url}")"; then
  fatal "Failed to fetch the Swift SDK installer from '${installer_url}'"
fi
readonly installer

readonly patched_installer="${installer/"${removal_by_sdk_id}"/"${removal_by_bundle_name}"}"

if [[ "${patched_installer}" == "${installer}" ]]; then
  fatal "Found no '${removal_by_sdk_id}' to replace with '${removal_by_bundle_name}' in '${installer_url}'"
fi

if [[ "${patched_installer}" == *"${removal_by_sdk_id}"* ]]; then
  fatal "Found more than one '${removal_by_sdk_id}' to replace with '${removal_by_bundle_name}' in '${installer_url}'"
fi

printf -- '%s\n' "${patched_installer}" \
  | bash -s -- \
    "--${sdk}" \
    --build-command="swift build" \
    --flags="${build_flags} -c ${build_mode}" \
    "${swift_version}"
