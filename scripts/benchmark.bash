#!/bin/bash

set -eu

# This script is in `./scripts` directory so `./scripts/..` would be the same as `./`.
BASE_DIR=$(dirname "$0")/..

swift package -c release \
  --package-path "$BASE_DIR/Benchmarks" \
  benchmark thresholds check \
  --path "$BASE_DIR/Benchmarks/Thresholds" \
  "$@"
