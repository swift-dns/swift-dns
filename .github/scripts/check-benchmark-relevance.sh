#!/bin/bash

set -Eeuo pipefail

script_dir="$(dirname "${BASH_SOURCE[0]}")"

force_run_paths=(
  "Benchmarks/Thresholds"
  ".github/workflows/benchmarks.yml"
  ".github/scripts/floor-baseline.sh"
  ".github/scripts/floor-thresholds.sh"
  ".github/scripts/check-benchmark-relevance.sh"
)

export TARGET_KIND="BenchmarkPlugin"
export TARGET_FILTER='select(any(.pluginUsages[]?; .plugin[0] == "BenchmarkPlugin"))'
export PACKAGE_PATH="Benchmarks"
FORCE_RUN_PATHS="$(printf '%s\n' "${force_run_paths[@]}")"
export FORCE_RUN_PATHS

exec "${script_dir}/check-relevance.sh"
