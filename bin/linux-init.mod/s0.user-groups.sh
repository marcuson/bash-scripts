#!/usr/bin/env bash

LinuxInitMod:addUserToGroups() {
    IO:print "Adding user to groups"

    LinuxInitMod:checkConfig "LI__USER" || return 1
    LinuxInitMod:checkConfig "LI__USER_ADD_TO_GROUPS__GROUPS" || return 1

    IO:print "Adding $LI__USER to $LI__USER_ADD_TO_GROUPS__GROUPS groups"
    usermod -aG "$LI__USER_ADD_TO_GROUPS__GROUPS" "$LI__USER"
    return 0
}
