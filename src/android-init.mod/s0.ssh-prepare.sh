#!/usr/bin/env bash

# FIXME: Merge with linux-init.sh

Mbs:AndroidInit:prepareSSH() {
	if Mbs:Var:isEmpty "$home_user_d"; then
		home_user_d="$HOME"
	fi

	local ssh_user_d="$home_user_d/.ssh"
	export ssh_auth_keys_user_f="$ssh_user_d/authorized_keys"
	export ssh_known_hosts_user_f="$ssh_user_d/known_hosts"

	mkdir -p "$ssh_user_d"
	touch "$ssh_auth_keys_user_f" "$ssh_known_hosts_user_f"
	chmod 700 "$ssh_user_d"
	chmod 600 "$ssh_auth_keys_user_f" "$ssh_known_hosts_user_f"
	Mbs:Io:print ".ssh folders and basic files added"
	return 0
}
