#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly build_mode="${BUILD_MODE:?BUILD_MODE must be 'debug' or 'release'}"
readonly wasmtime_version="${WASMTIME_VERSION:?WASMTIME_VERSION must be a wasmtime release, e.g. '48.0.1'}"
readonly wasmtime_sha256="${WASMTIME_SHA256:?WASMTIME_SHA256 must be the sha256 of the x86_64-linux wasmtime tarball of that release}"
readonly test_flags="${TEST_FLAGS:-}"

case "${build_mode}" in
  debug | release) ;;
  *) fatal "BUILD_MODE must be 'debug' or 'release', got '${build_mode}'" ;;
esac

readonly no_tests_found_exit_code=69 # EX_UNAVAILABLE, what a bundle returns when nothing matched

# 'swift build' repoints this symlink at the products directory of the build system it ran with.
readonly build_dir=".build/${build_mode}"
readonly wasmtime_name="wasmtime-v${wasmtime_version}-x86_64-linux"
readonly wasmtime_root="${RUNNER_TEMP:-/tmp}"
readonly wasmtime="${wasmtime_root}/${wasmtime_name}/wasmtime"

install_wasmtime() {
  local tarball="${wasmtime_root}/${wasmtime_name}.tar.xz"

  log "Installing wasmtime ${wasmtime_version}."
  curl --silent --show-error --fail --location --output "${tarball}" \
    "https://github.com/bytecodealliance/wasmtime/releases/download/v${wasmtime_version}/${wasmtime_name}.tar.xz"
  if ! printf -- '%s  %s\n' "${wasmtime_sha256}" "${tarball}" | sha256sum --check --quiet; then
    fatal "The wasmtime tarball does not match the pinned sha256"
  fi
  tar -xJf "${tarball}" -C "${wasmtime_root}"
  "${wasmtime}" --version
  return 0
}

# The native build system links one bundle per package, Swift Build one runner per test target.
mapfile -d '' -t test_bundles < <(
  find -L "${build_dir}" -maxdepth 1 -type f \
    \( -name '*PackageTests.xctest' -o -name '*-test-runner.wasm' \) -print0
)
readonly test_bundles

if [[ "${#test_bundles[@]}" -eq 0 ]]; then
  fatal "No test bundle under '${build_dir}'; build with '--build-tests' first"
fi

install_wasmtime

IFS=' ' read -r -a test_flag_words <<< "${test_flags}"
readonly test_flag_words

matched_any_test=false
for test_bundle in "${test_bundles[@]}"; do
  log "Running ${test_bundle} with wasmtime."
  bundle_exit_code=0
  "${wasmtime}" run --dir . "${test_bundle}" \
    --testing-library swift-testing "${test_flag_words[@]}" || bundle_exit_code=$?

  case "${bundle_exit_code}" in
    0) matched_any_test=true ;;
    "${no_tests_found_exit_code}") log "No test in '${test_bundle}' matched the given filters." ;;
    *) fatal "'${test_bundle}' failed with exit code ${bundle_exit_code}" ;;
  esac
done

if [[ "${matched_any_test}" == false ]]; then
  fatal "No test matched TEST_FLAGS '${test_flags}' in any of the ${#test_bundles[@]} bundle(s)"
fi
