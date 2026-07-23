#!/usr/bin/env bash

Mbs:LinuxInit:restoreBackup() {
    Mbs:Io:print "Restoring backup"

    Mbs:Var:isSet "LI__BACKUP_RESTORE__FILE_PATH" || return 1

    if [ ! -f "$LI__BACKUP_RESTORE__FILE_PATH" ]; then
        Mbs:Io:print "Cannot find $LI__BACKUP_RESTORE__FILE_PATH, please check"
        return 1
    else
        tar --same-owner -xf "$LI__BACKUP_RESTORE__FILE_PATH" -C /
    fi

    Mbs:Io:print "Backup restored"
    return 0
}
