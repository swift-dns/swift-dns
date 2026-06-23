#!/bin/bash

set -Eeuo pipefail

script_dir="$(dirname "${BASH_SOURCE[0]}")"

force_run_paths=(
  ".github/workflows/unit-tests.yml"
  ".github/workflows/integration-tests.yml"
  ".github/workflows/nightly-tests.yml"
  ".github/scripts/check-tests-relevance.sh"
)

export TARGET_KIND="test"
export TARGET_FILTER='select(.type == "test")'
export PACKAGE_PATH="."
FORCE_RUN_PATHS="$(printf '%s\n' "${force_run_paths[@]}")"
export FORCE_RUN_PATHS

exec "${script_dir}/check-relevance.sh"
