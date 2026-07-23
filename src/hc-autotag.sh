#!/usr/bin/env bash
# shellcheck disable=SC1091

# @describe Autotag Healthchecks pings based on name
# @meta version 0.0.1
# @meta require-tools curl
# @meta require-tools jq
# @option -u --url! $HC_BASE_URL Healthchecks base URL.
# @option -k --api-key! $HC_API_KEY API key.

set -euo pipefail

_this_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# shellcheck source=utils.mod/io.sh
source "$_this_dir/utils.mod/io.sh"
# shellcheck source=utils.mod/script.sh
source "$_this_dir/utils.mod/script.sh"

_entry() {
  # shellcheck disable=SC2154
  hc_base_url=${argc_url}
  # shellcheck disable=SC2154
  api_key=${argc_api_key}

  # 1. Get all checks from the API
  Mbs:Io:print "Fetching all checks from the v3 API..."
  checks_json=$(curl -s -H "X-Api-Key: $api_key" "$hc_base_url/api/v3/checks/")

  # Check if the API call was successful
  if [ ! $? ]; then
    Mbs:Script:die "Failed to fetch checks from the API. Please check your network connection."
  fi

  # Check for an empty response
  if [ -z "$checks_json" ]; then
    Mbs:Script:die "Empty response from the API. Please check your API key and the API endpoint."
  fi

  # 2. Process each check using jq
  Mbs:Io:print "Processing checks and updating tags..."
  echo "$checks_json" | jq -c '.checks[]' | while read -r check; do
    # Extract the slug and the uuid for the check
    slug=$(echo "$check" | jq -r '.slug')
    check_uuid=$(echo "$check" | jq -r '.uuid')

    if [ -z "$slug" ] || [ "$slug" == "null" ]; then
      Mbs:Io:warn "Skipping a check because its slug is empty."
      continue
    fi

    # 3. Split the slug and get the first part
    new_tag=$(echo "$slug" | cut -d'-' -f1)

    if [ -z "$new_tag" ]; then
      Mbs:Io:warn "Could not determine a new tag for check with slug: $slug"
      continue
    fi

    Mbs:Io:print "Check with slug '$slug' will be tagged with: '$new_tag'"

    # 4. Assign the new tag to the check
    update_payload="{\"tags\": \"$new_tag\"}"
    curl -s -X POST -H "X-Api-Key: $api_key" -H "Content-Type: application/json" -d "$update_payload" "${hc_base_url}/api/v3/checks/${check_uuid}"

    if [ ! $? ]; then
      Mbs:Io:print "Successfully updated check with slug '$slug'."
    else
      Mbs:Io:error "Failed to update check with slug '$slug'."
    fi
  done
}

eval "$(argc --argc-eval "$0" "$@")"

_entry
