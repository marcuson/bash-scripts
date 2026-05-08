#!/usr/bin/env bash

LinuxInitMod:enableNetSrcValidMark() {
    local systctld_network_conf_f="/etc/sysctl.d/22-network_src_valid_mark.conf"
    IO:print "\n\nAdding network confs to $systctld_network_conf_f"
    echo "net.ipv4.conf.all.src_valid_mark = 1" | tee "$systctld_network_conf_f" >/dev/null
    IO:print "Network src valid mark enabled"
    return 0
}
