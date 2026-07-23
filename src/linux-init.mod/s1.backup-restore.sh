#!/usr/bin/env bash

Mbs:LinuxInit:restoreBackup() {
    Mbs:Io:print "Restoring backup"

    Mbs:Var:isSet "MBS__LI__BACKUP_RESTORE__FILE_PATH" || return 1

    if [ ! -f "$MBS__LI__BACKUP_RESTORE__FILE_PATH" ]; then
        Mbs:Io:print "Cannot find $MBS__LI__BACKUP_RESTORE__FILE_PATH, please check"
        return 1
    else
        tar --same-owner -xf "$MBS__LI__BACKUP_RESTORE__FILE_PATH" -C /
    fi

    Mbs:Io:print "Backup restored"
    return 0
}
