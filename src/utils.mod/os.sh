#!/usr/bin/env bash

_umod_os_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# shellcheck source=io.sh
. "$_umod_os_dir/io.sh"

# Enable a service if exists
# $1 service name
# $2 true/false start service
# EG: enableService docker true
Mbs:Os:enableService() {
	[ $# -eq 0 ] && return 1

	local serviceName="$1"
	local startService="${2:-false}" # Default value is false
	Mbs:Io:print "Enabling service '$serviceName'"

	systemctl list-unit-files | grep "$serviceName" 1>/dev/null 2>&1
	if ! systemctl list-unit-files | grep "$serviceName" 1>/dev/null 2>&1; then
		Mbs:Io:error "$serviceName service does NOT exist."
		return 1
	fi

	if [ "$startService" = true ]; then
		systemctl enable --now "$serviceName"
		Mbs:Io:print "$serviceName service enabled and started"
	else
		systemctl enable "$serviceName"
		Mbs:Io:print "$serviceName service enabled"
	fi
	return 0
}
