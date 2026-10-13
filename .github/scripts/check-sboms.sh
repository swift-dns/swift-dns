#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly sbom_dir="${SBOM_DIR:?SBOM_DIR must be the directory that holds the committed SBOMs, which 'swift build --sbom-output-dir' generated the new ones in, e.g. 'docs/sboms'}"
readonly sbom_name="${SBOM_NAME:?SBOM_NAME must be the file name the committed SBOMs share before their extensions, e.g. 'swift-dns'}"
readonly summary_file="${SUMMARY_FILE:-${GITHUB_STEP_SUMMARY:-}}"
readonly max_summary_bytes="${MAX_SUMMARY_BYTES:-524288}"

readonly committed_cyclonedx_sbom="${sbom_dir}/${sbom_name}.cdx.json"
readonly committed_spdx_sbom="${sbom_dir}/${sbom_name}.spdx3.json"
readonly unknown_root_version="unknown"

if [[ ! -d "${sbom_dir}" ]]; then
  fatal "SBOM_DIR directory does not exist: '${sbom_dir}'"
fi
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  fatal "Not a git repository, so the SBOM changes cannot be diffed: '${PWD}'"
fi

workspace="$(mktemp -d)" || fatal "Failed to create a temporary workspace directory"
readonly workspace
trap 'rm -rf "${workspace}"' EXIT

readonly patch_file_name="sbom.patch"
readonly patch_file="${workspace}/${patch_file_name}"

find_generated_sbom() {
  local spec="${1:?find_generated_sbom requires an SBOM spec, e.g. 'cyclonedx1'}"

  local -a generated_sboms
  mapfile -d '' -t generated_sboms < <(
    find "${sbom_dir}" -mindepth 1 -maxdepth 1 -type f -name "${spec}-*.json" -print0
  )

  if [[ "${#generated_sboms[@]}" -ne 1 ]]; then
    fatal "Expected 1 '${spec}' SBOM generated in '${sbom_dir}', found ${#generated_sboms[@]}:" \
      "${generated_sboms[@]}"
  fi

  printf -- '%s' "${generated_sboms[0]}"
  return 0
}

# A committed SBOM cannot name the commit it lands in, so the root package must have no version.
assert_unknown_root_version() {
  local cyclonedx_sbom_file="${1:?assert_unknown_root_version requires a CycloneDX SBOM file path}"

  local root_version
  if ! root_version="$(jq --raw-output '.metadata.component.version' "${cyclonedx_sbom_file}")"; then
    fatal "Failed to read the root package version out of '${cyclonedx_sbom_file}'"
  fi

  if [[ "${root_version}" != "${unknown_root_version}" ]]; then
    fatal "SwiftPM recorded the root package at version '${root_version}', not '${unknown_root_version}'." \
      "'swift build' must generate the SBOMs before 'safe.directory' lets git read the checkout."
  fi

  return 0
}

# Every SwiftPM run mints new 'urn:uuid:' identifiers and records its time, so those never match.
normalize_sbom() {
  local sbom_file="${1:?normalize_sbom requires an SBOM file path}"

  jq --sort-keys '
    walk(
      if type == "string" then
        gsub("urn:uuid:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"; "urn:uuid:<random>")
        | sub("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"; "<generation time>")
      else . end
    )
  ' "${sbom_file}"
  return "$?"
}

is_sbom_up_to_date() {
  local committed_sbom="${1:?is_sbom_up_to_date requires the committed SBOM path}"
  local generated_sbom="${2:?is_sbom_up_to_date requires the generated SBOM path}"

  if [[ ! -f "${committed_sbom}" ]]; then
    log "'${committed_sbom}' does not exist."
    return 1
  fi

  local normalized_generated_sbom
  if ! normalized_generated_sbom="$(normalize_sbom "${generated_sbom}")"; then
    fatal "Failed to normalize the generated SBOM '${generated_sbom}'"
  fi

  local normalized_committed_sbom
  if ! normalized_committed_sbom="$(normalize_sbom "${committed_sbom}")"; then
    log "'${committed_sbom}' is not a valid JSON document."
    return 1
  fi

  if [[ "${normalized_committed_sbom}" != "${normalized_generated_sbom}" ]]; then
    log "'${committed_sbom}' differs from the generated '${generated_sbom}'."
    return 1
  fi

  log "'${committed_sbom}' matches the generated '${generated_sbom}'."
  return 0
}

# Writes the SBOM diff against HEAD to 'destination'. An SBOM committed for the first time is still
# untracked, so it is marked intent-to-add to make 'git diff' include it.
write_sbom_patch() {
  local destination="${1:?write_sbom_patch requires a destination patch file path}"

  if ! git add --intent-to-add -- "${committed_cyclonedx_sbom}" "${committed_spdx_sbom}"; then
    fatal "Failed to mark the untracked SBOMs under '${sbom_dir}' for diffing"
  fi

  local -a diff_args=(diff --no-color -- "${committed_cyclonedx_sbom}" "${committed_spdx_sbom}")
  local diff_status=0
  git "${diff_args[@]}" > "${destination}" || diff_status="$?"

  if ! git reset --quiet -- "${committed_cyclonedx_sbom}" "${committed_spdx_sbom}"; then
    log "Failed to unmark the intent-to-add SBOMs; the index still holds them."
  fi

  if [[ "${diff_status}" -ne 0 ]]; then
    fatal "Failed to diff the SBOMs under '${sbom_dir}'; git exited ${diff_status}."
  fi

  return 0
}

count_patched_files() {
  local patch_source="${1:?count_patched_files requires a patch file path}"

  grep -c -- '^diff --git ' "${patch_source}" || true
  return 0
}

# Job log copies carry per-line timestamps, so the summary copy below is the one to apply.
print_patch_to_job_log() {
  local patch_source="${1:?print_patch_to_job_log requires a patch file path}"

  printf -- '===== BEGIN SBOM PATCH =====\n'
  cat -- "${patch_source}"
  printf -- '===== END SBOM PATCH =====\n'
  return 0
}

append_patch_to_summary() {
  local patch_source="${1:?append_patch_to_summary requires a patch file path}"
  local patched_files="${2:?append_patch_to_summary requires a patched file count}"

  if [[ -z "${summary_file}" ]]; then
    log "Neither SUMMARY_FILE nor GITHUB_STEP_SUMMARY is set; skipping the summary section."
    return 0
  fi

  local patch_bytes
  patch_bytes="$(wc -c < "${patch_source}" | tr -d '[:space:]')"

  local update_notice
  update_notice="${patched_files} SBOM file(s) changed."
  update_notice+=" Update them by saving the diff below as '${patch_file_name}'"
  update_notice+=" at the root of the repository, then:"

  {
    printf -- '\n%s\n' "## Outdated SBOMs"
    printf -- '\n%s\n' "${update_notice}"
    printf -- '\n%s\n' '```sh'
    printf -- '%s\n' "git apply ${patch_file_name}"
    printf -- '%s\n' '```'
    printf -- '\n%s\n' '<details>'
    printf -- '%s\n' '  <summary> Click to expand the SBOM changes </summary>'
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

generated_cyclonedx_sbom="$(find_generated_sbom cyclonedx1)"
readonly generated_cyclonedx_sbom
generated_spdx_sbom="$(find_generated_sbom spdx3)"
readonly generated_spdx_sbom

assert_unknown_root_version "${generated_cyclonedx_sbom}"

outdated_sboms=()
if ! is_sbom_up_to_date "${committed_cyclonedx_sbom}" "${generated_cyclonedx_sbom}"; then
  outdated_sboms+=("${committed_cyclonedx_sbom}")
fi
if ! is_sbom_up_to_date "${committed_spdx_sbom}" "${generated_spdx_sbom}"; then
  outdated_sboms+=("${committed_spdx_sbom}")
fi
readonly outdated_sboms

if [[ "${#outdated_sboms[@]}" -eq 0 ]]; then
  if ! rm -f -- "${generated_cyclonedx_sbom}" "${generated_spdx_sbom}"; then
    fatal "Failed to remove the generated SBOMs, which match the committed ones"
  fi
  log "✅ The SBOMs under '${sbom_dir}' are up to date."
  exit 0
fi

# Both SBOMs come out of one SwiftPM run, so both are replaced to keep the identifiers they share.
if ! mv -f -- "${generated_cyclonedx_sbom}" "${committed_cyclonedx_sbom}"; then
  fatal "Failed to replace '${committed_cyclonedx_sbom}' with '${generated_cyclonedx_sbom}'"
fi
if ! mv -f -- "${generated_spdx_sbom}" "${committed_spdx_sbom}"; then
  fatal "Failed to replace '${committed_spdx_sbom}' with '${generated_spdx_sbom}'"
fi

write_sbom_patch "${patch_file}"

patched_file_count="$(count_patched_files "${patch_file}")"
readonly patched_file_count

if [[ "${patched_file_count}" -eq 0 ]]; then
  fatal "The SBOM patch holds no changes, although these SBOMs are out of date:" "${outdated_sboms[@]}"
fi

append_patch_to_summary "${patch_file}" "${patched_file_count}"
print_patch_to_job_log "${patch_file}"

fatal "These SBOMs are out of date; apply the patch in the job summary to update them:" \
  "${outdated_sboms[@]}"
