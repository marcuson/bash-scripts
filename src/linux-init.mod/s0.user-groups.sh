#!/usr/bin/env bash

Mbs:LinuxInit:addUserToGroups() {
    Mbs:Io:print "Adding user to groups"

    Mbs:Var:isSet "MBS__LI__USER" || return 1
    Mbs:Var:isSet "MBS__LI__USER_ADD_TO_GROUPS__GROUPS" || return 1

    Mbs:Io:print "Adding $MBS__LI__USER to $MBS__LI__USER_ADD_TO_GROUPS__GROUPS groups"
    usermod -aG "$MBS__LI__USER_ADD_TO_GROUPS__GROUPS" "$MBS__LI__USER"
    return 0
}
