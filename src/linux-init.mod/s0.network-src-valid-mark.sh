#!/usr/bin/env bash

Mbs:LinuxInit:enableNetSrcValidMark() {
    local systctld_network_conf_f="/etc/sysctl.d/22-network_src_valid_mark.conf"
    Mbs:Io:print "\n\nAdding network confs to $systctld_network_conf_f"
    echo "net.ipv4.conf.all.src_valid_mark = 1" | tee "$systctld_network_conf_f" >/dev/null
    Mbs:Io:print "Network src valid mark enabled"
    return 0
}
