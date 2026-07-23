#!/usr/bin/env bash

_umod_user_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# shellcheck source=var.sh
. "$_umod_user_dir/var.sh"

# Check whether the current process is running as root.
#
# Returns:
#   0 if the current user is root.
#   1 otherwise.
Mbs:User:isCurrentRunningAsRoot() {
    if [ ! "${EUID:-$(id -u)}" -eq 0 ]; then
        return 1
    fi
    return 0
}

# Check whether a supplied username is a normal non-root user.
#
# Args:
#   $1: Username to inspect.
# Returns:
#   0 if the user exists and is not root.
#   1 otherwise.
Mbs:User:isNormal() {
    [ $# -eq 0 ] && return 1
    Mbs:Var:isEmpty "$1" && return 1
    ! id "$1" &>/dev/null && return 1
    [ "$1" = "root" ] && return 1
    return 0
}

# Check whether the current user belongs to a group.
#
# Args:
#   $1: Name of the group to check.
# Returns:
#   0 if the current user is in the group.
#   1 otherwise.
Mbs:User:isCurrentInGroup() {
    [ $# -eq 0 ] && return 1
    Mbs:Var:isEmpty "$1" && return 1
    groups 2>/dev/null | grep -q "\b$1\b"
}

# Check whether a given user belongs to a group.
#
# Args:
#   $1: Username to inspect.
#   $2: Name of the group to check.
# Returns:
#   0 if the user is in the group.
#   1 otherwise.
Mbs:User:isUserInGroup() {
    [ $# -lt 2 ] && return 1
    Mbs:Var:isEmpty "$1" && return 1
    Mbs:Var:isEmpty "$2" && return 1
    groups "$1" 2>/dev/null | grep -q "\b$2\b"
}
