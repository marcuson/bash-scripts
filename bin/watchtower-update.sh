#!/usr/bin/env bash

set -e

fsource=${BASH_SOURCE[0]}
while [ -L "$fsource" ]; do # resolve $SOURCE until the file is no longer a symlink
  fdir=$( cd -P "$( dirname "$fsource" )" >/dev/null 2>&1 && pwd )
  fdir=$(readlink "$fsource")
  [[ $fsource != /* ]] && fsource=$fdir/$fsource # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the syml>
done
scriptDir=$( cd -P "$( dirname "$fsource" )" >/dev/null 2>&1 && pwd )

OPTSTRING=":k"

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    k)
      wtApiToken="${OPTARG}"
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

wtApiToken=${wtApiToken:-$WT_API_TOKEN}
wtBaseUrl=${1}

if [ -z "$wtApiToken" ]; then
  >&2 echo "Missing Watchtower API token."
  exit 1
fi

curl -H "Authorization: Bearer $wtApiToken" ${wtBaseUrl}/v1/update || [ $? -eq 52 ]