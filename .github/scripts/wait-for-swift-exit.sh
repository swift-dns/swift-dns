#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly max_wait_seconds="${MAX_WAIT_SECONDS:-30}"

waited_seconds=0
while swift_processes="$(pgrep -l swift)"; do
  if [[ "${waited_seconds}" -ge "${max_wait_seconds}" ]]; then
    fatal "Swift processes were still running after ${max_wait_seconds}s:" "${swift_processes}"
  fi
  if [[ "$((waited_seconds % 10))" -eq 0 ]]; then
    log "Waiting for swift processes to exit:" "${swift_processes}"
  fi
  sleep 1
  waited_seconds=$((waited_seconds + 1))
done

log "✅ No swift processes running after waiting ${waited_seconds}s."
