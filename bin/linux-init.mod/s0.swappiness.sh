#!/usr/bin/env bash

LinuxInitMod:setSwappiness() {
    # Defaults
    local swappiness_default=60
    # Dirs
    local swappiness_conf_f="/etc/sysctl.d/swappiness.conf"
    # Apply default if conf is not found
    local swappiness="${LI__RAM_SWAPPINESS__VALUE:=$swappiness_default}"

    IO:print "Setting custom swappiness"
    IO:print "New swappiness value: $swappiness"
    echo "vm.swappiness=$swappiness" | tee "$swappiness_conf_f" >/dev/null
    IO:print "Custom swappiness set, it will be applied from the next reboot"
    return 0
}
