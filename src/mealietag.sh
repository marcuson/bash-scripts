#!/usr/bin/env bash
# shellcheck disable=SC1091

# @describe Encrypt/decrypt a file using a password and GPG.
# @meta version 0.0.1
# @meta require-tools curl
# @meta require-tools jq
# @option -u --url! Mealie base URL.
# @option -k --api-key! API key.

set -euo pipefail

_this_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# shellcheck source=utils.mod/io.sh
source "$_this_dir/utils.mod/io.sh"
# shellcheck source=utils.mod/script.sh
source "$_this_dir/utils.mod/script.sh"

_entry() {
    # shellcheck disable=SC2154
    local mealie_url="${argc_url%/}"
    # shellcheck disable=SC2154
    local mealie_api_key="$argc_api_key"

    local api_base_url="${mealie_url}/api"
    local auth_header="Authorization: Bearer ${mealie_api_key}"
    local inbox_tag_name="INBOX"

    Mbs:Io:print "Checking if tag '$inbox_tag_name' exists..."

    # 1. Get or Create the target tag to obtain its full object (id, name, slug)
    local tag_list tag_obj
    tag_list=$(curl -s -H "$auth_header" "${api_base_url}/organizers/tags?perPage=1000")
    tag_obj=$(echo "$tag_list" | jq -c ".items[] | select(.name == \"$inbox_tag_name\")")

    if [ -z "$tag_obj" ]; then
        Mbs:Io:print "Tag not found. Creating tag '$inbox_tag_name'..."
        tag_obj=$(curl -s -X 'POST' \
            -H "$auth_header" \
            -H 'Content-Type: application/json' \
            -d "{\"name\": \"$inbox_tag_name\"}" \
            "${api_base_url}/organizers/tags")

        # If creation failed (e.g., due to Mealie v1.x group requirements)
        if echo "$tag_obj" | jq -e '.detail' >/dev/null; then
            Mbs:Script:die "Error creating tag: $(echo "$tag_obj" | jq -r '.detail')"
        fi
    fi

    local tag_id
    tag_id=$(echo "$tag_obj" | jq -r '.id')
    Mbs:Io:print "Using Tag ID: $tag_id"

    # 2. Fetch recipes and find those with no tags
    Mbs:Io:print "Fetching all untagged recipes..."
    # Note: perPage=1000 is used to avoid complex pagination logic for most home libraries
    local recipes_json
    recipes_json=$(curl -s --fail-with-body -H "$auth_header" "${api_base_url}/recipes?perPage=1000&queryFilter=tags.name%20IS%20null")

    # Filter for IDs of recipes where the 'tags' array is empty
    local untagged_slugs
    untagged_slugs=$(echo "$recipes_json" | jq -r '.items[] | select(.tags | length == 0) | .slug')

    if [ -z "$untagged_slugs" ]; then
        Mbs:Io:print "No untagged recipes found."
        return 0
    fi

    # Count how many we found
    local untagged_count
    untagged_count=$(echo "$untagged_slugs" | wc -l)
    Mbs:Io:print "Found $untagged_count untagged recipes. Applying tag..."

    # 3. Perform Bulk Tag Action
    # Convert IDs into a JSON array
    local untagged_slugs_array
    untagged_slugs_array=$(echo "$untagged_slugs" | jq -R . | jq -s -c .)

    # Mealie Bulk Action Body
    # Note: Newer Mealie versions may require the full tag object inside the array
    local bulk_payload
    bulk_payload=$(jq -n \
        --argjson recipes "$untagged_slugs_array" \
        --argjson tag "[$tag_obj]" \
        '{recipes: $recipes, tags: $tag}')

    local api_response_code
    api_response_code=$(curl -o /dev/null -w "%{http_code}\n" -s -X 'POST' \
        -H "$auth_header" \
        -H 'Content-Type: application/json' \
        -d "$bulk_payload" \
        "${api_base_url}/recipes/bulk-actions/tag")

    if [[ $api_response_code == "200" ]]; then
        Mbs:Io:print "Successfully assigned '$inbox_tag_name' to $untagged_count recipes."
    else
        Mbs:Script:die "HTTP status code from server: $api_response_code"
    fi
}

eval "$(argc --argc-eval "$0" "$@")"

_entry
