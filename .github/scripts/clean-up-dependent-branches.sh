#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly token="${GH_TOKEN:?GH_TOKEN must be a token allowed to write contents to REPOSITORY}"
readonly repository="${REPOSITORY:?REPOSITORY must be the owner/name of the repository to prune, e.g. 'swift-dns/swift-dns'}"
readonly deleted_branch="${DELETED_BRANCH:?DELETED_BRANCH must be the name of the branch that was just deleted, e.g. 'mmbm-do-this'}"
readonly default_branch="${DEFAULT_BRANCH:?DEFAULT_BRANCH must be the default branch of the repository, which is never deleted}"
readonly summary_file="${SUMMARY_FILE:?SUMMARY_FILE must be the file path to write the markdown job summary to}"
readonly api_url="${GITHUB_API_URL:-https://api.github.com}"
readonly page_size=100

# A run id is what 'benchmarks.yml' and 'lint.yml' embed in the branches they generate. Requiring it
# to be this long keeps a branch such as 'thr-update/mmbm-rfc-10029' attached to 'mmbm-rfc-10029'
# instead of also counting as a generated branch of 'mmbm-rfc'.
readonly minimum_run_id_length=9

if [[ ! "${repository}" =~ ^[^/]+/[^/]+$ ]]; then
  fatal "REPOSITORY is not in 'owner/name' form: '${repository}'"
fi
if [[ "${deleted_branch}" == "${default_branch}" ]]; then
  fatal "DELETED_BRANCH is the default branch '${default_branch}'; refusing to prune anything"
fi

workspace="$(mktemp -d)" || fatal "Failed to create a temporary workspace directory"
readonly workspace
trap 'rm -rf "${workspace}"' EXIT

readonly response_file="${workspace}/response.json"
readonly branch_names_file="${workspace}/branch-names"

# Performs a GitHub API request, writing the body to a file and printing the HTTP status.
github_api() {
  local method="${1:?github_api requires an HTTP method}"
  local url="${2:?github_api requires a URL}"
  local response_body_file="${3:?github_api requires a response body file path}"

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

is_run_id() {
  local value="${1?is_run_id requires a value}"

  if [[ "${#value}" -ge "${minimum_run_id_length}" && "${value}" != *[!0-9]* ]]; then
    return 0
  fi
  return 1
}

# Recognises the branches that 'update-benchmark-thresholds.yml', 'benchmarks.yml' and 'lint.yml'
# derive from a branch, one generated layer at a time so that a branch generated off an already
# deleted generated branch, such as 'auto-thr-update/thr-update/mmbm-cidr-benchs', is matched too.
is_derived_from() {
  local candidate="${1:?is_derived_from requires a candidate branch name}"
  local parent="${2:?is_derived_from requires the parent branch name}"

  if [[ "${candidate}" == "${parent}" ]]; then
    return 0
  fi

  local remainder
  case "${candidate}" in
    auto-thr-update/*)
      if is_derived_from "${candidate#auto-thr-update/}" "${parent}"; then
        return 0
      fi
      ;;
    thr-update/*)
      remainder="${candidate#thr-update/}"
      if is_derived_from "${remainder}" "${parent}"; then
        return 0
      fi
      if [[ "${remainder}" == *-* ]] && is_run_id "${remainder##*-}"; then
        if is_derived_from "${remainder%-*}" "${parent}"; then
          return 0
        fi
      fi
      ;;
    format-update/*/*)
      remainder="${candidate#format-update/}"
      if is_run_id "${remainder%%/*}"; then
        if is_derived_from "${remainder#*/}" "${parent}"; then
          return 0
        fi
      fi
      ;;
  esac

  return 1
}

list_branch_names() {
  local page=1
  local url status
  local -a page_names

  while :; do
    url="${api_url}/repos/${repository}/branches?per_page=${page_size}&page=${page}"
    status="$(github_api GET "${url}" "${response_file}")"
    if [[ "${status}" != "200" ]]; then
      fatal "Failed to list the branches of '${repository}':" \
        "$(api_failure_details "${status}" "${response_file}")"
    fi

    mapfile -t -d '' page_names < <(jq --join-output '.[] | .name, "\u0000"' "${response_file}")
    if [[ "${#page_names[@]}" -eq 0 ]]; then
      break
    fi

    printf -- '%s\0' "${page_names[@]}"

    if [[ "${#page_names[@]}" -lt "${page_size}" ]]; then
      break
    fi
    page=$((page + 1))
  done

  return 0
}

delete_branch() {
  local target_branch="${1:?delete_branch requires a branch name}"
  local encoded_branch url status

  if ! encoded_branch="$(url_encode "${target_branch}")"; then
    error "Failed to url-encode the branch '${target_branch}'"
    return 1
  fi

  url="${api_url}/repos/${repository}/git/refs/heads/${encoded_branch}"
  status="$(github_api DELETE "${url}" "${response_file}")"

  case "${status}" in
    204)
      log "Deleted branch '${target_branch}'."
      return 0
      ;;
    404 | 422)
      log "Branch '${target_branch}' is already gone."
      return 0
      ;;
    *)
      error "Failed to delete branch '${target_branch}' of '${repository}':" \
        "$(api_failure_details "${status}" "${response_file}")"
      return 1
      ;;
  esac
}

write_summary() {
  local deleted_count="${1:?write_summary requires the number of deleted branches}"
  local failed_count="${2:?write_summary requires the number of branches that could not be deleted}"
  shift 2
  local -a deleted=("$@")

  {
    printf -- '%s\n\n' "## Dependent Branches Clean-up Report"

    if [[ "${deleted_count}" -gt 0 ]]; then
      printf -- '%s\n\n' "Deleted ${deleted_count} branch(es) derived from \`${deleted_branch}\`:"
      printf -- "- \`%s\`\n" "${deleted[@]}"
      printf -- '\n'
    elif [[ "${failed_count}" -eq 0 ]]; then
      printf -- '%s\n\n' "No branch derived from \`${deleted_branch}\` was left in \`${repository}\`."
    fi

    if [[ "${failed_count}" -gt 0 ]]; then
      printf -- '%s\n' "${failed_count} branch(es) derived from \`${deleted_branch}\` could not be deleted; see the job log."
    fi
  } >> "${summary_file}"

  return 0
}

list_branch_names > "${branch_names_file}"
mapfile -t -d '' branch_names < "${branch_names_file}"
readonly branch_names
log "Looking through the ${#branch_names[@]} branches of '${repository}' for branches derived from '${deleted_branch}'."

derived_branches=()
for branch_name in "${branch_names[@]}"; do
  if [[ "${branch_name}" == "${default_branch}" || "${branch_name}" == "${deleted_branch}" ]]; then
    continue
  fi
  if is_derived_from "${branch_name}" "${deleted_branch}"; then
    derived_branches+=("${branch_name}")
  fi
done
readonly derived_branches

: > "${summary_file}"

if [[ "${#derived_branches[@]}" -eq 0 ]]; then
  log "No branch derived from '${deleted_branch}' is left in '${repository}'."
  write_summary 0 0
  exit 0
fi

deleted_branches=()
failed_deletion_count=0
for branch_name in "${derived_branches[@]}"; do
  if delete_branch "${branch_name}"; then
    deleted_branches+=("${branch_name}")
  else
    failed_deletion_count=$((failed_deletion_count + 1))
  fi
done
readonly deleted_branches failed_deletion_count

write_summary "${#deleted_branches[@]}" "${failed_deletion_count}" "${deleted_branches[@]}"

if [[ "${failed_deletion_count}" -gt 0 ]]; then
  fatal "Failed to delete ${failed_deletion_count} of the ${#derived_branches[@]} branches derived from '${deleted_branch}'"
fi

log "✅ Deleted ${#deleted_branches[@]} branch(es) derived from '${deleted_branch}' in '${repository}'."
