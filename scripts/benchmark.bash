#!/bin/bash

set -eu

# This script is in `./scripts` directory so `./scripts/..` would be the same as `./`.
SCRIPT_PATH=$(readlink -f "$0")
BASE_DIR=$(dirname "$SCRIPT_PATH")/..

swift package -c release \
  --package-path "$BASE_DIR/Benchmarks" \
  benchmark thresholds check \
  --path "$BASE_DIR/Benchmarks/Thresholds" \
  "$@"
