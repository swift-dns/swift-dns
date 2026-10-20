#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly thresholds_path="${THRESHOLDS_PATH:?THRESHOLDS_PATH must point at the benchmark Thresholds directory}"
readonly base_branch="${BASE_BRANCH:-main}"
readonly summary_file="${SUMMARY_FILE:-${GITHUB_STEP_SUMMARY:-}}"
readonly max_summary_bytes="${MAX_SUMMARY_BYTES:-524288}"

if [[ ! -d "${thresholds_path}" ]]; then
  fatal "Thresholds directory not found: '${thresholds_path}'"
fi
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  fatal "Not a git repository, so the threshold changes cannot be diffed: '${PWD}'"
fi

workspace="$(mktemp -d)" || fatal "Failed to create a temporary workspace directory"
readonly workspace
trap 'rm -rf "${workspace}"' EXIT

readonly patch_file="${workspace}/thresholds.patch"

# Prints the commit the thresholds are compared against. A stale local 'origin/<branch>' is still a
# valid base to recover from, so a failed fetch only downgrades the base instead of failing the run.
resolve_base_commit() {
  local remote_ref="origin/${base_branch}"

  if ! git fetch --no-tags --quiet origin "${base_branch}"; then
    log "Could not fetch '${base_branch}' from origin; falling back to the local '${remote_ref}'."
  fi

  local resolved_commit
  if ! resolved_commit="$(git rev-parse --verify --quiet "${remote_ref}^{commit}")"; then
    fatal "Failed to resolve '${remote_ref}'; there is no base to compare thresholds against."
  fi

  printf -- '%s' "${resolved_commit}"
  return 0
}

# Writes the threshold diff against 'base_commit' to 'destination'. Threshold files the benchmark
# run created are still untracked, so they are marked intent-to-add to make 'git diff' include them.
write_threshold_patch() {
  local base_commit="${1:?write_threshold_patch requires a base commit SHA}"
  local destination="${2:?write_threshold_patch requires a destination patch file path}"

  if ! git add --intent-to-add -- "${thresholds_path}"; then
    fatal "Failed to mark the untracked threshold files under '${thresholds_path}' for diffing"
  fi

  local -a diff_args=(diff --no-color "${base_commit}" -- "${thresholds_path}")
  local diff_status=0
  git "${diff_args[@]}" > "${destination}" || diff_status="$?"

  if ! git reset --quiet -- "${thresholds_path}"; then
    log "Failed to unmark the intent-to-add threshold files; the index still holds them."
  fi

  if [[ "${diff_status}" -ne 0 ]]; then
    fatal "Failed to diff '${thresholds_path}' against ${base_commit}; git exited ${diff_status}."
  fi

  return 0
}

count_patched_files() {
  local patch_source="${1:?count_patched_files requires a patch file path}"

  grep -c -- '^diff --git ' "${patch_source}" || true
  return 0
}

# Job log copies carry per-line timestamps, so the summary copy below is the one to recover from.
print_patch_to_job_log() {
  local base_commit="${1:?print_patch_to_job_log requires a base commit SHA}"
  local patch_source="${2:?print_patch_to_job_log requires a patch file path}"

  printf -- '===== BEGIN THRESHOLD PATCH vs %s (%s) =====\n' "${base_branch}" "${base_commit}"
  cat -- "${patch_source}"
  printf -- '===== END THRESHOLD PATCH =====\n'
  return 0
}

append_patch_to_summary() {
  local base_commit="${1:?append_patch_to_summary requires a base commit SHA}"
  local patch_source="${2:?append_patch_to_summary requires a patch file path}"
  local patched_files="${3:?append_patch_to_summary requires a patched file count}"

  if [[ -z "${summary_file}" ]]; then
    log "Neither SUMMARY_FILE nor GITHUB_STEP_SUMMARY is set; skipping the summary section."
    return 0
  fi

  local heading="## Benchmark threshold changes vs '${base_branch}' (${base_commit:0:7})"
  printf -- '\n%s\n' "${heading}" >> "${summary_file}"

  if [[ "${patched_files}" -eq 0 ]]; then
    printf -- '\n%s\n' "No threshold file changes." >> "${summary_file}"
    return 0
  fi

  local patch_bytes
  patch_bytes="$(wc -c < "${patch_source}" | tr -d '[:space:]')"

  local recovery_notice
  recovery_notice="${patched_files} file(s) changed."
  recovery_notice+=" Recover them by saving the diff below as 'thresholds.patch', then:"

  {
    printf -- '\n%s\n' "${recovery_notice}"
    printf -- '\n%s\n' '```sh'
    printf -- '%s\n' "git checkout ${base_commit}"
    printf -- '%s\n' "git apply thresholds.patch"
    printf -- '%s\n' '```'
    printf -- '\n%s\n' '<details>'
    printf -- '%s\n' '  <summary> Click to expand threshold changes </summary>'
    printf -- '\n%s\n' '```diff'
  } >> "${summary_file}"

  if [[ "${patch_bytes}" -gt "${max_summary_bytes}" ]]; then
    head -c "${max_summary_bytes}" "${patch_source}" >> "${summary_file}"
    local truncation_notice
    truncation_notice="... truncated at ${max_summary_bytes} bytes of ${patch_bytes};"
    truncation_notice+=" the full patch is in the job log."
    printf -- '\n%s\n' "${truncation_notice}" >> "${summary_file}"
  else
    cat -- "${patch_source}" >> "${summary_file}"
  fi

  {
    printf -- '%s\n' '```'
    printf -- '\n%s\n' '</details>'
  } >> "${summary_file}"

  return 0
}

base_commit_sha="$(resolve_base_commit)"
readonly base_commit_sha

write_threshold_patch "${base_commit_sha}" "${patch_file}"

patched_file_count="$(count_patched_files "${patch_file}")"
readonly patched_file_count

append_patch_to_summary "${base_commit_sha}" "${patch_file}" "${patched_file_count}"

if [[ "${patched_file_count}" -eq 0 ]]; then
  log "✅ No threshold changes compared to '${base_branch}' (${base_commit_sha:0:7})."
  exit 0
fi

print_patch_to_job_log "${base_commit_sha}" "${patch_file}"

log "✅ Logged ${patched_file_count} changed threshold file(s) vs ${base_commit_sha:0:7}."
