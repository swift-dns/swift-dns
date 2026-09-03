#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly job_keys="${JOB_KEYS:-}"
readonly ci_config_path="${CI_CONFIG_PATH:-.github/ci-config.json}"

# Every key a repository may turn off in its own '.github/ci-config.json'. That file is mandatory,
# but a key that is absent from it leaves the jobs it gates enabled.
readonly known_job_keys="android benchmarks embedded integration-tests musl wasm windows"

validate_ci_config() {
  local config_path="${1:?validate_ci_config requires the path of the ci config file}"

  local complaint
  if ! complaint="$(
    jq -r --arg known "${known_job_keys}" '
      (($known | split(" ")) + ["$schema"]) as $known_keys
      | if type != "object" then "it does not hold a json object" else
          (keys - $known_keys) as $unknown_keys
          | [to_entries[] | select(.key != "$schema" and (.value | type) != "boolean") | .key] as $not_boolean_keys
          | if ($unknown_keys | length) > 0 then
              "it holds unknown keys: \($unknown_keys | join(", "))"
            elif ($not_boolean_keys | length) > 0 then
              "these keys of it are not booleans: \($not_boolean_keys | join(", "))"
            else "" end
        end
    ' "${config_path}"
  )"; then
    fatal "Failed to parse '${config_path}'"
  fi

  if [[ -n "${complaint}" ]]; then
    fatal "'${config_path}' is invalid because ${complaint}" \
      "The known keys are: ${known_job_keys}"
  fi

  return 0
}

disabled_keys_of_job() {
  local keys_of_job="${1:?disabled_keys_of_job requires the space separated config keys of the current job}"
  local config_path="${2:?disabled_keys_of_job requires the path of the ci config file}"

  local disabled_keys
  if ! disabled_keys="$(
    jq -r --arg keys "${keys_of_job}" '
      . as $config
      | [$keys | split(" ")[] | select($config[.] == false)]
      | join(", ")
    ' "${config_path}"
  )"; then
    fatal "Failed to read the keys '${keys_of_job}' of '${config_path}'"
  fi

  printf -- '%s' "${disabled_keys}"
  return 0
}

if [[ ! -f "${ci_config_path}" ]]; then
  fatal "There is no '${ci_config_path}'" \
    "Every repository must have one, even when it turns nothing off, in which case it holds '{}'." \
    "The known keys are: ${known_job_keys}"
fi

validate_ci_config "${ci_config_path}"

if [[ -z "${job_keys}" ]]; then
  printf 'true\n'
  exit 0
fi

disabled_keys="$(disabled_keys_of_job "${job_keys}" "${ci_config_path}")"
readonly disabled_keys

if [[ -n "${disabled_keys}" ]]; then
  log "Turned off in '${ci_config_path}': ${disabled_keys}."
  printf 'false\n'
  exit 0
fi

log "None of '${job_keys}' is turned off in '${ci_config_path}'."
printf 'true\n'
