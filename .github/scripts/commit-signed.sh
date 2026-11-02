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
readonly commit_message="${COMMIT_MESSAGE:?COMMIT_MESSAGE must be the commit message}"
readonly work_dir="${WORK_DIR:?WORK_DIR must point at the checked-out repository holding the changes to commit}"
readonly output_file="${OUTPUT_FILE:?OUTPUT_FILE must be the file path to write 'has-changes' and 'commit-sha' to}"
readonly pathspec="${PATHSPEC-}"
readonly api_url="${GITHUB_API_URL:-https://api.github.com}"

if [[ ! "${repository}" =~ ^[^/]+/[^/]+$ ]]; then
  fatal "REPOSITORY is not in 'owner/name' form: '${repository}'"
fi
if [[ ! "${base_sha}" =~ ^[0-9a-f]{40}$ ]]; then
  fatal "BASE_SHA is not a 40-char commit SHA: '${base_sha}'"
fi
if [[ -z "${commit_message//[[:space:]]/}" ]]; then
  fatal "COMMIT_MESSAGE is blank; the commit message cannot be empty"
fi
[[ -d "${work_dir}" ]] || fatal "WORK_DIR directory does not exist: '${work_dir}'"

workspace="$(mktemp -d)" || fatal "Failed to create a temporary workspace directory"
readonly workspace
trap 'rm -rf "${workspace}"' EXIT

readonly tree_entries_file="${workspace}/tree-entries.jsonl"
readonly new_blobs_file="${workspace}/new-blobs.txt"
readonly blob_content_file="${workspace}/blob-content.b64"
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

# Percent-encodes every byte outside 'A-Za-z0-9-._~'; GitHub reads an encoded '/' as a literal one.
url_encode() {
  local value="${1?url_encode requires a value to encode}"

  jq --null-input --raw-output --arg value "${value}" '$value | @uri'
  return "$?"
}

git_in_work_dir() {
  git -C "${work_dir}" "$@"
  return "$?"
}

reject_unmerged_paths() {
  local -a unmerged_args=(ls-files --unmerged -z)
  if [[ -n "${pathspec}" ]]; then
    unmerged_args+=(-- "${pathspec}")
  fi

  local unmerged_entry unmerged_path
  while IFS= read -r -d '' unmerged_entry; do
    unmerged_path="${unmerged_entry#*$'\t'}"
    fatal "Unmerged path in '${work_dir}': '${unmerged_path}'"
  done < <(git_in_work_dir "${unmerged_args[@]}")
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

# Collects the staged changes as tree entries, listing the blobs that need uploading.
# Returns 1 when the staged tree holds no changes within PATHSPEC.
collect_file_changes() {
  local -a diff_args=(diff-tree -r -z --no-renames "${base_sha}" "${wanted_tree}")
  if [[ -n "${pathspec}" ]]; then
    diff_args+=(-- "${pathspec}")
  fi

  local change_count=0
  local change_meta changed_path old_mode new_mode old_sha new_sha change_status
  local entry_mode entry_type entry_sha
  : > "${new_blobs_file}"
  while IFS= read -r -d '' change_meta && IFS= read -r -d '' changed_path; do
    IFS=' ' read -r old_mode new_mode old_sha new_sha change_status <<< "${change_meta#:}"
    change_count=$((change_count + 1))

    entry_mode="${new_mode}"
    entry_sha="${new_sha}"
    if [[ "${change_status}" == "D" ]]; then
      entry_mode="${old_mode}"
      entry_sha=""
    fi

    entry_type="blob"
    if [[ "${entry_mode}" == "160000" ]]; then
      entry_type="commit"
    elif [[ -n "${entry_sha}" && "${entry_sha}" != "${old_sha}" ]]; then
      printf -- '%s\n' "${entry_sha}" >> "${new_blobs_file}"
    fi

    jq --null-input --compact-output \
      --arg path "${changed_path}" \
      --arg mode "${entry_mode}" \
      --arg type "${entry_type}" \
      --arg sha "${entry_sha}" \
      '{path: $path, mode: $mode, type: $type, sha: (if $sha == "" then null else $sha end)}'
  done < <(git_in_work_dir "${diff_args[@]}") > "${tree_entries_file}"

  if [[ "${change_count}" -eq 0 ]]; then
    return 1
  fi

  local new_blob_count
  new_blob_count="$(sort -u "${new_blobs_file}" | wc -l | tr -d ' ')"
  log "Collected ${change_count} change(s), with ${new_blob_count} new blob(s) to upload."
  return 0
}

# Fetches the remote branch head into 'branch_head_file'; returns 1 when the branch is absent.
fetch_remote_branch_head() {
  local encoded_branch url status

  if ! encoded_branch="$(url_encode "${branch}")"; then
    fatal "Failed to url-encode BRANCH '${branch}'"
  fi

  url="${api_url}/repos/${repository}/branches/${encoded_branch}"
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
  local encoded_branch create_url update_url status

  if ! encoded_branch="$(url_encode "${target_branch}")"; then
    fatal "Failed to url-encode the branch '${target_branch}'"
  fi

  create_url="${api_url}/repos/${repository}/git/refs"
  update_url="${api_url}/repos/${repository}/git/refs/heads/${encoded_branch}"

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

upload_new_blobs() {
  local url blob_sha status stored_sha
  url="${api_url}/repos/${repository}/git/blobs"

  while IFS= read -r blob_sha; do
    if ! git_in_work_dir cat-file blob "${blob_sha}" | base64 | tr -d '\n' > "${blob_content_file}"; then
      fatal "Failed to base64-encode blob ${blob_sha} of '${work_dir}'"
    fi
    jq --null-input --rawfile content "${blob_content_file}" \
      '{content: $content, encoding: "base64"}' > "${payload_file}"

    status="$(github_api POST "${url}" "${payload_file}" "${response_file}")"
    if [[ "${status}" != "201" ]]; then
      fatal "Failed to upload blob ${blob_sha} to '${repository}':" \
        "$(api_failure_details "${status}" "${response_file}")"
    fi

    stored_sha="$(jq --raw-output '.sha' "${response_file}")"
    if [[ "${stored_sha}" != "${blob_sha}" ]]; then
      fatal "GitHub stored blob ${blob_sha} as '${stored_sha}'"
    fi
  done < <(sort -u "${new_blobs_file}")

  return 0
}

create_tree() {
  local url status created_tree
  url="${api_url}/repos/${repository}/git/trees"

  jq --null-input --arg base_tree "${base_tree}" --slurpfile entries "${tree_entries_file}" \
    '{base_tree: $base_tree, tree: $entries}' > "${payload_file}"

  status="$(github_api POST "${url}" "${payload_file}" "${response_file}")"
  if [[ "${status}" != "201" ]]; then
    fatal "Failed to create the tree in '${repository}':" \
      "$(api_failure_details "${status}" "${response_file}")"
  fi

  created_tree="$(jq --raw-output '.sha' "${response_file}")"
  if [[ "${created_tree}" != "${wanted_tree}" ]]; then
    fatal "GitHub built tree '${created_tree}' instead of the staged tree ${wanted_tree}"
  fi
  return 0
}

# Creates the commit through the REST API so GitHub signs it, and prints its SHA.
create_signed_commit() {
  local url status commit_sha
  url="${api_url}/repos/${repository}/git/commits"

  jq --null-input \
    --arg message "${commit_message}" \
    --arg tree "${wanted_tree}" \
    --arg parent "${base_sha}" \
    '{message: $message, tree: $tree, parents: [$parent]}' > "${payload_file}"

  status="$(github_api POST "${url}" "${payload_file}" "${response_file}")"
  if [[ "${status}" != "201" ]]; then
    fatal "Failed to create the commit in '${repository}':" \
      "$(api_failure_details "${status}" "${response_file}")"
  fi

  commit_sha="$(jq --raw-output '.sha' "${response_file}")"
  if [[ ! "${commit_sha}" =~ ^[0-9a-f]{40}$ ]]; then
    fatal "GitHub returned an unexpected commit SHA: '${commit_sha}'"
  fi
  if ! jq --exit-status '.verification.verified == true' "${response_file}" > /dev/null; then
    fatal "GitHub did not sign commit ${commit_sha}, so no branch will point at it:" \
      "$(jq --compact-output '.verification' "${response_file}")"
  fi

  printf -- '%s' "${commit_sha}"
  return 0
}

if ! git_in_work_dir rev-parse --git-dir > /dev/null 2>&1; then
  fatal "WORK_DIR is not a git repository: '${work_dir}'"
fi

if ! base_tree="$(git_in_work_dir rev-parse --verify --quiet "${base_sha}^{commit}^{tree}")"; then
  fatal "BASE_SHA is not a commit in '${work_dir}': '${base_sha}'"
fi
readonly base_tree

reject_unmerged_paths

wanted_tree="$(desired_tree_sha)"
readonly wanted_tree

if ! collect_file_changes; then
  log "No changes in '${work_dir}' under pathspec '${pathspec:-.}'; nothing to commit."
  printf -- 'has-changes=false\n' >> "${output_file}"
  exit 0
fi

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

upload_new_blobs
create_tree

commit_sha="$(create_signed_commit)"
readonly commit_sha

point_branch_at_commit "${branch}" "${commit_sha}"

{
  printf -- 'has-changes=true\n'
  printf -- 'commit-sha=%s\n' "${commit_sha}"
} >> "${output_file}"

log "✅ Created signed commit ${commit_sha:0:7} on '${repository}@${branch}'."
