#!/usr/bin/env bash

Mbs:LinuxInit:addUserToGroups() {
    Mbs:Io:print "Adding user to groups"

    Mbs:Var:isSet "LI__USER" || return 1
    Mbs:Var:isSet "LI__USER_ADD_TO_GROUPS__GROUPS" || return 1

    Mbs:Io:print "Adding $LI__USER to $LI__USER_ADD_TO_GROUPS__GROUPS groups"
    usermod -aG "$LI__USER_ADD_TO_GROUPS__GROUPS" "$LI__USER"
    return 0
}
