#!/usr/bin/env bash

LinuxInitMod:restoreBackup() {
    IO:print "Restoring backup"

    LinuxInitMod:checkConfig "LI__BACKUP_RESTORE__FILE_PATH" || return 1

    if [ ! -f "$LI__BACKUP_RESTORE__FILE_PATH" ]; then
        IO:print "Cannot find $LI__BACKUP_RESTORE__FILE_PATH, please check"
        return 1
    else
        tar --same-owner -xf "$LI__BACKUP_RESTORE__FILE_PATH" -C /
    fi

    IO:print "Backup restored"
    return 0
}
