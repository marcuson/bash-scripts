#!/usr/bin/env bash

Mbs:LinuxInit:setSwappiness() {
    # Defaults
    local swappiness_default=60
    # Dirs
    local swappiness_conf_f="/etc/sysctl.d/swappiness.conf"
    # Apply default if conf is not found
    local swappiness="${MBS__LI__RAM_SWAPPINESS__VALUE:=$swappiness_default}"

    Mbs:Io:print "Setting custom swappiness"
    Mbs:Io:print "New swappiness value: $swappiness"
    echo "vm.swappiness=$swappiness" | tee "$swappiness_conf_f" >/dev/null
    Mbs:Io:print "Custom swappiness set, it will be applied from the next reboot"
    return 0
}
