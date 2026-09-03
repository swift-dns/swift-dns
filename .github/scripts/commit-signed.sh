#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly token="${GH_TOKEN:?GH_TOKEN must be a token allowed to write contents to REPOSITORY}"
readonly repository="${REPOSITORY:?REPOSITORY must be the owner/name of the repository to commit to, e.g. 'swift-dns/swift-dns'}"
readonly branch="${BRANCH:?BRANCH must be the branch to create the signed commit on, e.g. 'thr-update/main'}"
readonly base_sha="${BASE_SHA:?BASE_SHA must be the 40-char commit SHA the branch is force-reset to before committing}"
readonly commit_message="${COMMIT_MESSAGE:?COMMIT_MESSAGE must be the commit message; its first line becomes the headline}"
readonly work_dir="${WORK_DIR:?WORK_DIR must point at the checked-out repository holding the changes to commit}"
readonly output_file="${OUTPUT_FILE:?OUTPUT_FILE must be the file path to write 'has-changes' and 'commit-sha' to}"
readonly pathspec="${PATHSPEC-}"
readonly api_url="${GITHUB_API_URL:-https://api.github.com}"
readonly graphql_url="${GITHUB_GRAPHQL_URL:-https://api.github.com/graphql}"

if [[ ! "${repository}" =~ ^[^/]+/[^/]+$ ]]; then
  fatal "REPOSITORY is not in 'owner/name' form: '${repository}'"
fi
if [[ ! "${base_sha}" =~ ^[0-9a-f]{40}$ ]]; then
  fatal "BASE_SHA is not a 40-char commit SHA: '${base_sha}'"
fi
if [[ -z "${commit_message//[[:space:]]/}" ]]; then
  fatal "COMMIT_MESSAGE is blank; the GraphQL commit headline cannot be empty"
fi
[[ -d "${work_dir}" ]] || fatal "WORK_DIR directory does not exist: '${work_dir}'"

readonly staging_branch="${branch}-staging"

workspace="$(mktemp -d)" || fatal "Failed to create a temporary workspace directory"
readonly workspace
staging_branch_touched=0
trap cleanup EXIT

readonly changes_file="${workspace}/changes.jsonl"
readonly additions_file="${workspace}/additions.json"
readonly deletions_file="${workspace}/deletions.json"
readonly payload_file="${workspace}/payload.json"
readonly response_file="${workspace}/response.json"
readonly branch_head_file="${workspace}/branch-head.json"

# Performs a GitHub API request, writing the body to a file and printing the HTTP status.
github_api() {
  local method="${1:?github_api requires an HTTP method}"
  local url="${2:?github_api requires a URL}"
  local request_body_file="${3?github_api requires a request body file path, empty for none}"
  local response_body_file="${4:?github_api requires a response body file path}"

  local -a curl_args=(
    --silent
    --show-error
    --request "${method}"
    --header "Authorization: Bearer ${token}"
    --header "Accept: application/vnd.github+json"
    --header "X-GitHub-Api-Version: 2022-11-28"
    --output "${response_body_file}"
    --write-out '%{http_code}'
  )

  if [[ -n "${request_body_file}" ]]; then
    if [[ ! -f "${request_body_file}" ]]; then
      fatal "github_api request body file does not exist: '${request_body_file}'"
    fi
    curl_args+=(
      --header "Content-Type: application/json"
      --data-binary "@${request_body_file}"
    )
  fi

  : > "${response_body_file}"
  curl "${curl_args[@]}" "${url}" || error "Request failed: ${method} ${url}"
  return 0
}

api_failure_details() {
  local status="${1:?api_failure_details requires an HTTP status}"
  local response_body_file="${2:?api_failure_details requires a response body file path}"

  printf -- 'HTTP %s\n%s' "${status}" "$(cat "${response_body_file}")"
  return 0
}

git_in_work_dir() {
  git -C "${work_dir}" "$@"
  return "$?"
}

# Collects the changed paths, splitting them into GraphQL 'additions' and 'deletions'.
# Returns 1 when the working tree holds no changes within PATHSPEC.
collect_file_changes() {
  local -a status_args=(status --porcelain=v1 -z --untracked-files=all)
  if [[ -n "${pathspec}" ]]; then
    status_args+=(-- "${pathspec}")
  fi

  local -a changed_paths=()
  local entry index_status worktree_status changed_path original_path
  while IFS= read -r -d '' entry; do
    index_status="${entry:0:1}"
    worktree_status="${entry:1:1}"
    changed_path="${entry:3}"

    if [[ "${index_status}" == "U" || "${worktree_status}" == "U" ]]; then
      fatal "Unmerged path in '${work_dir}': '${changed_path}'"
    fi

    changed_paths+=("${changed_path}")

    if [[ "${index_status}" == "R" || "${index_status}" == "C" ]]; then
      if ! IFS= read -r -d '' original_path; then
        fatal "Missing original path for rename/copy entry: '${entry}'"
      fi
      changed_paths+=("${original_path}")
    fi
  done < <(git_in_work_dir "${status_args[@]}")

  if [[ "${#changed_paths[@]}" -eq 0 ]]; then
    return 1
  fi

  local file_path contents
  for changed_path in "${changed_paths[@]}"; do
    file_path="${work_dir}/${changed_path}"
    if [[ -e "${file_path}" || -L "${file_path}" ]]; then
      if ! contents="$(base64 < "${file_path}" | tr -d '\n')"; then
        fatal "Failed to base64-encode '${file_path}'"
      fi
      jq --null-input --arg path "${changed_path}" --arg contents "${contents}" \
        '{path: $path, contents: $contents}'
    else
      jq --null-input --arg path "${changed_path}" '{path: $path}'
    fi
  done > "${changes_file}"

  jq --slurp 'map(select(has("contents"))) | unique_by(.path)' \
    "${changes_file}" > "${additions_file}"
  jq --slurp 'map(select(has("contents") | not)) | unique_by(.path)' \
    "${changes_file}" > "${deletions_file}"

  local addition_count deletion_count
  addition_count="$(jq length "${additions_file}")"
  deletion_count="$(jq length "${deletions_file}")"
  log "Collected ${addition_count} addition(s) and ${deletion_count} deletion(s)."
  return 0
}

# Prints the tree SHA the commit would produce, so an unchanged branch is left alone.
desired_tree_sha() {
  local -a add_args=(add --all --)
  if [[ -n "${pathspec}" ]]; then
    add_args+=("${pathspec}")
  fi

  if ! git_in_work_dir "${add_args[@]}"; then
    fatal "Failed to stage the changes in '${work_dir}'"
  fi
  if ! git_in_work_dir write-tree; then
    fatal "Failed to write the staged tree in '${work_dir}'"
  fi
  return 0
}

# Fetches the remote branch head into 'branch_head_file'; returns 1 when the branch is absent.
fetch_remote_branch_head() {
  local url="${api_url}/repos/${repository}/branches/${branch}"
  local status
  status="$(github_api GET "${url}" "" "${branch_head_file}")"

  if [[ "${status}" == "404" ]]; then
    return 1
  fi
  if [[ "${status}" != "200" ]]; then
    fatal "Failed to read branch '${branch}' of '${repository}':" \
      "$(api_failure_details "${status}" "${branch_head_file}")"
  fi
  return 0
}

point_branch_at_commit() {
  local target_branch="${1:?point_branch_at_commit requires a branch name}"
  local target_sha="${2:?point_branch_at_commit requires a 40-char commit SHA}"
  local create_url="${api_url}/repos/${repository}/git/refs"
  local update_url="${api_url}/repos/${repository}/git/refs/heads/${target_branch}"
  local status

  jq --null-input --arg ref "refs/heads/${target_branch}" --arg sha "${target_sha}" \
    '{ref: $ref, sha: $sha}' > "${payload_file}"
  status="$(github_api POST "${create_url}" "${payload_file}" "${response_file}")"

  if [[ "${status}" == "201" ]]; then
    log "Created branch '${target_branch}' at ${target_sha:0:7}."
    return 0
  fi
  if [[ "${status}" != "422" ]]; then
    fatal "Failed to create branch '${target_branch}' of '${repository}':" \
      "$(api_failure_details "${status}" "${response_file}")"
  fi

  jq --null-input --arg sha "${target_sha}" '{sha: $sha, force: true}' > "${payload_file}"
  status="$(github_api PATCH "${update_url}" "${payload_file}" "${response_file}")"
  if [[ "${status}" != "200" ]]; then
    fatal "Failed to force-update '${target_branch}' of '${repository}' to ${target_sha}:" \
      "$(api_failure_details "${status}" "${response_file}")"
  fi

  log "Force-updated branch '${target_branch}' to ${target_sha:0:7}."
  return 0
}

# Deletes the branch without failing the run, so cleanup never masks the real error.
delete_branch() {
  local target_branch="${1:?delete_branch requires a branch name}"
  local url="${api_url}/repos/${repository}/git/refs/heads/${target_branch}"
  local status
  status="$(github_api DELETE "${url}" "" "${response_file}")"

  if [[ "${status}" != "204" && "${status}" != "404" && "${status}" != "422" ]]; then
    error "Failed to delete branch '${target_branch}' of '${repository}':" \
      "$(api_failure_details "${status}" "${response_file}")"
  fi
  return 0
}

cleanup() {
  if [[ "${staging_branch_touched}" == "1" ]]; then
    delete_branch "${staging_branch}"
  fi

  rm -rf "${workspace}"
  return 0
}

# Creates the commit through the GraphQL API so GitHub signs it, and prints its OID.
create_signed_commit() {
  local target_branch="${1:?create_signed_commit requires a branch name}"
  local headline body status commit_oid
  headline="${commit_message%%$'\n'*}"
  body="${commit_message#"${headline}"}"
  body="${body#$'\n'}"
  body="${body#$'\n'}"

  jq --null-input \
    --arg repository "${repository}" \
    --arg branch "${target_branch}" \
    --arg headline "${headline}" \
    --arg body "${body}" \
    --arg expected_head_oid "${base_sha}" \
    --slurpfile additions "${additions_file}" \
    --slurpfile deletions "${deletions_file}" \
    '{
      query: "mutation CommitOnBranch($input: CreateCommitOnBranchInput!) { createCommitOnBranch(input: $input) { commit { oid url } } }",
      variables: {
        input: {
          branch: {repositoryNameWithOwner: $repository, branchName: $branch},
          message: {headline: $headline, body: $body},
          expectedHeadOid: $expected_head_oid,
          fileChanges: {additions: $additions[0], deletions: $deletions[0]}
        }
      }
    }' > "${payload_file}"

  status="$(github_api POST "${graphql_url}" "${payload_file}" "${response_file}")"
  if [[ "${status}" != "200" ]]; then
    fatal "GraphQL createCommitOnBranch request failed:" \
      "$(api_failure_details "${status}" "${response_file}")"
  fi
  if jq --exit-status 'has("errors")' "${response_file}" > /dev/null; then
    fatal "GraphQL createCommitOnBranch returned errors:" \
      "$(jq --compact-output '.errors' "${response_file}")"
  fi

  commit_oid="$(jq --raw-output '.data.createCommitOnBranch.commit.oid' "${response_file}")"
  if [[ ! "${commit_oid}" =~ ^[0-9a-f]{40}$ ]]; then
    fatal "GraphQL createCommitOnBranch returned an unexpected OID: '${commit_oid}'"
  fi

  printf -- '%s' "${commit_oid}"
  return 0
}

if ! git_in_work_dir rev-parse --git-dir > /dev/null 2>&1; then
  fatal "WORK_DIR is not a git repository: '${work_dir}'"
fi

if ! collect_file_changes; then
  log "No changes in '${work_dir}' under pathspec '${pathspec:-.}'; nothing to commit."
  printf -- 'has-changes=false\n' >> "${output_file}"
  exit 0
fi

wanted_tree="$(desired_tree_sha)"
readonly wanted_tree

if fetch_remote_branch_head; then
  branch_head_sha="$(jq --raw-output '.commit.sha' "${branch_head_file}")"
  branch_tree_sha="$(jq --raw-output '.commit.commit.tree.sha' "${branch_head_file}")"

  if [[ "${wanted_tree}" == "${branch_tree_sha}" ]]; then
    log "Branch '${branch}' already holds tree ${wanted_tree:0:7}; no new commit needed."
    {
      printf -- 'has-changes=true\n'
      printf -- 'commit-sha=%s\n' "${branch_head_sha}"
    } >> "${output_file}"
    exit 0
  fi
fi

staging_branch_touched=1
point_branch_at_commit "${staging_branch}" "${base_sha}"

commit_sha="$(create_signed_commit "${staging_branch}")"
readonly commit_sha

point_branch_at_commit "${branch}" "${commit_sha}"

{
  printf -- 'has-changes=true\n'
  printf -- 'commit-sha=%s\n' "${commit_sha}"
} >> "${output_file}"

log "✅ Created signed commit ${commit_sha:0:7} on '${repository}@${branch}'."
