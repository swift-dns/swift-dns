#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly token="${GH_TOKEN:?GH_TOKEN must be a token allowed to write actions to REPOSITORY}"
readonly repository="${REPOSITORY:?REPOSITORY must be the owner/name of the repository to prune, e.g. 'swift-dns/swift-dns'}"
readonly cache_ref="${CACHE_REF:?CACHE_REF must be the git ref the caches to delete are scoped to, e.g. 'refs/pull/17/merge'}"
readonly summary_file="${SUMMARY_FILE:?SUMMARY_FILE must be the file path to write the markdown job summary to}"
readonly api_url="${GITHUB_API_URL:-https://api.github.com}"
readonly page_size=100

if [[ ! "${repository}" =~ ^[^/]+/[^/]+$ ]]; then
  fatal "REPOSITORY is not in 'owner/name' form: '${repository}'"
fi

# A cache scoped to the default branch is the one every other ref restores from, so deleting it
# would slow down every later run instead of reclaiming anything that has gone unreachable.
if [[ "${cache_ref}" != refs/pull/*/merge ]]; then
  fatal "CACHE_REF is '${cache_ref}', which is not a pull request merge ref; refusing to delete anything"
fi

workspace="$(mktemp -d)" || fatal "Failed to create a temporary workspace directory"
readonly workspace
trap 'rm -rf "${workspace}"' EXIT

readonly response_file="${workspace}/response.json"
readonly caches_file="${workspace}/caches"

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

readonly bytes_per_mebibyte=1048576

mebibytes_of() {
  local bytes="${1:?mebibytes_of requires a byte count}"

  printf -- '%s' "$(((bytes + bytes_per_mebibyte / 2) / bytes_per_mebibyte))"
  return 0
}

# Emits one 'id<tab>size<tab>key' line per cache scoped to the ref. Every page is read before
# anything is deleted, because deleting shifts the entries the later pages would have held.
list_caches() {
  local encoded_ref="${1:?list_caches requires a url-encoded ref}"

  local page=1
  local url status
  local -a page_caches

  while :; do
    url="${api_url}/repos/${repository}/actions/caches?ref=${encoded_ref}&per_page=${page_size}&page=${page}"
    status="$(github_api GET "${url}" "${response_file}")"
    if [[ "${status}" != "200" ]]; then
      fatal "Failed to list the caches of '${repository}' scoped to '${cache_ref}':" \
        "$(api_failure_details "${status}" "${response_file}")"
    fi

    mapfile -t page_caches < <(
      jq --raw-output '.actions_caches[] | [.id, .size_in_bytes, .key] | @tsv' "${response_file}"
    )
    if [[ "${#page_caches[@]}" -eq 0 ]]; then
      break
    fi

    printf -- '%s\n' "${page_caches[@]}"

    if [[ "${#page_caches[@]}" -lt "${page_size}" ]]; then
      break
    fi
    page=$((page + 1))
  done

  return 0
}

delete_cache() {
  local cache_id="${1:?delete_cache requires a cache id}"
  local cache_key="${2:?delete_cache requires a cache key}"
  local url status

  url="${api_url}/repos/${repository}/actions/caches/${cache_id}"
  status="$(github_api DELETE "${url}" "${response_file}")"

  case "${status}" in
    204)
      log "Deleted cache '${cache_key}'."
      return 0
      ;;
    404)
      log "Cache '${cache_key}' is already gone."
      return 0
      ;;
    *)
      error "Failed to delete cache '${cache_key}' of '${repository}':" \
        "$(api_failure_details "${status}" "${response_file}")"
      return 1
      ;;
  esac
}

write_summary() {
  local deleted_count="${1:?write_summary requires the number of deleted caches}"
  local reclaimed="${2:?write_summary requires the number of reclaimed bytes}"
  local failed_count="${3:?write_summary requires the number of caches that could not be deleted}"
  shift 3
  local -a deleted=("$@")

  {
    printf -- '%s\n\n' "## Cache Clean-up Report"

    if [[ "${deleted_count}" -gt 0 ]]; then
      printf -- '%s\n\n' "Deleted ${deleted_count} cache(s) scoped to \`${cache_ref}\`, reclaiming $(mebibytes_of "${reclaimed}") MiB:"
      printf -- "- \`%s\`\n" "${deleted[@]}"
      printf -- '\n'
    elif [[ "${failed_count}" -eq 0 ]]; then
      printf -- '%s\n\n' "No cache scoped to \`${cache_ref}\` was left in \`${repository}\`."
    fi

    if [[ "${failed_count}" -gt 0 ]]; then
      printf -- '%s\n' "${failed_count} cache(s) scoped to \`${cache_ref}\` could not be deleted; see the job log."
    fi
  } >> "${summary_file}"

  return 0
}

if ! encoded_cache_ref="$(url_encode "${cache_ref}")"; then
  fatal "Failed to url-encode the ref '${cache_ref}'"
fi
readonly encoded_cache_ref

list_caches "${encoded_cache_ref}" > "${caches_file}"
mapfile -t caches < "${caches_file}"
readonly caches
log "Found ${#caches[@]} cache(s) of '${repository}' scoped to '${cache_ref}'."

: > "${summary_file}"

if [[ "${#caches[@]}" -eq 0 ]]; then
  write_summary 0 0 0
  exit 0
fi

deleted_keys=()
reclaimed_bytes=0
failed_deletion_count=0
for cache in "${caches[@]}"; do
  IFS=$'\t' read -r cache_id cache_size cache_key <<< "${cache}"
  if delete_cache "${cache_id}" "${cache_key}"; then
    deleted_keys+=("${cache_key}")
    reclaimed_bytes=$((reclaimed_bytes + cache_size))
  else
    failed_deletion_count=$((failed_deletion_count + 1))
  fi
done
readonly deleted_keys reclaimed_bytes failed_deletion_count

write_summary "${#deleted_keys[@]}" "${reclaimed_bytes}" "${failed_deletion_count}" "${deleted_keys[@]}"

if [[ "${failed_deletion_count}" -gt 0 ]]; then
  fatal "Failed to delete ${failed_deletion_count} of the ${#caches[@]} caches scoped to '${cache_ref}'"
fi

log "✅ Deleted ${#deleted_keys[@]} cache(s) scoped to '${cache_ref}' in '${repository}', reclaiming $(mebibytes_of "${reclaimed_bytes}") MiB."
