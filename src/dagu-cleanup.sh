#!/usr/bin/env bash
# shellcheck disable=SC1091

# @describe Remove empty Dagu logs folders.
# @meta version 0.0.1
# @meta require-tools curl
# @meta require-tools grep
# @meta require-tools host
# @meta require-tools jq
# @arg dagu-home Home dir of Dagu.

set -euo pipefail

_this_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# shellcheck source=utils.mod/io.sh
source "$_this_dir/utils.mod/io.sh"
# shellcheck source=utils.mod/script.sh
source "$_this_dir/utils.mod/script.sh"

_entry() {
  config_dir=${argc_dagu_home:-/var/lib/dagu}
  logs_dir="$config_dir/logs"

  if [ ! -d "${config_dir}" ]; then
    Mbs:Script:die "Config dir '${config_dir}' does not exists."
  fi

  if [ ! -d "${logs_dir}" ]; then
    Mbs:Script:die "Logs dir '${logs_dir}' does not exists."
  fi

  Mbs:Io:print "Delete empty logs"
  logs_deleted_count=$(find "${logs_dir}" -mindepth 2 -type d -empty -print -delete | tee /dev/stderr | wc -l)
  Mbs:Io:print "$logs_deleted_count empty log dirs deleted."
}

eval "$(argc --argc-eval "$0" "$@")"

_entry
