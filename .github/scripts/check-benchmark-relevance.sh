#!/bin/bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly package_path="${1:-Benchmarks}"
readonly github_context_json="${GITHUB_OBJECT:?GITHUB_OBJECT must contain the toJson(github) context}"

# Require a pull request event
event_name="$(jq -r '.event_name' <<< "${github_context_json}")"
readonly event_name

if [[ "${event_name}" != pull_request* ]]; then
  log "Not a Pull request event: '${event_name}'; Won't check for benchmark relevance."
  printf 'true\n'
  exit 0
fi

base_sha="$(jq -r '.event.pull_request.base.sha' <<< "${github_context_json}")"
head_sha="$(jq -r '.event.pull_request.head.sha' <<< "${github_context_json}")"
readonly base_sha head_sha
[[ "${base_sha}" =~ ^[0-9a-f]{40}$ && "${head_sha}" =~ ^[0-9a-f]{40}$ ]] \
  || fatal "could not read base/head sha from github context.
base_sha: '${base_sha}'
head_sha: '${head_sha}'"

mapfile -d '' -t changed_files < <(
  git diff -z --name-only "${base_sha}...${head_sha}"
)
readonly changed_files

# - Check force-run paths
readonly force_run_paths=(
  "${package_path}/Package.swift"
  "${package_path}/Package.resolved"
  "${package_path}/Thresholds"
  ".github/workflows/benchmarks.yml"
  ".github/scripts/floor-baseline.sh"
  ".github/scripts/floor-thresholds.sh"
)

forces_benchmark_run() {
  local changed_file="${1:?forces_benchmark_run requires a changed file path}"
  local force_path

  for force_path in "${force_run_paths[@]}"; do
    if [[ "${changed_file}" == "${force_path}" || "${changed_file}" == "${force_path}"/* ]]; then
      return 0
    fi
  done
  return 1
}

for changed_file in "${changed_files[@]}"; do
  [[ -n "${changed_file}" ]] || continue

  if forces_benchmark_run "${changed_file}"; then
    log "Benchmark-forcing path changed: '${changed_file}'; will run benchmarks."
    printf 'true\n'
    exit 0
  fi
done

# - Set up to check SwiftPM target graph for modified dependencies
repo_root="$(git rev-parse --show-toplevel)"
readonly repo_root

package_dump_json="$(swift package --package-path "${package_path}" dump-package)"
readonly package_dump_json

mapfile -d '' -t local_target_names < <(
  jq --raw-output0 '.targets[].name' <<< "${package_dump_json}"
)
readonly local_target_names
[[ "${#local_target_names[@]}" -gt 0 ]] \
  || fatal "swift package dump-package found no targets in package path '${package_path}'"

is_local_target() {
  local candidate_name="${1:?is_local_target requires a target name}"
  local target_name

  for target_name in "${local_target_names[@]}"; do
    if [[ "${target_name}" == "${candidate_name}" ]]; then
      return 0
    fi
  done
  return 1
}

get_target_dependencies() {
  local target_name="${1:?get_target_dependencies requires a target name}"

  jq --raw-output0 --arg t "${target_name}" '
    .targets[]
    | select(.name == $t)
    | (.dependencies[]? | (.byName[0]? // .target[0]?) // empty),
      (.pluginUsages[]?.plugin[0] // empty)
  ' <<< "${package_dump_json}"
}

# - Get all benchmark targets
# SwiftPM dumps each plugin usage as {"plugin": [name, package]}, so .plugin[0] is the plugin name.
mapfile -d '' -t benchmark_targets < <(jq --raw-output0 '
  .targets[]
  | select(any(.pluginUsages[]?; .plugin[0] == "BenchmarkPlugin"))
  | .name
' <<< "${package_dump_json}")

if [[ "${#benchmark_targets[@]}" -eq 0 ]]; then
  log "No BenchmarkPlugin targets found among ${#local_target_names[@]} target(s) in '${package_path}': $(IFS=' '; printf '%s' "${local_target_names[*]}"); will return true just to be safe."
  printf 'true\n'
  exit 0
fi

# - Find all local dependencies of the benchmark targets
declare -A seen=()
declare -a targets_to_visit=()
for target_name in "${benchmark_targets[@]}"; do
  seen["${target_name}"]=1
  targets_to_visit+=("${target_name}")
done

for (( i = 0; i < ${#targets_to_visit[@]}; i++ )); do
  target_name="${targets_to_visit[i]}"

  while IFS= read -r -d '' dependency; do
    [[ -n "${dependency}" ]] || continue

    if [[ -z "${seen[${dependency}]:-}" ]] && is_local_target "${dependency}"; then
      seen["${dependency}"]=1
      targets_to_visit+=("${dependency}")
    fi
  done < <(get_target_dependencies "${target_name}")
done

# - Find relevant directories to targets_to_visit
declare -A relevant_directories=()
for target_name in "${targets_to_visit[@]}"; do
  target_subpath="$(
    jq -r \
      --arg t "${target_name}" \
      '.targets[] | select(.name == $t) | .path // ""' <<< "${package_dump_json}"
  )"
  target_type="$(
    jq -r \
      --arg t "${target_name}" \
      '.targets[] | select(.name == $t) | .type' <<< "${package_dump_json}"
  )"

  # Skip non-local binary targets
  if [[ "${target_type}" == "binary" && -z "${target_subpath}" ]]; then
    continue
  fi

  if [[ "${target_subpath}" == "." ]]; then
    target_dir="${package_path}"
  elif [[ -n "${target_subpath}" ]]; then
    target_dir="${package_path}/${target_subpath}"
  elif [[ "${target_type}" == "plugin" ]]; then
    target_dir="${package_path}/Plugins/${target_name}"
  else
    target_dir="${package_path}/Sources/${target_name}"
  fi
  [[ -d "${target_dir}" ]] || fatal "source directory not found for target '${target_name}': ${target_dir}"
  absolute_target_dir="$(realpath "${target_dir}")"
  relative_target_dir="${absolute_target_dir#"${repo_root}"/}"
  relevant_directories["${relative_target_dir}"]=1
done

log "Benchmark-relevant directories (${#relevant_directories[@]}), derived from benchmark targets in '${package_path}':"
for relevant_dir in "${!relevant_directories[@]}"; do log "  ${relevant_dir}/"; done

# - See if any of the directories have had any changes
declare -a matched_files=()
for changed_file in "${changed_files[@]}"; do
  [[ -n "${changed_file}" ]] || continue

  for relevant_dir in "${!relevant_directories[@]}"; do
    if [[ "${changed_file}" == "${relevant_dir}" || "${changed_file}" == "${relevant_dir}"/* ]]; then
      matched_files+=("${changed_file}")
      continue 2
    fi
  done
done

if [[ "${#matched_files[@]}" -eq 0 ]]; then
  log "No benchmark-relevant changes among ${#changed_files[@]} changed file(s) in ${base_sha:0:7}...${head_sha:0:7}; skipping."
  printf 'false\n'
  exit 0
fi

log "Benchmark-relevant changes detected (${#matched_files[@]} of ${#changed_files[@]} changed file(s) in ${base_sha:0:7}...${head_sha:0:7}):"
for changed_file in "${matched_files[@]}"; do log "  ${changed_file}"; done
printf 'true\n'
exit 0
