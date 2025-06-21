#!/usr/bin/env bash

set -e

fsource=${BASH_SOURCE[0]}
while [ -L "$fsource" ]; do # resolve $SOURCE until the file is no longer a symlink
  fdir=$( cd -P "$( dirname "$fsource" )" >/dev/null 2>&1 && pwd )
  fdir=$(readlink "$fsource")
  [[ $fsource != /* ]] && fsource=$fdir/$fsource # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the syml>
done
scriptDir=$( cd -P "$( dirname "$fsource" )" >/dev/null 2>&1 && pwd )

# OPTSTRING=":k:"

# while getopts ${OPTSTRING} opt; do
#   case ${opt} in
#     k)
#       wtApiToken="${OPTARG}"
#       ;;
#     ?)
#       >&2 echo "Invalid option: -$OPTARG"
#       exit 1
#       ;;
#     :)
#       >&2 echo "Option -$OPTARG requires an argument."
#       exit 1
#       ;;
#   esac
# done

# shift $((OPTIND-1))

configDir=${1:-${DAGU_HOME:-/var/lib/dagu}}
logsDir="$configDir/logs"

if [ ! -d "${configDir}" ]; then
  >&2 echo "Config dir '${configDir}' does not exists."
  exit 1
fi


if [ ! -d "${logsDir}" ]; then
  >&2 echo "Logs dir '${logsDir}' does not exists."
  exit 1
fi

echo "Delete empty logs"
logsDeletedCount=$(find "${logsDir}" -mindepth 2 -type d -empty -print -delete | tee /dev/stderr | wc -l)
echo "$logsDeletedCount empty log dirs deleted."

set +e
