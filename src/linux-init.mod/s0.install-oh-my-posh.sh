#!/usr/bin/env bash

Mbs:LinuxInit:installOhMyPosh() {
	Mbs:Io:print "Installing oh-my-posh"

	if ! Mbs:User:isNormal "$LI__USER"; then
		Mbs:Script:die "LI__USER problem, it must be set, it must be a normal user, it must exists"
	fi

	sudo -u "$LI__USER" bash -c "curl -s https://ohmyposh.dev/install.sh | bash -s"

	if Mbs:Var:isEmpty "$home_user_d"; then
		home_user_d=$(sudo -u "$LI__USER" sh -c 'echo $HOME')
	fi

	local profile_user_f="$home_user_d/.profile"

	if [ ! -f "$profile_user_f" ] || ! grep -q 'oh-my-posh' "$profile_user_f"; then
		local user_default_shell
		user_default_shell=$(awk -F: -v user="$LI__USER" '$1 == user {print $NF}' /etc/passwd)

		sudo -u "$LI__USER" "$user_default_shell" -c 'export PATH=$PATH:$HOME/.local/bin; oh-my-posh font install meslo'

		local omp_shell
		omp_shell=$(sudo -u "$LI__USER" "$user_default_shell" -c 'export PATH=$PATH:$HOME/.local/bin; oh-my-posh get shell; echo $SHELL 2>&1 > /dev/null')

		sudo -u "$LI__USER" bash -c "wget https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/OhMyPosh-Atomic-Custom-ExperimentalDividers.json -O $home_user_d/.omp.json"

		cat <<EOF >>"$profile_user_f"
if [ -n "\$DISPLAY" ] || [ -n "\$WAYLAND_DISPLAY" ] || [ "\$TERM" = "xterm-256color" ]; then
    eval \"\$(oh-my-posh init $omp_shell --config $home_user_d/.omp.json)\""
fi
EOF

		Mbs:Io:print "oh-my-posh installed"
	else
		Mbs:Io:print "$profile_user_f already configured"
	fi

	return 0
}
