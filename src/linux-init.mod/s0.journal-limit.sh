#!/usr/bin/env bash

Mbs:LinuxInit:limitJournal() {
    # Defaults
    local config_journal_system_max_default="1024M"
    local config_journal_file_max_default="100M"
    # Dirs
    local journal_conf_d="/etc/systemd/journald.conf.d"
    local journal_conf_f="${journal_conf_d}/size.conf"

    # Apply default if conf is not found
    local system_max="${MBS__LI__JOURNAL_LIMIT__SYSTEM_MAX:=$config_journal_system_max_default}"
    local file_max="${MBS__LI__JOURNAL_LIMIT__FILE_MAX:=$config_journal_file_max_default}"

    Mbs:Io:print "Limit journal size"
    mkdir -p "$journal_conf_d"
    Mbs:Io:print "Using SystemMaxUse=$system_max | SystemMaxFileSize=$file_max"
    echo -e "[Journal]\nSystemMaxUse=$system_max\nSystemMaxFileSize=$file_max" | tee "$journal_conf_f" >/dev/null
    Mbs:Io:print "New conf file is located at $journal_conf_f"
    Mbs:Io:print "Journal size limited"
    return 0
}
