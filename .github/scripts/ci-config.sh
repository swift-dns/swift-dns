#!/usr/bin/env bash

set -Eeuo pipefail
shopt -s failglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly ci_config_path="${CI_CONFIG_PATH:-.github/ci-config.json}"

# Every key a repository may turn off in its own '.github/ci-config.json'. That file is mandatory,
# but a key that is absent from it leaves the jobs it gates enabled.
readonly known_job_keys="android benchmarks embedded freebsd integration-tests musl wasm windows"

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

enablement_of_known_keys() {
  local config_path="${1:?enablement_of_known_keys requires the path of the ci config file}"

  local enablement
  if ! enablement="$(
    jq -r --arg known "${known_job_keys}" '
      . as $config
      | $known
      | split(" ")[]
      | "\(.)=\($config[.] != false)"
    ' "${config_path}"
  )"; then
    fatal "Failed to read the keys '${known_job_keys}' of '${config_path}'"
  fi

  printf -- '%s\n' "${enablement}"
  return 0
}

if [[ ! -f "${ci_config_path}" ]]; then
  fatal "There is no '${ci_config_path}'" \
    "Every repository must have one, even when it turns nothing off, in which case it holds '{}'." \
    "The known keys are: ${known_job_keys}"
fi

validate_ci_config "${ci_config_path}"

enablement="$(enablement_of_known_keys "${ci_config_path}")"
readonly enablement

log "Job keys of '${ci_config_path}': ${enablement//$'\n'/, }"

printf -- '%s\n' "${enablement}"
