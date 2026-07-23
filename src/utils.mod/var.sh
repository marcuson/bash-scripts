#!/usr/bin/env bash

_umod_var_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# shellcheck source=io.sh
. "$_umod_var_dir/io.sh"

# Checks whether a value represents a true-like boolean value.
#
# Args:
#   value: The value to evaluate.
# Returns:
#   0 when the value is one of: 1, y, true.
#   1 otherwise.
Mbs:Var:isTrue() {
    local var_value
    var_value="$1"

    case "${var_value}" in
    1 | y | true)
        return 0
        ;;
    *)
        return 1
        ;;
    esac
}

# Checks whether a variable is set in the current shell.
#
# Args:
#   var_name: Name of the variable to check.
# Returns:
#   0 if the variable exists and is defined, 1 otherwise.
Mbs:Var:isSet() {
    [ $# -eq 0 ] && return 1
    [ -z "$1" ] && return 1
    declare -p "$1" &>/dev/null
}

# Checks whether a value is empty.
#
# Args:
#   value: The value to check.
# Returns:
#   0 if the provided value is empty, 1 otherwise.
Mbs:Var:isEmpty() {
    [ $# -eq 0 ] && return 1
    [ -z "$1" ] && return 0
    return 1
}

# Returns the detected type of a variable.
#
# Args:
#   var_name: Name of the variable to inspect.
# Returns:
#   0 on success, 1 if the variable is unset.
# Output:
#   Prints ARRAY, HASH, INT, EXPORT, or OTHER.
Mbs:Var:getType() {
    if ! Mbs:Var:isSet "$1"; then
        Mbs:Io:print "UNSET"
        return 1
    fi

    local var
    var=$(declare -p "$1" 2>/dev/null)
    local reg='^declare -n [^=]+=\"([^\"]+)\"$'
    while [[ $var =~ $reg ]]; do
        var=$(declare -p "${BASH_REMATCH[1]}")
    done

    case "${var#declare -}" in
    a*)
        Mbs:Io:print "ARRAY"
        ;;
    A*)
        Mbs:Io:print "HASH"
        ;;
    i*)
        Mbs:Io:print "INT"
        ;;
    x*)
        Mbs:Io:print "EXPORT"
        ;;
    *)
        Mbs:Io:print "OTHER"
        ;;
    esac
    return 0
}

# Checks whether a variable is an array.
#
# Args:
#   var_name: Name of the variable to inspect.
# Returns:
#   0 if the variable is an array, 1 otherwise.
Mbs:Var:isArray() {
    Mbs:Var:getType "$1" | grep -q "ARRAY"
}

# Checks whether a variable is an integer.
#
# Args:
#   var_name: Name of the variable to inspect.
# Returns:
#   0 if the variable is an integer, 1 otherwise.
Mbs:Var:isInt() {
    Mbs:Var:getType "$1" | grep -q "INT"
}

# Checks whether a variable is a scalar value of another type.
#
# Args:
#   var_name: Name of the variable to inspect.
# Returns:
#   0 if the variable is neither an array nor an integer, 1 otherwise.
Mbs:Var:isOther() {
    Mbs:Var:getType "$1" | grep -q "OTHER"
}

# Imports variables from a dotenv file into the current shell.
#
# Args:
#   env_file: Path to the dotenv file to import.
# Returns:
#   0 on success, 1 if the file does not exist.
# Note:
#   The imported values are sourced from a temporary cleaned file.
Mbs:Var:importDotenv() {
    local env_file="$1" env_vars=""
    if [[ -f "$env_file" ]]; then
        while IFS='=' read -r key value; do
            if [[ "$key" == $'#'* ]] || [[ -z "$key" ]]; then
                continue
            fi
            if [[ -z "${!key+x}" ]]; then
                env_vars="$env_vars $key=$value"
            fi
        done < <(
            cat "$env_file"
            echo ""
        )
        if [[ -n "$env_vars" ]]; then
            eval "export $env_vars"
        fi
    fi
}
