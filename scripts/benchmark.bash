#!/bin/bash

set -Eeuo pipefail

# This script is in `./scripts` directory so `./scripts/..` would be the same as `./`.
script_dir="$(dirname "${BASH_SOURCE[0]}")"
base_dir="${script_dir}/.."

swift package -c release \
  --package-path "${base_dir}/Benchmarks" \
  benchmark run \
  --path "${base_dir}/Benchmarks/Thresholds" \
  "$@"
