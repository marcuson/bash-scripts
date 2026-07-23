#!/usr/bin/env bash

Mbs:LinuxInit:installAptPackages() {
    declare -a config_pkgs_arr
    Mbs:Io:print "Installing new packages"

    if Mbs:Var:isEmpty "$MBS__LI__APT_INSTALL_PACKAGES__PACKAGES"; then
        Mbs:Io:print "MBS__LI__APT_INSTALL_PACKAGES__PACKAGES unset or empty"
        Mbs:Io:print "Please input one or more space separated APT packages to install, then press enter to confirm:"
        read -r -a config_pkgs_arr
        Mbs:Io:print ""
    else
        readarray -td, config_pkgs_arr <<<"$MBS__LI__APT_INSTALL_PACKAGES__PACKAGES,"
        unset 'config_pkgs_arr[-1]'
    fi

    Mbs:Io:print "New packages to install: ${config_pkgs_arr[*]}"
    apt -y install "${config_pkgs_arr[@]}"
    return 0
}
