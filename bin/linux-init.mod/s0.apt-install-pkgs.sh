#!/usr/bin/env bash

LinuxInitMod:installAptPackages() {
    declare -a config_pkgs_arr
    IO:print "Installing new packages"

    if LinuxInitMod:isVarEmpty "$LI__APT_INSTALL_PACKAGES__PACKAGES"; then
        IO:print "LI__APT_INSTALL_PACKAGES__PACKAGES unset or empty"
        IO:print "Please input one or more space separated APT packages to install, then press enter to confirm:"
        read -r -a config_pkgs_arr
        IO:print ""
    else
        readarray -td, config_pkgs_arr <<<"$LI__APT_INSTALL_PACKAGES__PACKAGES,"
        unset 'config_pkgs_arr[-1]'
    fi

    IO:print "New packages to install: ${config_pkgs_arr[*]}"
    apt -y install "${config_pkgs_arr[@]}"
    return 0
}
