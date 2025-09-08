#!/usr/bin/env bash

set -e

fsource=${BASH_SOURCE[0]}
while [ -L "$fsource" ]; do # resolve $SOURCE until the file is no longer a symlink
  fdir=$( cd -P "$( dirname "$fsource" )" >/dev/null 2>&1 && pwd )
  fdir=$(readlink "$fsource")
  [[ $fsource != /* ]] && fsource=$fdir/$fsource # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the syml>
done
scriptDir=$( cd -P "$( dirname "$fsource" )" >/dev/null 2>&1 && pwd )

OPTSTRING=":u:k:"

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    u)
      hcBaseUrl="${OPTARG}"
      ;;
    k)
      apiKey="${OPTARG}"
      ;;
    ?)
      >&2 echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      >&2 echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

hcBaseUrl=${hcBaseUrl:-$HC_BASE_URL}
apiKey=${apiKey:-$HC_API_KEY}

if [ -z "$hcBaseUrl" ]; then
  >&2 echo "Missing HC base URL (-u or HC_BASE_URL)."
  exit 1
fi

if [ -z "$apiKey" ]; then
  >&2 echo "Missing HC API token (-k or HC_API_KEY)."
  exit 1
fi

echo "--- hc-autotag (start) ---"

# 1. Get all checks from the API
echo "Fetching all checks from the v3 API..."
checksJson=$(curl -s -H "X-Api-Key: $apiKey" "$hcBaseUrl/api/v3/checks/")

# Check if the API call was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch checks from the API. Please check your network connection."
    exit 1
fi

# Check for an empty response
if [ -z "$checksJson" ]; then
    echo "Error: Empty response from the API. Please check your API key and the API endpoint."
    exit 1
fi

# 2. Process each check using jq
echo "Processing checks and updating tags..."
echo "$checksJson" | jq -c '.checks[]' | while read -r check; do
    # Extract the slug and the uuid for the check
    slug=$(echo "$check" | jq -r '.slug')
    check_uuid=$(echo "$check" | jq -r '.uuid')

    if [ -z "$slug" ] || [ "$slug" == "null" ]; then
        echo "Skipping a check because its slug is empty."
        continue
    fi

    # 3. Split the slug and get the first part
    new_tag=$(echo "$slug" | cut -d'-' -f1)

    if [ -z "$new_tag" ]; then
        echo "Could not determine a new tag for check with slug: $slug"
        continue
    fi

    echo "  - Check with slug '$slug' will be tagged with: '$new_tag'"

    # 4. Assign the new tag to the check
    update_payload="{\"tags\": \"$new_tag\"}"
    update_response=$(curl -s -X POST -H "X-Api-Key: $apiKey" -H "Content-Type: application/json" -d "$update_payload" "${hcBaseUrl}/api/v3/checks/${check_uuid}")


    if [ $? -eq 0 ]; then
        echo "    ... Successfully updated."
    else
        echo "    ... Failed to update."
    fi
done

echo "--- hc-autotag (done) ---"
set +e