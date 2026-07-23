#!/usr/bin/env bash

Mbs:AndroidInit:installPkgPackages() {
    declare -a config_pkgs_arr
    Mbs:Io:print "Installing new packages"

    readarray -td, config_pkgs_arr <<<"$MBS__AI__PKG_INSTALL_PACKAGES__PACKAGES,"
    unset 'config_pkgs_arr[-1]'

    Mbs:Io:print "New packages to install: ${config_pkgs_arr[*]}"
    pkg install -y "${config_pkgs_arr[@]}"
    return 0
}
