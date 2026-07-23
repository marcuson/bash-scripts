#!/usr/bin/env bash

_umod_script_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# shellcheck source=io.sh
. "$_umod_script_dir/io.sh"

# Registers a trap handler for a signal.
#
# Args:
#   cmd: Command or snippet to run when the trap fires.
#   sig: Signal name or numeric value. Defaults to EXIT.
# Returns:
#   0 if the trap was registered successfully.
#   1 if the signal is invalid.
Mbs:Script:addTrap() {
    local cmd=$1         # command(s) to add
    local sig=${2:-EXIT} # signal name or number

    # validate signal name or numeric id
    local sig_name
    {
        if [[ $sig =~ ^[0-9]+$ ]]; then
            sig_name=$(kill -l "$sig")
        else
            sig_name=${sig^^}
            kill -l "$sig_name" &>/dev/null
        fi
    } || {
        echo "add_trap: invalid signal '$sig'" >&2
        return 1
    }

    # Compute effective trap list for current (sub)shell
    # Based on info from https://stackoverflow.com/a/59307894/5116073
    local old
    if [[ "${BASH_VERSINFO:-0}" -ge 4 ]]; then
        trap -- KILL &>/dev/null || true
        old=$(trap -p "$sig_name")
    else
        old=$( (trap -p "$sig_name"))
    fi

    # extract/cleanup the existing registered command(s)
    old=${old#*\'}         # remove leading "trap -- '"
    old=${old%\'*}         # remove trailing "' EXIT"
    old=${old//"'\''"/"'"} # unescape every '\'' to '

    # if command is already registered, do nothing
    if [[ ";$old;" == *";$cmd;"* ]]; then
        return 0
    fi

    # build the new combined handler
    if [[ -n $old ]]; then
        combined="$old;$cmd"
    else
        combined="$cmd"
    fi

    # register the new combined handler
    trap -- "$combined" "$sig"
}

Mbs:Script:addTrapMultiSignal() {
    local cmd="${1:-}"
    shift || true

    # Validate that at least command and one signal are provided
    if [[ -z "$cmd" || $# -eq 0 ]]; then
        echo "Usage: Mbs:Script:addTrapMultiSignal <command> <signal1> [signal2 ...]" >&2
        return 1
    fi

    local sig
    for sig in "$@"; do
        Mbs:Script:addTrap "$cmd" "$sig" || return 1
    done
}

# Prints the current call stack.
#
# Outputs:
#   Prints each caller and line number to stdout.
Mbs:Script:callStack() {
    local i=1
    while caller $i; do
        ((i++))
    done
}

# Check whether a given name resolves to a shell function.
#
# Args:
#   $1: Name of the function to inspect.
# Returns:
#   0 if the name resolves to a function.
#   1 otherwise.
Mbs:Script:isFunc() {
    local res
    res=$(type -t "$1" || echo "NONE")

    if [ "$res" == "function" ]; then
        return 0
    else
        return 1
    fi
}

Mbs:Script:die() {
    Mbs:Io:error "$@"
    exit 1
}
