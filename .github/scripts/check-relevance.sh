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
readonly run_id="${GITHUB_RUN_ID:?the id of the current workflow run}"
readonly run_attempt="${GITHUB_RUN_ATTEMPT:?the attempt number of the current workflow run}"
readonly runner_name="${RUNNER_NAME:-}"
readonly github_token="${GITHUB_TOKEN:?a token with 'contents: read' and 'actions: read' permissions}"
readonly job_keys="${JOB_KEYS:-}"
readonly scripts_dir="${BASH_SOURCE[0]%/*}"

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

if ! job_is_enabled="$(JOB_KEYS="${job_keys}" "${scripts_dir}/ci-config.sh")"; then
  fatal "Failed to read the ci config of '${repository}'"
fi
readonly job_is_enabled

if [[ "${job_is_enabled}" != "true" ]]; then
  log "This job is turned off for '${repository}'; skipping."
  printf 'false\n'
  exit 0
fi

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

[[ -n "${runner_name}" ]] \
  || run_and_exit "RUNNER_NAME is not set, so the current job cannot be identified"

current_run_jobs_json="$(
  github_api "repos/${repository}/actions/runs/${run_id}/attempts/${run_attempt}/jobs?per_page=100"
)" || run_and_exit "Could not fetch the jobs of the current run ${run_id}"
readonly current_run_jobs_json

# A GitHub runner only ever hosts one running job at a time, so this identifies the current job,
# matrix values included, without having to reconstruct its display name by hand.
job_name="$(
  jq -r --arg runner_name "${runner_name}" '
    [.jobs[] | select(.runner_name == $runner_name and .status == "in_progress") | .name]
    | if length == 1 then .[0] else "" end
  ' <<< "${current_run_jobs_json}"
)"
readonly job_name
[[ -n "${job_name}" ]] \
  || run_and_exit "Could not identify the current job among the jobs of run ${run_id} using runner '${runner_name}'"

parent_runs_json="$(
  github_api "repos/${repository}/actions/workflows/${workflow_file}/runs?head_sha=${parent_sha}&per_page=100"
)" || run_and_exit "Could not fetch the '${workflow_file}' runs of parent commit ${parent_sha:0:7}"
readonly parent_runs_json

mapfile -t parent_run_ids < <(jq -r '.workflow_runs[].id' <<< "${parent_runs_json}")
readonly parent_run_ids
[[ "${#parent_run_ids[@]}" -gt 0 ]] \
  || run_and_exit "No '${workflow_file}' run found for parent commit ${parent_sha:0:7}"

# A run is cancelled as a whole when a newer commit supersedes it, even though the jobs that had
# already finished did succeed, so this looks at the job instead of at the run that contains it.
for parent_run_id in "${parent_run_ids[@]}"; do
  parent_run_jobs_json="$(
    github_api "repos/${repository}/actions/runs/${parent_run_id}/jobs?per_page=100"
  )" || continue

  succeeded="$(
    jq --arg job_name "${job_name}" \
      '[.jobs[] | select(.name == $job_name and .conclusion == "success")] | length' \
      <<< "${parent_run_jobs_json}"
  )"

  if [[ "${succeeded}" -gt 0 ]]; then
    log "Both ${head_sha:0:7} and its parent ${parent_sha:0:7} are benchmark thresholds updates, and '${job_name}' succeeded on the parent in run ${parent_run_id}; skipping."
    printf 'false\n'
    exit 0
  fi
done

run_and_exit "No successful '${job_name}' job found for parent commit ${parent_sha:0:7} in ${#parent_run_ids[@]} '${workflow_file}' run(s)"
