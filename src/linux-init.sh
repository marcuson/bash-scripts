#!/usr/bin/env bash
# shellcheck disable=SC1091

# @describe Init a new Linux machine.
# @meta version 0.0.1
# @meta require-tools sudo

set -euo pipefail

# !mbs keep
_this_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# !mbs include=linux-init.mod/linux-init.tpl.env
cfg_tpl_content=$(base64 -w0 "$_this_dir/linux-init.mod/linux-init.tpl.env")

# shellcheck source=utils.mod/io.sh
source "$_this_dir/utils.mod/io.sh"
# shellcheck source=utils.mod/script.sh
source "$_this_dir/utils.mod/script.sh"

# Constants
readonly progress_filename="progress"
readonly bw_filename="bw.sessions"

# @cmd Create a config template.
# @arg out-file Where to write the file. Defaults to /etc/linux-init/config.env
cfg() {
	Mbs:Io:print "Generate default config file"

	local cfg_f="${argc_out_file:-/etc/linux-init/config.env}"
	if [[ -f "$cfg_f" ]]; then
		if Mbs:Io:confirmDefaultNo "Config file already exists at $cfg_f, do you want to overwrite it?"; then
			Mbs:Io:debug "Overwrite config file $cfg_f"
		else
			Mbs:Io:print "Config file generation cancelled, exiting."
			exit 0
		fi
	fi

	cfg_d=$(dirname "$cfg_f")
	mkdir -p "$cfg_d"
	echo "$cfg_tpl_content" | base64 --decode >"$cfg_f"
	Mbs:Io:success "Config file generated at $cfg_f"
}

# @cmd run Load config and init the machine.
# @arg cfg-file Config file location. Defaults to /etc/linux-init/config.env
# @option -d --data-dir Data dir location. Defaults to /etc/linux-init/data
run() {
	Mbs:Io:print "Linux init start"

	# Source utils
	# shellcheck source=utils.mod/var.sh
	. "$_this_dir/utils.mod/var.sh"
	# shellcheck source=utils.mod/user.sh
	. "$_this_dir/utils.mod/user.sh"
	# shellcheck source=bw.mod/bw.sh
	. "$_this_dir/bw.mod/bw.sh"

	local data_dir="${argc_data_dir:-/etc/linux-init/data}"
	local helper_f="$data_dir/${progress_filename}"
	export MBS__BW__HELPER_F="$data_dir/${bw_filename}"

	li_modules_d="$_this_dir/linux-init.mod"

	# Create helper files if not found
	mkdir -p "$data_dir"
	if [ ! -f "$helper_f" ]; then
		echo "0" | tee "$helper_f" >/dev/null
	fi

	if [ ! -f "$MBS__BW__HELPER_F" ]; then
		touch "$MBS__BW__HELPER_F" >/dev/null
	fi

	local cfg_file
	cfg_file="${argc_cfg_file:-/etc/linux-init/config.env}"
	Mbs:Var:importDotenv "$cfg_file"

	Mbs:Script:addTrapMultiSignal "Mbs:Bw:lock" INT TERM EXIT

	if ! Mbs:User:isCurrentRunningAsRoot; then
		Mbs:Script:die "This script must be run as root"
	fi

	if ! Mbs:User:isNormal "$LI__USER"; then
		Mbs:Script:die "LI__USER problem, it must be set, it must be a normal user, it must exists"
	fi

	home_user_d=$(sudo -u "$LI__USER" sh -c 'echo $HOME')

	helper_f_content=$(<"$helper_f")

	if [[ "$helper_f_content" == "2" ]]; then
		Mbs:Io:print "All config already done, exiting."
	elif [[ "$helper_f_content" == "0" ]]; then
		_run_step_0
	elif [[ "$helper_f_content" == "1" ]]; then
		_run_step_1
	fi

	exit 0
}

function _run_step_0() {
	Mbs:Io:print "First init pass"

	# APT - update
	Mbs:Io:printSep
	Mbs:Io:print "Updating packages"
	apt -y update
	apt -y upgrade
	echo "Packages updated"

	# Journal - limit size
	if Mbs:Var:isTrue "$LI__JOURNAL_LIMIT__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.journal-limit.sh
		. "$li_modules_d/s0.journal-limit.sh"
		Mbs:LinuxInit:limitJournal || Mbs:Script:die "Failed to limit journal size"
	fi

	# RAM - set swappiness
	if Mbs:Var:isTrue "$LI__RAM_SWAPPINESS__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.swappiness.sh
		. "$li_modules_d/s0.swappiness.sh"
		Mbs:LinuxInit:setSwappiness || Mbs:Script:die "Failed to set swappiness"
	fi

	# APT - add Docker repo
	if Mbs:Var:isTrue "$LI__ADD_DOCKER_APT_REPO__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.apt-add-docker-repo.sh
		. "$li_modules_d/s0.apt-add-docker-repo.sh"
		Mbs:LinuxInit:aptAddDockerRepo || Mbs:Script:die "Failed to add Docker APT repo"
	fi

	# APT - install packages
	if Mbs:Var:isTrue "$LI__APT_INSTALL_PACKAGES__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.apt-install-pkgs.sh
		. "$li_modules_d/s0.apt-install-pkgs.sh"
		Mbs:LinuxInit:installAptPackages || Mbs:Script:die "Failed to install APT packages"
	fi

	# User - add to groups
	if Mbs:Var:isTrue "$LI__USER_ADD_TO_GROUPS__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.user-groups.sh
		. "$li_modules_d/s0.user-groups.sh"
		Mbs:LinuxInit:addUserToGroups || Mbs:Script:die "Failed to add user to groups"
	fi

	# User - sudo without password
	if Mbs:Var:isTrue "$LI__PASSWORDLESS_SUDO__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.user-passwordless-sudo.sh
		. "$li_modules_d/s0.user-passwordless-sudo.sh"
		Mbs:LinuxInit:enablePasswordlessSudo || Mbs:Script:die "Failed to enable passwordless sudo"
	fi

	# Nano - enable syntax highlighting
	if Mbs:Var:isTrue "$LI__NANO_SYNTAX_HIGHLIGHTING__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.nano-syntax-highlighting.sh
		. "$li_modules_d/s0.nano-syntax-highlighting.sh"
		Mbs:LinuxInit:enableNanoSyntaxHighlighting || Mbs:Script:die "Failed to enable nano syntax highlighting"
	fi

	# Network - enable routing
	if Mbs:Var:isTrue "$LI__NETWORK_ROUTING__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.network-routing.sh
		. "$li_modules_d/s0.network-routing.sh"
		Mbs:LinuxInit:enableRouting || Mbs:Script:die "Failed to enable network routing"
	fi

	# Network - enable src valid mark
	if Mbs:Var:isTrue "$LI__NETWORK_SRC_VALID_MARK__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.network-src-valid-mark.sh
		. "$li_modules_d/s0.network-src-valid-mark.sh"
		Mbs:LinuxInit:enableNetSrcValidMark || Mbs:Script:die "Failed to enable network src valid mark"
	fi

	# SSH - prepare
	Mbs:Io:printSep
	# shellcheck source=linux-init.mod/s0.ssh-prepare.sh
	. "$li_modules_d/s0.ssh-prepare.sh"
	Mbs:LinuxInit:prepareSSH || Mbs:Script:die "Failed to prepare SSH"

	# Services - docker
	if Mbs:Var:isTrue "$LI__SRV_DOCKER_ENABLER__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.docker-service-enabler.sh
		. "$li_modules_d/s0.docker-service-enabler.sh"
		Mbs:LinuxInit:enableDockerService || Mbs:Script:die "Failed to enable Docker services"
	fi

	# Git - config
	if Mbs:Var:isTrue "$LI__GIT_CONFIG__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.git-config.sh
		. "$li_modules_d/s0.git-config.sh"
		Mbs:LinuxInit:configGit || Mbs:Script:die "Failed to configure Git"
	fi

	# Install oh-my-posh
	if Mbs:Var:isTrue "$LI__INSTALL_OH_MY_POSH__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.install-oh-my-posh.sh
		. "$li_modules_d/s0.install-oh-my-posh.sh"
		Mbs:LinuxInit:installOhMyPosh || Mbs:Script:die "Failed to install oh-my-posh"
	fi

	# Install SOPS
	if Mbs:Var:isTrue "$LI__INSTALL_SOPS__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.install-sops.sh
		. "$li_modules_d/s0.install-sops.sh"
		Mbs:LinuxInit:installSops || Mbs:Script:die "Failed to install SOPS"
	fi

	# Prep Komodo
	if Mbs:Var:isTrue "$LI__KOMODO_PREP__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s0.komodo-prep.sh
		. "$li_modules_d/s0.komodo-prep.sh"
		Mbs:LinuxInit:komodoPrep || Mbs:Script:die "Failed to prep Komodo"
	fi

	# Pass 0 done
	echo "1" | tee "$helper_f" >/dev/null
	Mbs:Io:printSep
	Mbs:Io:success "First part of the config done"
	Mbs:Io:print ""
	Mbs:Io:print "Please check sshd config using 'sudo sshd -t' command and fix any problem before rebooting"
	Mbs:Io:print "If the command sudo sshd -t has no output the config is ok"
	Mbs:Io:print ""
	Mbs:Io:print "Reboot and run this script again to finalize the configuration"
}

function _run_step_1() {
	Mbs:Io:print "Second init pass"

	# Docker - login
	if Mbs:Var:isTrue "$LI__DOCKER_LOGIN__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s1.docker-login.sh
		. "$li_modules_d/s1.docker-login.sh"
		Mbs:LinuxInit:dockerLogin || Mbs:Script:die "Failed to login to Docker"
	fi

	# Docker - custom bridge network
	if Mbs:Var:isTrue "$LI__DOCKER_NETWORK_CUSTOM_BRIDGE__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s1.docker-custom-bridge.sh
		. "$li_modules_d/s1.docker-custom-bridge.sh"
		Mbs:LinuxInit:createCustomDockerBridgeNetwork || Mbs:Script:die "Failed to create custom Docker bridge network"
	fi

	# Backup - restore
	if Mbs:Var:isTrue "$LI__BACKUP_RESTORE__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s1.backup-restore.sh
		. "$li_modules_d/s1.backup-restore.sh"
		Mbs:LinuxInit:restoreBackup || Mbs:Script:die "Failed to restore backup"
	fi

	if Mbs:Var:isTrue "$LI__DOCKER_COMPOSE_START__IS_ENABLED"; then
		Mbs:Io:printSep
		# shellcheck source=linux-init.mod/s1.docker-compose-start.sh
		. "$li_modules_d/s1.docker-compose-start.sh"
		Mbs:LinuxInit:startDockerCompose || Mbs:Script:die "Failed to start Docker Compose"
	fi

	echo "2" | tee "$helper_f" >/dev/null
	Mbs:Io:printSep
	Mbs:Io:success "Second part of the config done"
}

eval "$(argc --argc-eval "$0" "$@")"
