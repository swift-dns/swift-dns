#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly ci_config_dir="${CI_CONFIG_DIR:-.github}"
readonly is_fork_pull_request="${IS_FORK_PULL_REQUEST:-false}"

case "${is_fork_pull_request}" in
  true | false) ;;
  *) fatal "IS_FORK_PULL_REQUEST must be 'true' or 'false', got '${is_fork_pull_request}'" ;;
esac

# Every key a repository may turn off in its own '.github/ci-config.y[a]ml'. That file is mandatory,
# but a key that is absent from it leaves the jobs it gates enabled.
readonly known_job_keys="android benchmarks embedded freebsd integration-tests musl wasm windows"

# Keys holding a 'swiftc' flag rather than gating a job. An absent or empty one adds no flag; the
# jobs pass a set one on as '-Xswiftc <flag>', under the same name with '-arguments' in place of
# '-flag'.
readonly known_flag_keys="cxx-interoperability-flag"

# Keys holding a whole argument list rather than gating a job, which the jobs pass on as it stands,
# under the same name with '-arguments' in place of '-flags'. The android jobs expand theirs in a
# shell, so it may name an environment variable that they set, such as '${SWIFT_INSTALLATION}'.
readonly known_argument_keys="android-swift-build-flags wasi-swift-build-flags"

readonly known_keys="${known_job_keys} ${known_flag_keys} ${known_argument_keys}"

resolve_ci_config_path() {
  local config_dir="${1:?resolve_ci_config_path requires the directory that holds the ci config file}"

  local yml_path="${config_dir}/ci-config.yml"
  local yaml_path="${config_dir}/ci-config.yaml"

  if [[ -f "${yml_path}" && -f "${yaml_path}" ]]; then
    fatal "Both '${yml_path}' and '${yaml_path}' exist" \
      "Only one of them may exist."
  fi

  local config_path
  for config_path in "${yml_path}" "${yaml_path}"; do
    if [[ -f "${config_path}" ]]; then
      printf -- '%s' "${config_path}"
      return 0
    fi
  done

  fatal "There is no '${config_dir}/ci-config.y[a]ml'" \
    "Every repository must have one, even when it turns nothing off, in which case it is empty." \
    "The known keys are: ${known_keys}"
}

assert_no_complaint() {
  local config_path="${1:?assert_no_complaint requires the path of the ci config file}"
  local expression="${2:?assert_no_complaint requires a yq expression that yields a complaint}"

  local complaint
  if ! complaint="$(
    KNOWN_JOB_KEYS="${known_job_keys}" KNOWN_FLAG_KEYS="${known_flag_keys}" \
      KNOWN_ARGUMENT_KEYS="${known_argument_keys}" \
      yq eval-all "${expression}" "${config_path}"
  )"; then
    fatal "Failed to parse '${config_path}'"
  fi

  if [[ -n "${complaint}" ]]; then
    fatal "'${config_path}' is invalid because ${complaint}" \
      "The known keys are: ${known_keys}"
  fi

  return 0
}

# shellcheck disable=SC2016
validate_ci_config() {
  local config_path="${1:?validate_ci_config requires the path of the ci config file}"

  assert_no_complaint "${config_path}" '
    ([.] | length) as $documents
    | ("it holds " + ($documents | tostring) + " yaml documents instead of 1")
    | select($documents != 1)
  '

  # Anchors go first because yq expands their aliases the moment an expression reaches the values,
  # and a few nested ones expand into gigabytes. An alias without its anchor does not parse.
  assert_no_complaint "${config_path}" '
    ([... | select(anchor != "") | anchor] | unique | join(", ")) as $anchors
    | ("it defines the yaml anchors " + $anchors)
    | select($anchors != "")
  '

  assert_no_complaint "${config_path}" '
    tag as $root_tag
    | ("its root is a " + $root_tag + " instead of a map")
    | select($root_tag != "!!map" and $root_tag != "!!null")
  '

  assert_no_complaint "${config_path}" '
    (strenv(KNOWN_JOB_KEYS) | split(" ")) as $known_jobs
    | ((strenv(KNOWN_FLAG_KEYS) + " " + strenv(KNOWN_ARGUMENT_KEYS)) | split(" ")) as $known_strings
    | (. // {}) as $config
    | ($config | keys) as $config_keys
    | ($config_keys | group_by(.) | map(select(length > 1) | .[0]) | join(", ")) as $duplicate_keys
    | (($config_keys | unique) - ($known_jobs + $known_strings) | join(", ")) as $unknown_keys
    | ([$config | to_entries[]
        | select(((([.key] - $known_jobs) | length) == 0) and (.value | tag) != "!!bool")
        | .key + " (" + (.value | tag) + ")"] | join(", ")) as $not_boolean_keys
    | ([$config | to_entries[]
        | select(((([.key] - $known_strings) | length) == 0) and (.value | tag) != "!!str")
        | .key + " (" + (.value | tag) + ")"] | join(", ")) as $not_string_keys
    | [
        (("it holds duplicate keys: " + $duplicate_keys) | select($duplicate_keys != "")),
        (("it holds unknown keys: " + $unknown_keys) | select($unknown_keys != "")),
        (("these keys of it are not booleans: " + $not_boolean_keys) | select($not_boolean_keys != "")),
        (("these keys of it are not strings: " + $not_string_keys) | select($not_string_keys != ""))
      ]
    | .[0] // ""
  '

  return 0
}

# shellcheck disable=SC2016
enablement_of_known_keys() {
  local config_path="${1:?enablement_of_known_keys requires the path of the ci config file}"

  local enablement
  if ! enablement="$(
    KNOWN_JOB_KEYS="${known_job_keys}" yq eval-all '
      (strenv(KNOWN_JOB_KEYS) | split(" ")) as $known
      | (. // {}) as $config
      | $known[]
      | . + "=" + (($config[.] != false) | tostring)
    ' "${config_path}"
  )"; then
    fatal "Failed to read the keys '${known_job_keys}' of '${config_path}'"
  fi

  printf -- '%s\n' "${enablement}"
  return 0
}

# shellcheck disable=SC2016
arguments_of_known_keys() {
  local config_path="${1:?arguments_of_known_keys requires the path of the ci config file}"

  local arguments
  if ! arguments="$(
    KNOWN_FLAG_KEYS="${known_flag_keys}" KNOWN_ARGUMENT_KEYS="${known_argument_keys}" \
      yq eval-all '
        (strenv(KNOWN_FLAG_KEYS) | split(" ")) as $known_flags
        | (strenv(KNOWN_ARGUMENT_KEYS) | split(" ")) as $known_arguments
        | (. // {}) as $config
        | ($known_flags + $known_arguments)[]
        | . as $key
        | ($key | sub("-flags?$", "-arguments")) as $output
        | (($config[$key] // "") | select(. != "")) as $value
        | ((([$key] - $known_flags) | length) == 0) as $needs_prefix
        | (($value | select($needs_prefix) | "-Xswiftc " + .) // $value) as $argument
        | $output + "=" + ($argument // "")
      ' "${config_path}"
  )"; then
    fatal "Failed to read the keys '${known_flag_keys} ${known_argument_keys}' of '${config_path}'"
  fi

  printf -- '%s\n' "${arguments}"
  return 0
}

ci_config_path="$(resolve_ci_config_path "${ci_config_dir}")"
readonly ci_config_path

if [[ "${is_fork_pull_request}" == true ]]; then
  log "This pull request comes from a fork, so its own ci config is ignored in favour of '${ci_config_path}' of the base branch"
else
  log "Using '${ci_config_path}' of the checked out commit"
fi

validate_ci_config "${ci_config_path}"

enablement="$(enablement_of_known_keys "${ci_config_path}")"
readonly enablement

log "Job keys of '${ci_config_path}': ${enablement//$'\n'/, }"

arguments="$(arguments_of_known_keys "${ci_config_path}")"
readonly arguments

log "Flag and argument keys of '${ci_config_path}': ${arguments//$'\n'/, }"

printf -- '%s\n' "${enablement}"
printf -- '%s\n' "${arguments}"
