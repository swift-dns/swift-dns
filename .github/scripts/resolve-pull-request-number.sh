#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly github_token="${GITHUB_TOKEN:?GITHUB_TOKEN must be a token allowed to read the pull requests of GITHUB_REPOSITORY}"
readonly repository="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be the owner/name of the repository to search, e.g. 'swift-dns/swift-dns'}"
readonly branch="${BRANCH:?BRANCH must be the head branch to find the open pull request of, e.g. 'mmbm-rfc-10029'}"
readonly api_url="${GITHUB_API_URL:-https://api.github.com}"

if [[ ! "${repository}" =~ ^[^/]+/[^/]+$ ]]; then
  fatal "GITHUB_REPOSITORY is not in 'owner/name' form: '${repository}'"
fi

readonly repository_owner="${repository%%/*}"

fetch_open_pull_requests() {
  curl --silent --show-error --fail --location --get \
    --header "Accept: application/vnd.github+json" \
    --header "Authorization: Bearer ${github_token}" \
    --header "X-GitHub-Api-Version: 2022-11-28" \
    --data-urlencode "state=open" \
    --data-urlencode "head=${repository_owner}:${branch}" \
    --data-urlencode "sort=updated" \
    --data-urlencode "direction=desc" \
    --data-urlencode "per_page=100" \
    "${api_url}/repos/${repository}/pulls"
  return "$?"
}

# GitHub answers with every open pull request when the 'head' filter has an empty owner or branch.
select_pull_requests_of_branch() {
  local response_json="${1:?select_pull_requests_of_branch requires the listed pull requests json}"

  jq --arg repository "${repository}" --arg branch "${branch}" '
    [ .[]
      | select(.state == "open")
      | select(.head.ref == $branch)
      | select(.head.repo.full_name == $repository)
    ]
    | sort_by([.updated_at, .number])
    | reverse
  ' <<< "${response_json}"
  return "$?"
}

describe_pull_requests() {
  local candidates_json="${1:?describe_pull_requests requires the matched pull requests json}"

  jq --raw-output '
    map("#\(.number) into \(.base.ref), updated at \(.updated_at)") | join(", ")
  ' <<< "${candidates_json}"
  return "$?"
}

if ! pull_requests_json="$(fetch_open_pull_requests)"; then
  fatal "Failed to list the open pull requests of '${repository}'"
fi
readonly pull_requests_json

if ! matches_json="$(select_pull_requests_of_branch "${pull_requests_json}")"; then
  fatal "Failed to narrow the pull requests of '${repository}' down to those of '${branch}'"
fi
readonly matches_json

if ! match_count="$(jq 'length' <<< "${matches_json}")"; then
  fatal "Failed to count the pull requests of '${repository}' that have '${branch}' as head"
fi
readonly match_count

if [[ "${match_count}" -eq 0 ]]; then
  log "No open pull request has '${branch}' of '${repository}' as its head branch."
  exit 0
fi

# GitHub lets a branch head only one open pull request; this logs the pick should that change.
if [[ "${match_count}" -gt 1 ]]; then
  if ! candidates="$(describe_pull_requests "${matches_json}")"; then
    fatal "Failed to describe the ${match_count} pull requests headed by '${branch}'"
  fi
  readonly candidates
  log "${match_count} open pull requests have '${branch}' as their head branch: ${candidates}"
fi

if ! pull_request_number="$(jq --raw-output '.[0].number' <<< "${matches_json}")"; then
  fatal "Failed to read the number of the pull request headed by '${branch}'"
fi
readonly pull_request_number

log "Pull request #${pull_request_number} of '${repository}' has '${branch}' as its head branch."
printf -- '%s' "${pull_request_number}"
