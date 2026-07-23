#!/usr/bin/env bash

_argc_scripts_const_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

root_dir=$(realpath "$_argc_scripts_const_dir/..")
bin_dir="$root_dir/bin"
src_dir="$root_dir/src"
export root_dir
export bin_dir
export src_dir
