#!/usr/bin/env bash
# shellcheck disable=SC1091

# @describe Hello world test
# @meta version 0.0.1

set -euo pipefail

_this_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# shellcheck source=utils.mod/io.sh
source "$_this_dir/utils.mod/io.sh"

_entry() {
	Mbs:Io:print "Hello World from marcuson/bash-scripts!"
}

eval "$(argc --argc-eval "$0" "$@")"

_entry
