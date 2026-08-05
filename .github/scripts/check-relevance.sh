#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly repository="${GITHUB_REPOSITORY:?the 'owner/repo' slug, e.g. 'swift-dns/swift-dns'}"
readonly workflow_ref="${GITHUB_WORKFLOW_REF:?the workflow ref, e.g. 'swift-dns/swift-dns/.github/workflows/unit-tests.yml@refs/heads/main'}"
readonly head_sha="${HEAD_SHA:?the sha of the commit this workflow is running for}"
readonly github_token="${GITHUB_TOKEN:?a token with 'contents: read' and 'actions: read' permissions}"

# Both the benchmark and the threshold-update workflows commit with this subject prefix.
readonly benchmark_update_subject_prefix="Update of benchmark thresholds"

readonly workflow_path="${workflow_ref%%@*}"
readonly workflow_file="${workflow_path##*/}"

run_and_exit() {
  local reason="${1:?run_and_exit requires a reason}"

  log "${reason}; will run."
  printf 'true\n'
  exit 0
}

github_api() {
  local endpoint="${1:?github_api requires an api endpoint}"

  curl --silent --show-error --fail --location \
    --header "Accept: application/vnd.github+json" \
    --header "Authorization: Bearer ${github_token}" \
    --header "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/${endpoint}" \
    || return 1
  return 0
}

is_benchmark_update_commit() {
  local commit_json="${1:?is_benchmark_update_commit requires a commit json}"
  local description="${2:?is_benchmark_update_commit requires a description of the commit}"
  local author subject

  author="$(jq -r '.commit.author.name // ""' <<< "${commit_json}")"
  subject="$(jq -r '(.commit.message // "") | split("\n")[0]' <<< "${commit_json}")"
  log "${description} commit is authored by '${author}' with subject '${subject}'."

  if [[ "${author}" == *"[bot]" && "${subject}" == "${benchmark_update_subject_prefix}"* ]]; then
    return 0
  fi
  return 1
}

head_commit_json="$(github_api "repos/${repository}/commits/${head_sha}")" \
  || fatal "could not fetch commit '${head_sha}' of '${repository}'"
readonly head_commit_json

is_benchmark_update_commit "${head_commit_json}" "Head ${head_sha:0:7}" \
  || run_and_exit "Head commit ${head_sha:0:7} is not a benchmark thresholds update"

parent_sha="$(jq -r '.parents[0].sha // ""' <<< "${head_commit_json}")"
readonly parent_sha
[[ "${parent_sha}" =~ ^[0-9a-f]{40}$ ]] \
  || run_and_exit "Head commit ${head_sha:0:7} has no parent commit to compare against"

parent_commit_json="$(github_api "repos/${repository}/commits/${parent_sha}")" \
  || fatal "could not fetch commit '${parent_sha}' of '${repository}'"
readonly parent_commit_json

is_benchmark_update_commit "${parent_commit_json}" "Parent ${parent_sha:0:7}" \
  || run_and_exit "Parent commit ${parent_sha:0:7} is not a benchmark thresholds update"

parent_runs_json="$(
  github_api "repos/${repository}/actions/workflows/${workflow_file}/runs?head_sha=${parent_sha}&per_page=100"
)" || run_and_exit "Could not fetch the '${workflow_file}' runs of parent commit ${parent_sha:0:7}"
readonly parent_runs_json

parent_successful_runs="$(
  jq '[.workflow_runs[] | select(.conclusion == "success")] | length' <<< "${parent_runs_json}"
)"
readonly parent_successful_runs
[[ "${parent_successful_runs}" -gt 0 ]] \
  || run_and_exit "No successful '${workflow_file}' run found for parent commit ${parent_sha:0:7}"

log "Both ${head_sha:0:7} and its parent ${parent_sha:0:7} are benchmark thresholds updates, and '${workflow_file}' succeeded on the parent; skipping."
printf 'false\n'
exit 0
