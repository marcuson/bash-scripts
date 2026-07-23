#!/usr/bin/env bash
# shellcheck disable=SC1091

set -euo pipefail

_root_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# shellcheck source="argc_scripts/build.sh"
source "$_root_dir/argc_scripts/build.sh"

# @cmd
build() {
    build_entrypoint
}

# See more details at https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"
