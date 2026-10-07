#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly start_ref="${START_REF:?START_REF must be the commit or ref whose history is walked}"
readonly max_depth="${MAX_DEPTH:-100}"
readonly bot_author_suffix="[bot]"

if ! git rev-parse --verify --quiet "${start_ref}^{commit}" > /dev/null; then
  fatal "Failed to resolve '${start_ref}' to a commit"
fi

# Prints '<short-sha> <subject>' of the newest commit reachable from 'start_ref' that is not
# authored by a GitHub App or Actions bot, whose author names all end in '[bot]'.
find_latest_non_bot_commit() {
  local -a log_args=(log -z --max-count="${max_depth}" --format='%h%x1f%an%x1f%s' "${start_ref}")

  local entry short_sha author_name subject
  while IFS= read -r -d '' entry; do
    IFS=$'\x1f' read -r short_sha author_name subject <<< "${entry}"
    if [[ "${author_name}" == *"${bot_author_suffix}" ]]; then
      continue
    fi
    printf -- '%s %s' "${short_sha}" "${subject}"
    return 0
  done < <(git "${log_args[@]}")

  fatal "No commit authored by a non-bot found within ${max_depth} commits of '${start_ref}'"
}

find_latest_non_bot_commit
