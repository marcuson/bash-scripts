#!/usr/bin/env bash

# @describe Init a new Android machine.
# @meta version 0.0.1

#region Meta moved
# @meta require-tools bw
#endregion Meta moved

set -euo pipefail

_this_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# File included (base64) [android-init.mod/config.tpl.env]
cfg_tpl_content="IyBDb25maWd1cmFibGUgdmFyaWFibGVzCgojIC0tIEdlbmVyYWwKIyAtLS0tIEJpdHdhcmRlbiBpbnRlZ3JhdGlvbgpNQlNfX0JXX19VUkw9eHh4Ck1CU19fQldfX0NMSUVOVF9JRD14eHgKTUJTX19CV19fQ0xJRU5UX1NFQ1JFVD14eHgKTUJTX19CV19fTUFTVEVSX1BBU1NXT1JEPXh4eAoKIyAtLSBTdGVwIDAKIyAtLS0tIFBLRyAtIGluc3RhbGwgcGFja2FnZXMKTUJTX19BSV9fUEtHX0lOU1RBTExfUEFDS0FHRVNfX0lTX0VOQUJMRUQ9eQpNQlNfX0FJX19QS0dfSU5TVEFMTF9QQUNLQUdFU19fUEFDS0FHRVM9InRlcm11eC1hcGksdGVybXV4LWd1aS1wYWNrYWdlLG9wZW5zc2gsZ2l0LHJpcGdyZXAsbnBtIgojIC0tLS0gR2l0IC0gYmFzaWMgY29uZmlnCk1CU19fQUlfX0dJVF9DT05GSUdfX0lTX0VOQUJMRUQ9eQpNQlNfX0FJX19HSVRfQ09ORklHX19VU0VSTkFNRT0iRmlyc3ROYW1lIExhc3ROYW1lIgpNQlNfX0FJX19HSVRfQ09ORklHX19FTUFJTD0ieHh4QHh4eC5jb20iCiMgLS0tLSBTU0ggLSBwcmVwYXJlCiMgTk9URTogTm8gY29uZmlnIGZvciBub3cK"

#region Bundler import [utils.mod/io.sh]

# Prints text to stdout.
#
# Args:
#   msg: Message or text to print. Accepts multiple arguments.
# Outputs:
#   Prints the provided message to stdout.
Mbs:Io:print() {
	printf '%b\n' "$*"
}

# Prints an error message with an [ERR] prefix.
#
# Args:
#   msg: Error message text to print.
# Outputs:
#   Prints the provided message to stdout with an [ERR] prefix.
Mbs:Io:error() {
	Mbs:Io:print '[ERR]' "$*"
}

# Prints a warning message with a [WRN] prefix.
#
# Args:
#   msg: Warning message text to print.
# Outputs:
#   Prints the provided message to stdout with a [WRN] prefix.
Mbs:Io:warn() {
	Mbs:Io:print '[WRN]' "$*"
}

# Prints an informational message with an [INF] prefix.
#
# Args:
#   msg: Informational message text to print.
# Outputs:
#   Prints the provided message to stdout with an [INF] prefix.
Mbs:Io:info() {
	Mbs:Io:print '[INF]' "$*"
}

# Prints a success message with a [SUC] prefix.
#
# Args:
#   msg: Success message text to print.
# Outputs:
#   Prints the provided message to stdout with a [SUC] prefix.
Mbs:Io:success() {
	Mbs:Io:print '[SUC]' "$*"
}

# Prints a debug message with a [DBG] prefix.
#
# Args:
#   msg: Success message text to print.
# Outputs:
#   Prints the provided message to stdout with a [DBG] prefix.
Mbs:Io:debug() {
	Mbs:Io:print '[DBG]' "$*"
}

# Prints a simple separator line.
#
# Outputs:
#   Prints a separator to stdout.
Mbs:Io:printSep() {
	Mbs:Io:print "\n-----------------------------\n"
}

# Pauses execution until the user presses a key.
#
# Outputs:
#   Prompts the user to press any key and then continues.
# Returns:
#   0 after the user presses a key.
Mbs:Io:paktc() {
	Mbs:Io:print ""
	Mbs:Io:print "Press any key to continue"
	read -n 1 -s -r
	Mbs:Io:print ""
}

Mbs:Io:confirm() {
	local default_choice text_suffix
	default_choice="$1"
	[[ $default_choice =~ ^[Yy]$ ]] && text_suffix="[Y/n]" || text_suffix="[y/N]"

	read -r -p "$2 $text_suffix " -n 1
	echo " "

	local answer
	answer="${REPLY:-$default_choice}"
	[[ $answer =~ ^[Yy]$ ]]
}

Mbs:Io:confirmDefaultNo() {
	Mbs:Io:confirm "n" "$1"
}

Mbs:Io:confirmDefaultYes() {
	Mbs:Io:confirm "y" "$1"
}
#endregion Bundler import [utils.mod/io.sh]
#region Bundler import [utils.mod/script.sh]

# Registers a trap handler for a signal.
#
# Args:
#   cmd: Command or snippet to run when the trap fires.
#   sig: Signal name or numeric value. Defaults to EXIT.
# Returns:
#   0 if the trap was registered successfully.
#   1 if the signal is invalid.
Mbs:Script:addTrap() {
	local cmd=$1         # command(s) to add
	local sig=${2:-EXIT} # signal name or number

	# validate signal name or numeric id
	local sig_name
	{
		if [[ $sig =~ ^[0-9]+$ ]]; then
			sig_name=$(kill -l "$sig")
		else
			sig_name=${sig^^}
			kill -l "$sig_name" &>/dev/null
		fi
	} || {
		echo "add_trap: invalid signal '$sig'" >&2
		return 1
	}

	# Compute effective trap list for current (sub)shell
	# Based on info from https://stackoverflow.com/a/59307894/5116073
	local old
	if [[ ${BASH_VERSINFO:-0} -ge 4 ]]; then
		trap -- KILL &>/dev/null || true
		old=$(trap -p "$sig_name")
	else
		old=$(trap -p "$sig_name")
	fi

	# extract/cleanup the existing registered command(s)
	old=${old#*\'}         # remove leading "trap -- '"
	old=${old%\'*}         # remove trailing "' EXIT"
	old=${old//"'\''"/"'"} # unescape every '\'' to '

	# if command is already registered, do nothing
	if [[ ";$old;" == *";$cmd;"* ]]; then
		return 0
	fi

	# build the new combined handler
	if [[ -n $old ]]; then
		combined="$old;$cmd"
	else
		combined="$cmd"
	fi

	# register the new combined handler
	trap -- "$combined" "$sig"
}

Mbs:Script:addTrapMultiSignal() {
	local cmd="${1:-}"
	shift || true

	# Validate that at least command and one signal are provided
	if [[ -z $cmd || $# -eq 0 ]]; then
		echo "Usage: Mbs:Script:addTrapMultiSignal <command> <signal1> [signal2 ...]" >&2
		return 1
	fi

	local sig
	for sig in "$@"; do
		Mbs:Script:addTrap "$cmd" "$sig" || return 1
	done
}

# Prints the current call stack.
#
# Outputs:
#   Prints each caller and line number to stdout.
Mbs:Script:callStack() {
	local i=1
	while caller $i; do
		((i++))
	done
}

# Check whether a given name resolves to a shell function.
#
# Args:
#   $1: Name of the function to inspect.
# Returns:
#   0 if the name resolves to a function.
#   1 otherwise.
Mbs:Script:isFunc() {
	local res
	res=$(type -t "$1" || echo "NONE")

	if [ "$res" == "function" ]; then
		return 0
	else
		return 1
	fi
}

Mbs:Script:die() {
	Mbs:Io:error "$@"
	exit 1
}
#endregion Bundler import [utils.mod/script.sh]

# Constants
readonly progress_filename="progress"
readonly bw_filename="bw.sessions"

# @cmd Create a config template.
# @arg out-file Where to write the file. Defaults to $HOME/storage/shared/_marcdata/android-init/config.env
cfg() {
	Mbs:Io:print "Generate default config file"

	local cfg_f="${argc_out_file:-$HOME/storage/shared/_marcdata/android-init/config.env}"
	if [[ -f $cfg_f ]]; then
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
# @arg cfg-file Config file location. Defaults to $HOME/storage/shared/_marcdata/android-init/config.env
# @option -d --data-dir Data dir location. Defaults to $HOME/storage/shared/_marcdata/android-init/data
run() {
	Mbs:Io:print "Android init start"

	# Source utils
	#region Bundler import [utils.mod/var.sh]

	# Checks whether a value represents a true-like boolean value.
	#
	# Args:
	#   value: The value to evaluate.
	# Returns:
	#   0 when the value is one of: 1, y, true.
	#   1 otherwise.
	Mbs:Var:isTrue() {
		local var_value
		var_value="$1"

		case "${var_value}" in
		1 | y | true)
			return 0
			;;
		*)
			return 1
			;;
		esac
	}

	# Checks whether a variable is set in the current shell.
	#
	# Args:
	#   var_name: Name of the variable to check.
	# Returns:
	#   0 if the variable exists and is defined, 1 otherwise.
	Mbs:Var:isSet() {
		[ $# -eq 0 ] && return 1
		[ -z "$1" ] && return 1
		declare -p "$1" &>/dev/null
	}

	# Checks whether a value is empty.
	#
	# Args:
	#   value: The value to check.
	# Returns:
	#   0 if the provided value is empty, 1 otherwise.
	Mbs:Var:isEmpty() {
		[ $# -eq 0 ] && return 1
		[ -z "$1" ] && return 0
		return 1
	}

	# Returns the detected type of a variable.
	#
	# Args:
	#   var_name: Name of the variable to inspect.
	# Returns:
	#   0 on success, 1 if the variable is unset.
	# Output:
	#   Prints ARRAY, HASH, INT, EXPORT, or OTHER.
	Mbs:Var:getType() {
		if ! Mbs:Var:isSet "$1"; then
			Mbs:Io:print "UNSET"
			return 1
		fi

		local var
		var=$(declare -p "$1" 2>/dev/null)
		local reg='^declare -n [^=]+=\"([^\"]+)\"$'
		while [[ $var =~ $reg ]]; do
			var=$(declare -p "${BASH_REMATCH[1]}")
		done

		case "${var#declare -}" in
		a*)
			Mbs:Io:print "ARRAY"
			;;
		A*)
			Mbs:Io:print "HASH"
			;;
		i*)
			Mbs:Io:print "INT"
			;;
		x*)
			Mbs:Io:print "EXPORT"
			;;
		*)
			Mbs:Io:print "OTHER"
			;;
		esac
		return 0
	}

	# Checks whether a variable is an array.
	#
	# Args:
	#   var_name: Name of the variable to inspect.
	# Returns:
	#   0 if the variable is an array, 1 otherwise.
	Mbs:Var:isArray() {
		Mbs:Var:getType "$1" | grep -q "ARRAY"
	}

	# Checks whether a variable is an integer.
	#
	# Args:
	#   var_name: Name of the variable to inspect.
	# Returns:
	#   0 if the variable is an integer, 1 otherwise.
	Mbs:Var:isInt() {
		Mbs:Var:getType "$1" | grep -q "INT"
	}

	# Checks whether a variable is a scalar value of another type.
	#
	# Args:
	#   var_name: Name of the variable to inspect.
	# Returns:
	#   0 if the variable is neither an array nor an integer, 1 otherwise.
	Mbs:Var:isOther() {
		Mbs:Var:getType "$1" | grep -q "OTHER"
	}

	# Imports variables from a dotenv file into the current shell.
	#
	# Args:
	#   env_file: Path to the dotenv file to import.
	# Returns:
	#   0 on success, 1 if the file does not exist.
	# Note:
	#   The imported values are sourced from a temporary cleaned file.
	Mbs:Var:importDotenv() {
		local env_file="$1" env_vars=""
		if [[ -f $env_file ]]; then
			while IFS='=' read -r key value; do
				if [[ $key == $'#'* ]] || [[ -z $key ]]; then
					continue
				fi
				if [[ -z ${!key+x} ]]; then
					env_vars="$env_vars $key=$value"
				fi
			done < <(
				cat "$env_file"
				echo ""
			)
			if [[ -n $env_vars ]]; then
				eval "export $env_vars"
			fi
		fi
	}
	#endregion Bundler import [utils.mod/var.sh]
	#region Bundler import [bw.mod/bw.sh]

	# Unlocks the Bitwarden vault and ensures a valid session is available.
	#
	# Globals:
	#   MBS__BW__HELPER_F: Path to the helper file that stores active session IDs.
	#   MBS__BW__URL: Bitwarden server URL.
	#   MBS__BW__CLIENT_ID: Bitwarden client ID.
	#   MBS__BW__CLIENT_SECRET: Bitwarden client secret.
	#   MBS__BW__MASTER_PASSWORD: Bitwarden master password.
	# Returns:
	#   0 if the vault is unlocked successfully, non-zero otherwise.
	Mbs:Bw:unlock() {
		if [ -z "${MBS__BW__HELPER_F}" ]; then
			Mbs:Io:error "Bitwarden helper file path not set, cannot proceed"
			return 1
		fi

		if [ ! -f "${MBS__BW__HELPER_F}" ]; then
			Mbs:Io:error "Bitwarden helper file path does not exist, cannot proceed"
			return 1
		fi

		if [ -z "${MBS__BW__URL:-}" ]; then
			Mbs:Io:error "Missing MBS__BW__URL config, cannot proceed"
			return 1
		fi
		if [ -z "${MBS__BW__CLIENT_ID:-}" ]; then
			Mbs:Io:error "Missing MBS__BW__CLIENT_ID config, cannot proceed"
			return 1
		fi
		if [ -z "${MBS__BW__CLIENT_SECRET:-}" ]; then
			Mbs:Io:error "Missing MBS__BW__CLIENT_SECRET config, cannot proceed"
			return 1
		fi
		if [ -z "${MBS__BW__MASTER_PASSWORD:-}" ]; then
			Mbs:Io:error "Missing MBS__BW__MASTER_PASSWORD config, cannot proceed"
			return 1
		fi

		export BW_CLIENTID="${MBS__BW__CLIENT_ID:-}"
		export BW_CLIENTSECRET="${MBS__BW__CLIENT_SECRET:-}"
		export BW_MASTER_PASSWORD="${MBS__BW__MASTER_PASSWORD:-}"

		local bw_url
		local bw_status
		local session

		bw_url=$(bw status | jq -r .serverUrl 2>/dev/null)
		if [[ $bw_url != "$MBS__BW__URL" ]]; then
			Mbs:Io:print "Configuring Bitwarden CLI to use server URL '$MBS__BW__URL'" >/dev/tty
			Mbs:Bw:lock
			bw config server "$MBS__BW__URL" >/dev/tty || IO:die "Bitwarden config failed"
		fi

		bw_status=$(bw status | jq -r .status)
		if [ -z "$bw_status" ] || [ "$bw_status" = "unauthenticated" ]; then
			Mbs:Io:print "Bitwarden: login"
			bw login --apikey || IO:die "Bitwarden login failed"
		fi

		bw_status=$(bw status | jq -r .status)
		if [ "$bw_status" = "locked" ]; then
			Mbs:Io:print "Bitwarden: unlock"
			session=$(bw unlock --passwordenv BW_MASTER_PASSWORD --raw) || IO:die "Bitwarden unlock failed"
			echo "$session" >>"$MBS__BW__HELPER_F"
			export BW_SESSION="$session"
		fi

		bw sync --force
	}

	# Locks and invalidates a specific Bitwarden session.
	#
	# Arguments:
	#   session: Session token to invalidate.
	# Returns:
	#   0 if the session is already unauthenticated or was invalidated
	#   successfully, non-zero if invalidation fails.
	Mbs:Bw:lockSession() {
		local session
		session="$1"
		local bw_status

		bw_status=$(BW_SESSION="$session" bw status | jq -r .status)
		if [ -z "$bw_status" ] || [ "$bw_status" = "unauthenticated" ]; then
			Mbs:Io:print "Bitwarden: not logged in"
			return 0
		fi

		if ! BW_SESSION="$session" bw lock; then
			Mbs:Io:error "Failed to invalidate Bitwarden session"
			return 1
		fi

		Mbs:Io:print "Bitwarden session invalidated"
		return 0
	}

	# Locks the Bitwarden vault and invalidates all stored sessions.
	#
	# Globals:
	#   MBS__BW__HELPER_F: Path to the helper file that stores active session IDs.
	# Returns:
	#   0 on success.
	Mbs:Bw:lock() {
		Mbs:Io:print "Invalidating Bitwarden sessions from helper file [$MBS__BW__HELPER_F]"
		if [ -n "${MBS__BW__HELPER_F:-}" ] && [ -f "$MBS__BW__HELPER_F" ]; then
			while IFS= read -r line; do
				Mbs:Bw:lockSession "$line"
			done <"$MBS__BW__HELPER_F"
		fi

		unset BW_SESSION
		cat /dev/null >|"$MBS__BW__HELPER_F"

		return 0
	}

	# Retrieves a value from a Bitwarden item.
	#
	# Arguments:
	#   item_name: Name of the Bitwarden item.
	#   property: Optional property to retrieve. Defaults to "item".
	# Returns:
	#   0 on success, non-zero on failure.
	Mbs:Bw:get() {
		if [ $# -lt 1 ]; then
			Mbs:Io:error "Usage: Mbs:Bw:get <item-name> [property]"
			return 2
		fi

		local item_name="$1"
		local item_field="${2:-item}"

		Mbs:Bw:unlock &>/dev/tty

		bw get "$item_field" "$item_name"
	}

	# Retrieves the value of a custom field from a Bitwarden item.
	#
	# Arguments:
	#   item_name: Name of the Bitwarden item.
	#   custom_field: Name of the custom field to retrieve.
	# Returns:
	#   0 on success, non-zero on failure.
	Mbs:Bw:getCF() {
		if [ $# -lt 2 ]; then
			Mbs:Io:error "Usage: Mbs:Bw:getCF <item-name> <field-name>"
			return 2
		fi

		local item_name="$1"
		local custom_field="$2"

		Mbs:Bw:get "$item_name" | jq -r ".fields[] | select(.name==\"$custom_field\") | .value"
	}
	#endregion Bundler import [bw.mod/bw.sh]

	local data_dir="${argc_data_dir:-$HOME/storage/shared/_marcdata/android-init/data}"
	local helper_f="$data_dir/${progress_filename}"
	export MBS__BW__HELPER_F="$data_dir/${bw_filename}"

	ai_modules_d="$_this_dir/android-init.mod"

	# Create helper files if not found
	mkdir -p "$data_dir"
	if [ ! -f "$helper_f" ]; then
		echo "0" | tee "$helper_f" >/dev/null
	fi

	if [ ! -f "$MBS__BW__HELPER_F" ]; then
		touch "$MBS__BW__HELPER_F" >/dev/null
	fi

	local cfg_file
	cfg_file="${argc_cfg_file:-$HOME/storage/shared/_marcdata/android-init/config.env}"
	Mbs:Var:importDotenv "$cfg_file"

	Mbs:Script:addTrapMultiSignal "Mbs:Bw:lock" INT TERM EXIT

	home_user_d="$HOME"

	helper_f_content=$(<"$helper_f")

	if [[ $helper_f_content == "1" ]]; then
		Mbs:Io:print "All config already done, exiting."
	elif [[ $helper_f_content == "0" ]]; then
		_run_step_0
	fi

	exit 0
}

function _run_step_0() {
	Mbs:Io:print "First init pass"

	# pkg - update
	Mbs:Io:printSep
	Mbs:Io:print "Updating packages"
	pkg update -y
	pkg upgrade -y
	echo "Packages updated"

	# PKG - install packages
	if Mbs:Var:isTrue "$MBS__AI__PKG_INSTALL_PACKAGES__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [android-init.mod/s0.pkg-install-pkgs.sh]

		Mbs:AndroidInit:installPkgPackages() {
			declare -a config_pkgs_arr
			Mbs:Io:print "Installing new packages"

			readarray -td, config_pkgs_arr <<<"$MBS__AI__PKG_INSTALL_PACKAGES__PACKAGES,"
			unset 'config_pkgs_arr[-1]'

			Mbs:Io:print "New packages to install: ${config_pkgs_arr[*]}"
			pkg install -y "${config_pkgs_arr[@]}"
			return 0
		}
		#endregion Bundler import [android-init.mod/s0.pkg-install-pkgs.sh]
		Mbs:AndroidInit:installPkgPackages || Mbs:Script:die "Failed to install PKG packages"
	fi

	# SSH - prepare
	Mbs:Io:printSep
	#region Bundler import [android-init.mod/s0.ssh-prepare.sh]

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
	#endregion Bundler import [android-init.mod/s0.ssh-prepare.sh]
	Mbs:AndroidInit:prepareSSH || Mbs:Script:die "Failed to prepare SSH"

	# Git - config
	if Mbs:Var:isTrue "$MBS__AI__GIT_CONFIG__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [android-init.mod/s0.git-config.sh]

		# FIXME: Merge with linux-init.sh

		Mbs:AndroidInit:configGit() {
			Mbs:Io:print "Configuring basic Git settings"

			git config --global user.name "$MBS__AI__GIT_CONFIG__USERNAME"
			git config --global user.email "$MBS__AI__GIT_CONFIG__EMAIL"
			return 0
		}
		#endregion Bundler import [android-init.mod/s0.git-config.sh]
		Mbs:AndroidInit:configGit || Mbs:Script:die "Failed to configure Git"
	fi

	# Pass 0 done
	echo "1" | tee "$helper_f" >/dev/null
	Mbs:Io:printSep
	Mbs:Io:success "First part of the config done"
	Mbs:Io:print ""
	Mbs:Io:print "Please check sshd config using 'sudo sshd -t' command and fix any problem before rebooting"
	Mbs:Io:print "If the command sudo sshd -t has no output the config is ok"
	Mbs:Io:print ""
	Mbs:Io:print "Reboot to finalize the configuration"
}

# ARGC-BUILD {
# This block was generated by argc (https://github.com/sigoden/argc).
# Modifying it manually is not recommended

_argc_run() {
	if [[ ${1:-} == "___internal___" ]]; then
		_argc_die "error: unsupported ___internal___ command"
	fi
	if [[ ${OS:-} == "Windows_NT" ]] && [[ -n ${MSYSTEM:-} ]]; then
		set -o igncr
	fi
	argc__args=("$(basename "$0" .sh)" "$@")
	argc__positionals=()
	_argc_index=1
	_argc_len="${#argc__args[@]}"
	_argc_required_flag_options=()
	_argc_required_envs=()
	_argc_tools=()
	_argc_parse
	_argc_require_tools "${_argc_tools[@]}"
	if [ -n "${argc__fn:-}" ]; then
		$argc__fn "${argc__positionals[@]}"
	fi
}

_argc_usage() {
	cat <<-'EOF'
		Init a new Android machine.

		USAGE: android-init.sh.tmp.out <COMMAND>

		COMMANDS:
		  cfg  Create a config template.
		  run  run Load config and init the machine.
	EOF
	exit
}

_argc_version() {
	echo android-init.sh.tmp.out 0.0.1
	exit
}

_argc_parse() {
	local _argc_key _argc_action
	local _argc_subcmds="cfg, run"
	while [[ $_argc_index -lt $_argc_len ]]; do
		_argc_item="${argc__args[_argc_index]}"
		_argc_key="${_argc_item%%=*}"
		case "$_argc_key" in
		--help | -help | -h)
			_argc_usage
			;;
		--version | -version | -V)
			_argc_version
			;;
		--)
			_argc_dash="${#argc__positionals[@]}"
			argc__positionals+=("${argc__args[@]:$((_argc_index + 1))}")
			_argc_index=$_argc_len
			break
			;;
		cfg)
			_argc_index=$((_argc_index + 1))
			_argc_action=_argc_parse_cfg
			break
			;;
		run)
			_argc_index=$((_argc_index + 1))
			_argc_action=_argc_parse_run
			break
			;;
		help)
			local help_arg="${argc__args[$((_argc_index + 1))]:-}"
			case "$help_arg" in
			cfg)
				_argc_usage_cfg
				;;
			run)
				_argc_usage_run
				;;
			"")
				_argc_usage
				;;
			*)
				_argc_die "error: invalid value \`$help_arg\` for \`<command>\`"$'\n'"  [possible values: $_argc_subcmds]"
				;;
			esac
			;;
		*)
			_argc_die 'error: `android-init.sh.tmp.out` requires a subcommand but one was not provided'$'\n'"  [subcommands: $_argc_subcmds]"
			;;
		esac
	done
	_argc_tools=(bw)
	if [[ -n ${_argc_action:-} ]]; then
		$_argc_action
	else
		_argc_usage
	fi
}

_argc_usage_cfg() {
	cat <<-'EOF'
		Create a config template.

		USAGE: android-init.sh.tmp.out cfg [OUT-FILE]

		ARGS:
		  [OUT-FILE]  Where to write the file. Defaults to $HOME/storage/shared/_marcdata/android-init/config.env
	EOF
	exit
}

_argc_parse_cfg() {
	local _argc_key _argc_action
	local _argc_subcmds=""
	while [[ $_argc_index -lt $_argc_len ]]; do
		_argc_item="${argc__args[_argc_index]}"
		_argc_key="${_argc_item%%=*}"
		case "$_argc_key" in
		--help | -help | -h)
			_argc_usage_cfg
			;;
		--)
			_argc_dash="${#argc__positionals[@]}"
			argc__positionals+=("${argc__args[@]:$((_argc_index + 1))}")
			_argc_index=$_argc_len
			break
			;;
		*)
			argc__positionals+=("$_argc_item")
			_argc_index=$((_argc_index + 1))
			;;
		esac
	done
	_argc_tools=(bw)
	if [[ -n ${_argc_action:-} ]]; then
		$_argc_action
	else
		argc__fn=cfg
		if [[ ${argc__positionals[0]:-} == "help" ]] && [[ ${#argc__positionals[@]} -eq 1 ]]; then
			_argc_usage_cfg
		fi
		_argc_match_positionals 0
		local values_index values_size
		IFS=: read -r values_index values_size <<<"${_argc_match_positionals_values[0]:-}"
		if [[ -n $values_index ]]; then
			argc_out_file="${argc__positionals[values_index]}"
		fi
	fi
}

_argc_usage_run() {
	cat <<-'EOF'
		run Load config and init the machine.

		USAGE: android-init.sh.tmp.out run [OPTIONS] [CFG-FILE]

		ARGS:
		  [CFG-FILE]  Config file location. Defaults to $HOME/storage/shared/_marcdata/android-init/config.env

		OPTIONS:
		  -d, --data-dir <DATA-DIR>  Data dir location. Defaults to $HOME/storage/shared/_marcdata/android-init/data
		  -h, --help                 Print help
	EOF
	exit
}

_argc_parse_run() {
	local _argc_key _argc_action
	local _argc_subcmds=""
	while [[ $_argc_index -lt $_argc_len ]]; do
		_argc_item="${argc__args[_argc_index]}"
		_argc_key="${_argc_item%%=*}"
		case "$_argc_key" in
		--help | -help | -h)
			_argc_usage_run
			;;
		--)
			_argc_dash="${#argc__positionals[@]}"
			argc__positionals+=("${argc__args[@]:$((_argc_index + 1))}")
			_argc_index=$_argc_len
			break
			;;
		--data-dir | -d)
			_argc_take_args "--data-dir <DATA-DIR>" 1 1 "-" ""
			_argc_index=$((_argc_index + _argc_take_args_len + 1))
			if [[ -z ${argc_data_dir:-} ]]; then
				argc_data_dir="${_argc_take_args_values[0]:-}"
			else
				_argc_die 'error: the argument `--data-dir` cannot be used multiple times'
			fi
			;;
		*)
			if _argc_maybe_flag_option "-" "$_argc_item"; then
				_argc_die "error: unexpected argument \`$_argc_key\` found"
			fi
			argc__positionals+=("$_argc_item")
			_argc_index=$((_argc_index + 1))
			;;
		esac
	done
	_argc_tools=(bw)
	if [[ -n ${_argc_action:-} ]]; then
		$_argc_action
	else
		argc__fn=run
		if [[ ${argc__positionals[0]:-} == "help" ]] && [[ ${#argc__positionals[@]} -eq 1 ]]; then
			_argc_usage_run
		fi
		_argc_match_positionals 0
		local values_index values_size
		IFS=: read -r values_index values_size <<<"${_argc_match_positionals_values[0]:-}"
		if [[ -n $values_index ]]; then
			argc_cfg_file="${argc__positionals[values_index]}"
		fi
	fi
}

_argc_take_args() {
	_argc_take_args_values=()
	_argc_take_args_len=0
	local param="$1" min="$2" max="$3" signs="$4" delimiter="$5"
	if [[ $min -eq 0 ]] && [[ $max -eq 0 ]]; then
		return
	fi
	local _argc_take_index=$((_argc_index + 1)) _argc_take_value
	if [[ $_argc_item == *=* ]]; then
		_argc_take_args_values=("${_argc_item##*=}")
	else
		while [[ $_argc_take_index -lt $_argc_len ]]; do
			_argc_take_value="${argc__args[_argc_take_index]}"
			if _argc_maybe_flag_option "$signs" "$_argc_take_value"; then
				if [[ ${#_argc_take_value} -gt 1 ]]; then
					break
				fi
			fi
			_argc_take_args_values+=("$_argc_take_value")
			_argc_take_args_len=$((_argc_take_args_len + 1))
			if [[ $_argc_take_args_len -ge $max ]]; then
				break
			fi
			_argc_take_index=$((_argc_take_index + 1))
		done
	fi
	if [[ ${#_argc_take_args_values[@]} -lt $min ]]; then
		_argc_die "error: incorrect number of values for \`$param\`"
	fi
	if [[ -n $delimiter ]] && [[ ${#_argc_take_args_values[@]} -gt 0 ]]; then
		local item values arr=()
		for item in "${_argc_take_args_values[@]}"; do
			IFS="$delimiter" read -r -a values <<<"$item"
			arr+=("${values[@]}")
		done
		_argc_take_args_values=("${arr[@]}")
	fi
}

_argc_match_positionals() {
	_argc_match_positionals_values=()
	_argc_match_positionals_len=0
	local params=("$@")
	local args_len="${#argc__positionals[@]}"
	if [[ $args_len -eq 0 ]]; then
		return
	fi
	local params_len=$# arg_index=0 param_index=0
	while [[ $param_index -lt $params_len && $arg_index -lt $args_len ]]; do
		local takes=0
		if [[ ${params[param_index]} -eq 1 ]]; then
			if [[ $param_index -eq 0 ]] \
				&& [[ ${_argc_dash:-} -gt 0 ]] \
				&& [[ $params_len -eq 2 ]] \
				&& [[ ${params[$((param_index + 1))]} -eq 1 ]] \
				; then
				takes=${_argc_dash:-}
			else
				local arg_diff=$((args_len - arg_index)) param_diff=$((params_len - param_index))
				if [[ $arg_diff -gt $param_diff ]]; then
					takes=$((arg_diff - param_diff + 1))
				else
					takes=1
				fi
			fi
		else
			takes=1
		fi
		_argc_match_positionals_values+=("$arg_index:$takes")
		arg_index=$((arg_index + takes))
		param_index=$((param_index + 1))
	done
	if [[ $arg_index -lt $args_len ]]; then
		_argc_match_positionals_values+=("$arg_index:$((args_len - arg_index))")
	fi
	_argc_match_positionals_len=${#_argc_match_positionals_values[@]}
	if [[ $params_len -gt 0 ]] && [[ $_argc_match_positionals_len -gt $params_len ]]; then
		local index="${_argc_match_positionals_values[params_len]%%:*}"
		_argc_die "error: unexpected argument \`${argc__positionals[index]}\` found"
	fi
}

_argc_maybe_flag_option() {
	local signs="$1" arg="$2"
	if [[ -z $signs ]]; then
		return 1
	fi
	local cond=false
	if [[ $signs == *"+"* ]]; then
		if [[ $arg =~ ^\+[^+].* ]]; then
			cond=true
		fi
	elif [[ $arg == -* ]]; then
		if ((${#arg} < 3)) || [[ ! $arg =~ ^---.* ]]; then
			cond=true
		fi
	fi
	if [[ $cond == "false" ]]; then
		return 1
	fi
	local value="${arg%%=*}"
	if [[ $value =~ [[:space:]] ]]; then
		return 1
	fi
	return 0
}

_argc_require_tools() {
	local tool missing_tools=()
	for tool in "$@"; do
		if ! command -v "$tool" >/dev/null 2>&1; then
			missing_tools+=("$tool")
		fi
	done
	if [[ ${#missing_tools[@]} -gt 0 ]]; then
		echo "error: missing tools: ${missing_tools[*]}" >&2
		exit 1
	fi
}

_argc_die() {
	if [[ $# -eq 0 ]]; then
		cat
	else
		echo "$*" >&2
	fi
	exit 1
}

_argc_run "$@"

# ARGC-BUILD }
