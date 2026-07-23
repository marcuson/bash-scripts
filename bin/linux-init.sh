#!/usr/bin/env bash

# @describe Init a new Linux machine.
# @meta version 0.0.1
# @meta require-tools sudo

#region Meta moved
# @meta require-tools bw
# @meta require-tools curl
# @meta require-tools docker
#endregion Meta moved

set -euo pipefail

_this_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# File included (base64) [linux-init.mod/linux-init.tpl.env]
cfg_tpl_content="IyBDb25maWd1cmFibGUgdmFyaWFibGVzCgojIC0tIEdlbmVyYWwKIyAtLS0tIFVzZXIgLSB0aGUgbm9uIHJvb3QgY29uZmlndXJlZCB1c2VyCkxJX19VU0VSPXh4eAojIC0tLS0gSW5zdGFsbGF0aW9uIHR5cGUgLSBzZXJ2ZXIgb3IgZGVza3RvcApMSV9fSU5TVEFMTEFUSU9OX1RZUEU9c2VydmVyCiMgLS0tLSBCaXR3YXJkZW4gaW50ZWdyYXRpb24KTUJTX19CV19fVVJMPXh4eApNQlNfX0JXX19DTElFTlRfSUQ9eHh4Ck1CU19fQldfX0NMSUVOVF9TRUNSRVQ9eHh4Ck1CU19fQldfX01BU1RFUl9QQVNTV09SRD14eHgKCiMgLS0gU3RlcCAwCiMgLS0tLSBBUFQgLSBBZGQgRG9ja2VyIHJlcG8KTElfX0FERF9ET0NLRVJfQVBUX1JFUE9fX0lTX0VOQUJMRUQ9eQojIC0tLS0gQVBUIC0gaW5zdGFsbCBwYWNrYWdlcwpMSV9fQVBUX0lOU1RBTExfUEFDS0FHRVNfX0lTX0VOQUJMRUQ9eQpMSV9fQVBUX0lOU1RBTExfUEFDS0FHRVNfX1BBQ0tBR0VTPSJjYS1jZXJ0aWZpY2F0ZXMsY3VybCxodG9wLGdpdCx1bnppcCxkb2NrZXItY2UsZG9ja2VyLWNlLWNsaSxjb250YWluZXJkLmlvLGRvY2tlci1idWlsZHgtcGx1Z2luLGRvY2tlci1jb21wb3NlLXBsdWdpbiIKIyAtLS0tIFNlcnZpY2VzIC0gZG9ja2VyCkxJX19TUlZfRE9DS0VSX0VOQUJMRVJfX0lTX0VOQUJMRUQ9eQojIC0tLS0gR2l0IC0gYmFzaWMgY29uZmlnCkxJX19HSVRfQ09ORklHX19JU19FTkFCTEVEPXkKTElfX0dJVF9DT05GSUdfX1VTRVJOQU1FPSJGaXJzdE5hbWUgTGFzdE5hbWUiCkxJX19HSVRfQ09ORklHX19FTUFJTD0ieHh4QHh4eC5jb20iCiMgLS0tLSBKb3VybmFsIC0gbGltaXQgc2l6ZQpMSV9fSk9VUk5BTF9MSU1JVF9fSVNfRU5BQkxFRD15CkxJX19KT1VSTkFMX0xJTUlUX19TWVNURU1fTUFYPSIxMDI0TSIKTElfX0pPVVJOQUxfTElNSVRfX0ZJTEVfTUFYPSIxMDBNIgojIC0tLS0gTmFubyAtIGVuYWJsZSBzeW50YXggaGlnaGxpZ2h0aW5nCkxJX19OQU5PX1NZTlRBWF9ISUdITElHSFRJTkdfX0lTX0VOQUJMRUQ9eQojIC0tLS0gTmV0d29yayAtIGVuYWJsZSByb3V0aW5nCkxJX19ORVRXT1JLX1JPVVRJTkdfX0lTX0VOQUJMRUQ9eQojIC0tLS0gTmV0d29yayAtIGVuYWJsZSBzcmMgdmFsaWQgbWFyawpMSV9fTkVUV09SS19TUkNfVkFMSURfTUFSS19fSVNfRU5BQkxFRD15CiMgLS0tLSBTU0ggLSBwcmVwYXJlCiMgTk9URTogTm8gY29uZmlnIGZvciBub3cKIyAtLS0tIFJBTSAtIHNldCBzd2FwcGluZXNzCkxJX19SQU1fU1dBUFBJTkVTU19fSVNfRU5BQkxFRD15CkxJX19SQU1fU1dBUFBJTkVTU19fVkFMVUU9IjEwIgojIC0tLS0gVXNlciAtIGFkZCB0byBncm91cHMKTElfX1VTRVJfQUREX1RPX0dST1VQU19fSVNfRU5BQkxFRD15CkxJX19VU0VSX0FERF9UT19HUk9VUFNfX0dST1VQUz0iZG9ja2VyLHR0eSx1dWNwLGxwIgojIC0tLS0gVXNlciAtIHN1ZG8gd2l0aG91dCBwYXNzd29yZApMSV9fUEFTU1dPUkRMRVNTX1NVRE9fX0lTX0VOQUJMRUQ9eQojIC0tLS0gSW5zdGFsbCBTT1BTCkxJX19JTlNUQUxMX1NPUFNfX0lTX0VOQUJMRUQ9eQojIC0tLS0gSW5zdGFsbCBvaC1teS1wb3NoCkxJX19JTlNUQUxMX09IX01ZX1BPU0hfX0lTX0VOQUJMRUQ9eQojIC0tLS0gS29tb2RvIHByZXAKTElfX0tPTU9ET19QUkVQX19JU19FTkFCTEVEPXkKTElfX0tPTU9ET19QUkVQX19TT1BTX0tFWT14eHgKCiMgLS0gU3RlcCAxCiMgLS0tLSBEb2NrZXIgLSBsb2dpbgpMSV9fRE9DS0VSX0xPR0lOX19JU19FTkFCTEVEPXkKTElfX0RPQ0tFUl9MT0dJTl9fVVNFUk5BTUU9Inh4eCIKIyAtLS0tIERvY2tlciAtIGN1c3RvbSBicmlkZ2UgbmV0d29yawpMSV9fRE9DS0VSX05FVFdPUktfQ1VTVE9NX0JSSURHRV9fSVNfRU5BQkxFRD15CkxJX19ET0NLRVJfTkVUV09SS19DVVNUT01fQlJJREdFX19OQU1FPSJkb2NrZXJuZXRfYnJpZGdlIgojIC0tLS0gRG9ja2VyIC0gc3RhcnQgY29tcG9zZQpMSV9fRE9DS0VSX0NPTVBPU0VfU1RBUlRfX0lTX0VOQUJMRUQ9bgpMSV9fRE9DS0VSX0NPTVBPU0VfU1RBUlRfX0ZJTEVfUEFUSD0iL2Fic29sdXRlL3BhdGgvdG8vZG9ja2VyLWNvbXBvc2UueW1sIgojIC0tLS0gQmFja3VwIC0gcmVzdG9yZQpMSV9fQkFDS1VQX1JFU1RPUkVfX0lTX0VOQUJMRUQ9bgpMSV9fQkFDS1VQX1JFU1RPUkVfX0ZJTEVfUEFUSD0iL2Fic29sdXRlL3BhdGgvdG8vYmFja3VwLnRhci5neiIK"

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

	# FIXME: Unregister traps
	exit 1
}
#endregion Bundler import [utils.mod/script.sh]

# Constants
readonly progress_filename="progress"
readonly bw_filename="bw.sessions"

# @cmd Create a config template.
# @arg out-file Where to write the file. Defaults to /etc/linux-init/config.env
cfg() {
	Mbs:Io:print "Generate default config file"

	local cfg_f="${argc_out_file:-/etc/linux-init/config.env}"
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
# @arg cfg-file Config file location. Defaults to /etc/linux-init/config.env
# @option -d --data-dir Data dir location. Defaults to /etc/linux-init/data
run() {
	Mbs:Io:print "Linux init start"

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
	#region Bundler import [utils.mod/user.sh]

	# Check whether the current process is running as root.
	#
	# Returns:
	#   0 if the current user is root.
	#   1 otherwise.
	Mbs:User:isCurrentRunningAsRoot() {
		if [ ! "${EUID:-$(id -u)}" -eq 0 ]; then
			return 1
		fi
		return 0
	}

	# Check whether a supplied username is a normal non-root user.
	#
	# Args:
	#   $1: Username to inspect.
	# Returns:
	#   0 if the user exists and is not root.
	#   1 otherwise.
	Mbs:User:isNormal() {
		[ $# -eq 0 ] && return 1
		Mbs:Var:isEmpty "$1" && return 1
		! id "$1" &>/dev/null && return 1
		[ "$1" = "root" ] && return 1
		return 0
	}

	# Check whether the current user belongs to a group.
	#
	# Args:
	#   $1: Name of the group to check.
	# Returns:
	#   0 if the current user is in the group.
	#   1 otherwise.
	Mbs:User:isCurrentInGroup() {
		[ $# -eq 0 ] && return 1
		Mbs:Var:isEmpty "$1" && return 1
		groups 2>/dev/null | grep -q "\b$1\b"
	}

	# Check whether a given user belongs to a group.
	#
	# Args:
	#   $1: Username to inspect.
	#   $2: Name of the group to check.
	# Returns:
	#   0 if the user is in the group.
	#   1 otherwise.
	Mbs:User:isUserInGroup() {
		[ $# -lt 2 ] && return 1
		Mbs:Var:isEmpty "$1" && return 1
		Mbs:Var:isEmpty "$2" && return 1
		groups "$1" 2>/dev/null | grep -q "\b$2\b"
	}
	#endregion Bundler import [utils.mod/user.sh]
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

	if [[ $helper_f_content == "2" ]]; then
		Mbs:Io:print "All config already done, exiting."
	elif [[ $helper_f_content == "0" ]]; then
		_run_step_0
	elif [[ $helper_f_content == "1" ]]; then
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
		#region Bundler import [linux-init.mod/s0.journal-limit.sh]

		Mbs:LinuxInit:limitJournal() {
			# Defaults
			local config_journal_system_max_default="1024M"
			local config_journal_file_max_default="100M"
			# Dirs
			local journal_conf_d="/etc/systemd/journald.conf.d"
			local journal_conf_f="${journal_conf_d}/size.conf"

			# Apply default if conf is not found
			local system_max="${LI__JOURNAL_LIMIT__SYSTEM_MAX:=$config_journal_system_max_default}"
			local file_max="${LI__JOURNAL_LIMIT__FILE_MAX:=$config_journal_file_max_default}"

			Mbs:Io:print "Limit journal size"
			mkdir -p "$journal_conf_d"
			Mbs:Io:print "Using SystemMaxUse=$system_max | SystemMaxFileSize=$file_max"
			echo -e "[Journal]\nSystemMaxUse=$system_max\nSystemMaxFileSize=$file_max" | tee "$journal_conf_f" >/dev/null
			Mbs:Io:print "New conf file is located at $journal_conf_f"
			Mbs:Io:print "Journal size limited"
			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.journal-limit.sh]
		Mbs:LinuxInit:limitJournal || Mbs:Script:die "Failed to limit journal size"
	fi

	# RAM - set swappiness
	if Mbs:Var:isTrue "$LI__RAM_SWAPPINESS__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.swappiness.sh]

		Mbs:LinuxInit:setSwappiness() {
			# Defaults
			local swappiness_default=60
			# Dirs
			local swappiness_conf_f="/etc/sysctl.d/swappiness.conf"
			# Apply default if conf is not found
			local swappiness="${LI__RAM_SWAPPINESS__VALUE:=$swappiness_default}"

			Mbs:Io:print "Setting custom swappiness"
			Mbs:Io:print "New swappiness value: $swappiness"
			echo "vm.swappiness=$swappiness" | tee "$swappiness_conf_f" >/dev/null
			Mbs:Io:print "Custom swappiness set, it will be applied from the next reboot"
			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.swappiness.sh]
		Mbs:LinuxInit:setSwappiness || Mbs:Script:die "Failed to set swappiness"
	fi

	# APT - add Docker repo
	if Mbs:Var:isTrue "$LI__ADD_DOCKER_APT_REPO__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.apt-add-docker-repo.sh]

		Mbs:LinuxInit:aptAddDockerRepo() {
			Mbs:Io:print "Add Docker repo to APT"

			local docker_gpg_f="/etc/apt/keyrings/docker.asc"
			local docker_list_f="/etc/apt/sources.list.d/docker.list"

			# Add Docker's official GPG key
			if [ ! -f "$docker_gpg_f" ]; then
				apt update
				apt install ca-certificates curl
				install -m 0755 -d /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "${docker_gpg_f}"
				chmod a+r "${docker_gpg_f}"
			else
				Mbs:Io:print "Docker repo GPG key already added"
			fi

			# Add the repository to Apt sources
			if [ ! -f "$docker_list_f" ]; then
				echo \
					"deb [arch=$(dpkg --print-architecture) signed-by=$docker_gpg_f] \
        https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
					| tee "${docker_list_f}" >/dev/null
				apt update
			else
				Mbs:Io:print "Docker repo already added"
			fi

			Mbs:Io:print "Docker APT repo added and configured"
			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.apt-add-docker-repo.sh]
		Mbs:LinuxInit:aptAddDockerRepo || Mbs:Script:die "Failed to add Docker APT repo"
	fi

	# APT - install packages
	if Mbs:Var:isTrue "$LI__APT_INSTALL_PACKAGES__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.apt-install-pkgs.sh]

		Mbs:LinuxInit:installAptPackages() {
			declare -a config_pkgs_arr
			Mbs:Io:print "Installing new packages"

			if Mbs:Var:isEmpty "$LI__APT_INSTALL_PACKAGES__PACKAGES"; then
				Mbs:Io:print "LI__APT_INSTALL_PACKAGES__PACKAGES unset or empty"
				Mbs:Io:print "Please input one or more space separated APT packages to install, then press enter to confirm:"
				read -r -a config_pkgs_arr
				Mbs:Io:print ""
			else
				readarray -td, config_pkgs_arr <<<"$LI__APT_INSTALL_PACKAGES__PACKAGES,"
				unset 'config_pkgs_arr[-1]'
			fi

			Mbs:Io:print "New packages to install: ${config_pkgs_arr[*]}"
			apt -y install "${config_pkgs_arr[@]}"
			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.apt-install-pkgs.sh]
		Mbs:LinuxInit:installAptPackages || Mbs:Script:die "Failed to install APT packages"
	fi

	# User - add to groups
	if Mbs:Var:isTrue "$LI__USER_ADD_TO_GROUPS__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.user-groups.sh]

		Mbs:LinuxInit:addUserToGroups() {
			Mbs:Io:print "Adding user to groups"

			Mbs:Var:isSet "LI__USER" || return 1
			Mbs:Var:isSet "LI__USER_ADD_TO_GROUPS__GROUPS" || return 1

			Mbs:Io:print "Adding $LI__USER to $LI__USER_ADD_TO_GROUPS__GROUPS groups"
			usermod -aG "$LI__USER_ADD_TO_GROUPS__GROUPS" "$LI__USER"
			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.user-groups.sh]
		Mbs:LinuxInit:addUserToGroups || Mbs:Script:die "Failed to add user to groups"
	fi

	# User - sudo without password
	if Mbs:Var:isTrue "$LI__PASSWORDLESS_SUDO__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.user-passwordless-sudo.sh]

		Mbs:LinuxInit:enablePasswordlessSudo() {
			Mbs:Io:print "Setting sudo without password"

			if Mbs:Var:isEmpty "$LI__USER"; then
				Mbs:Io:print "Missing LI__USER, please enter the normal user name and press enter: "
				read -r
				LI__USER="$REPLY"
			fi

			if ! Mbs:User:isNormal "$LI__USER"; then
				Mbs:Io:error "LI__USER problem, it must be set, it must be a normal user, it must exists"
				return 1
			fi

			Mbs:Io:print "New super-uber-user: $LI__USER"

			local sudoers_f="/etc/sudoers.d/99-$LI__USER"

			if [ -f "$sudoers_f" ]; then
				Mbs:Io:print "$sudoers_f file already exists, please check"
				return 0
			fi

			echo "$LI__USER ALL=(ALL) NOPASSWD: ALL" | tee "$sudoers_f" >/dev/null
			chmod 750 "$sudoers_f"
			Mbs:Io:print "$LI__USER can run sudo without password from the next boot."
			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.user-passwordless-sudo.sh]
		Mbs:LinuxInit:enablePasswordlessSudo || Mbs:Script:die "Failed to enable passwordless sudo"
	fi

	# Nano - enable syntax highlighting
	if Mbs:Var:isTrue "$LI__NANO_SYNTAX_HIGHLIGHTING__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.nano-syntax-highlighting.sh]

		Mbs:LinuxInit:enableNanoSyntaxHighlighting() {
			Mbs:Io:print "Enabling Nano Syntax highlighting"

			if ! Mbs:User:isNormal "$LI__USER"; then
				Mbs:Script:die "\nLI__USER problem, it must be set, it must be a normal user, it must exists"
			fi

			if Mbs:Var:isEmpty "$home_user_d"; then
				home_user_d=$(sudo -u "$LI__USER" sh -c 'echo $HOME')
			fi

			home_root_d=$(sudo -u root sh -c 'echo $HOME')

			local nano_conf_f=".nanorc"
			local nano_conf_user_f="$home_user_d/$nano_conf_f"
			local nano_conf_root_f="$home_root_d/$nano_conf_f"

			if [ ! -f "$nano_conf_root_f" ] || ! grep -q 'include "/usr/share/nano/\*.nanorc' "$nano_conf_root_f"; then
				echo -e 'include "/usr/share/nano/*.nanorc"\nset linenumbers' | tee -a "$nano_conf_root_f" >/dev/null
			else
				Mbs:Io:print "$nano_conf_root_f already configured"
			fi

			if [ ! -f "$nano_conf_user_f" ] || ! grep -q 'include "/usr/share/nano/\*.nanorc' "$nano_conf_user_f"; then
				echo -e 'include "/usr/share/nano/*.nanorc"\nset linenumbers' | sudo -u "$LI__USER" tee -a "$nano_conf_user_f" >/dev/null
			else
				Mbs:Io:print "$nano_conf_user_f already configured"
			fi
			Mbs:Io:print "Nano Syntax highlighting enabled"
			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.nano-syntax-highlighting.sh]
		Mbs:LinuxInit:enableNanoSyntaxHighlighting || Mbs:Script:die "Failed to enable nano syntax highlighting"
	fi

	# Network - enable routing
	if Mbs:Var:isTrue "$LI__NETWORK_ROUTING__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.network-routing.sh]

		Mbs:LinuxInit:enableRouting() {
			local systctld_network_conf_f="/etc/sysctl.d/21-network_routing.conf"
			Mbs:Io:print "Adding network confs to $systctld_network_conf_f"
			echo "net.ipv4.ip_forward = 1" | tee "$systctld_network_conf_f" >/dev/null
			Mbs:Io:print "Routing enabled"
			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.network-routing.sh]
		Mbs:LinuxInit:enableRouting || Mbs:Script:die "Failed to enable network routing"
	fi

	# Network - enable src valid mark
	if Mbs:Var:isTrue "$LI__NETWORK_SRC_VALID_MARK__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.network-src-valid-mark.sh]

		Mbs:LinuxInit:enableNetSrcValidMark() {
			local systctld_network_conf_f="/etc/sysctl.d/22-network_src_valid_mark.conf"
			Mbs:Io:print "\n\nAdding network confs to $systctld_network_conf_f"
			echo "net.ipv4.conf.all.src_valid_mark = 1" | tee "$systctld_network_conf_f" >/dev/null
			Mbs:Io:print "Network src valid mark enabled"
			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.network-src-valid-mark.sh]
		Mbs:LinuxInit:enableNetSrcValidMark || Mbs:Script:die "Failed to enable network src valid mark"
	fi

	# SSH - prepare
	Mbs:Io:printSep
	#region Bundler import [linux-init.mod/s0.ssh-prepare.sh]

	Mbs:LinuxInit:prepareSSH() {
		Mbs:Io:print "Adding .ssh folders and basic files"

		if Mbs:Var:isEmpty "$LI__USER"; then
			Mbs:Io:print "Missing LI__USER, please enter the normal user name and press enter\n"
			read -r
			LI__USER="$REPLY"
		fi

		if ! Mbs:User:isNormal "$LI__USER"; then
			Mbs:Io:error "LI__USER problem, it must be set, it must be a normal user, it must exists"
			return 1
		fi

		if Mbs:Var:isEmpty "$home_user_d"; then
			home_user_d=$(sudo -u "$LI__USER" sh -c 'echo $HOME')
		fi

		local ssh_user_d="$home_user_d/.ssh"
		export ssh_auth_keys_user_f="$ssh_user_d/authorized_keys"
		export ssh_known_hosts_user_f="$ssh_user_d/known_hosts"

		sudo -u "$LI__USER" mkdir -p "$ssh_user_d"
		sudo -u "$LI__USER" touch "$ssh_auth_keys_user_f" "$ssh_known_hosts_user_f"
		chmod 700 "$ssh_user_d"
		chmod 600 "$ssh_auth_keys_user_f" "$ssh_known_hosts_user_f"
		Mbs:Io:print ".ssh folders and basic files added"
		return 0
	}
	#endregion Bundler import [linux-init.mod/s0.ssh-prepare.sh]
	Mbs:LinuxInit:prepareSSH || Mbs:Script:die "Failed to prepare SSH"

	# Services - docker
	if Mbs:Var:isTrue "$LI__SRV_DOCKER_ENABLER__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.docker-service-enabler.sh]

		Mbs:LinuxInit:enableDockerService() {
			Mbs:Io:print "Enabling Docker services"

			if ! Mbs:LinuxInit:enableService "docker.service" false; then
				Mbs:Io:error "Failed to enable docker service"
				return 1
			fi

			if ! Mbs:Os:enableService "containerd.service" false; then
				Mbs:Io:error "Failed to enable containerd service"
				return 1
			fi

			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.docker-service-enabler.sh]
		Mbs:LinuxInit:enableDockerService || Mbs:Script:die "Failed to enable Docker services"
	fi

	# Git - config
	if Mbs:Var:isTrue "$LI__GIT_CONFIG__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.git-config.sh]

		Mbs:LinuxInit:configGit() {
			Mbs:Io:print "Configuring basic Git settings"

			if ! Mbs:User:isNormal "$LI__USER"; then
				Mbs:Script:die "LI__USER problem, it must be set, it must be a normal user, it must exists"
			fi

			sudo -u "$LI__USER" sh -c "git config --global user.name \"$LI__GIT_CONFIG__USERNAME\""
			sudo -u "$LI__USER" sh -c "git config --global user.email \"$LI__GIT_CONFIG__EMAIL\""
			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.git-config.sh]
		Mbs:LinuxInit:configGit || Mbs:Script:die "Failed to configure Git"
	fi

	# Install oh-my-posh
	if Mbs:Var:isTrue "$LI__INSTALL_OH_MY_POSH__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.install-oh-my-posh.sh]

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
		#endregion Bundler import [linux-init.mod/s0.install-oh-my-posh.sh]
		Mbs:LinuxInit:installOhMyPosh || Mbs:Script:die "Failed to install oh-my-posh"
	fi

	# Install SOPS
	if Mbs:Var:isTrue "$LI__INSTALL_SOPS__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.install-sops.sh]

		Mbs:LinuxInit:installSops() {
			Mbs:Io:print "Installing sops"

			local sops_version
			local pc_arch

			case "$(uname -m)" in
			x86_64 | amd64)
				pc_arch=amd64
				;;
			aarch64 | arm64)
				pc_arch=arm64
				;;
			*)
				Mbs:Io:error "Unsupported architecture: $(uname -m)"
				return 1
				;;
			esac

			# Get latest SOPS version from GitHub releases
			sops_version=$(curl -fsSL https://api.github.com/repos/getsops/sops/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')
			if [ -z "$sops_version" ]; then
				Mbs:Io:error "Unable to detect latest sops version"
				return 1
			fi

			curl -L --output sops "https://github.com/getsops/sops/releases/download/${sops_version}/sops-${sops_version}.linux.${pc_arch}"
			mv -f sops /usr/local/bin/sops
			chmod +x /usr/local/bin/sops

			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.install-sops.sh]
		Mbs:LinuxInit:installSops || Mbs:Script:die "Failed to install SOPS"
	fi

	# Prep Komodo
	if Mbs:Var:isTrue "$LI__KOMODO_PREP__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s0.komodo-prep.sh]

		Mbs:LinuxInit:komodoPrep() {
			Mbs:Io:print "Prepare Komodo"

			if ! Mbs:User:isNormal "$LI__USER"; then
				Mbs:Script:die "LI__USER problem, it must be set, it must be a normal user, it must exists"
			fi

			if Mbs:Var:isEmpty "$home_user_d"; then
				home_user_d=$(sudo -u "$LI__USER" sh -c 'echo $HOME')
			fi

			if Mbs:LinuxInit:isVarEmpty "$LI__KOMODO_PREP__SOPS_KEY"; then
				Mbs:Script:die "LI__KOMODO_PREP__SOPS_KEY env var must be set"
			fi

			local home_root_d="$HOME"
			local profile_root_f="$home_root_d/.profile"
			local profile_user_f="$home_user_d/.profile"

			if [ ! -f "$profile_root_f" ] || ! grep -q 'SOPS_AGE_KEY_FILE' "$profile_root_f"; then
				echo "export SOPS_AGE_KEY_FILE=/srv/docker/age.key" >>"$profile_root_f"
				Mbs:Io:print "Added SOPS_AGE_KEY_FILE to $profile_root_f"
			else
				Mbs:Io:print "$profile_root_f already configured with SOPS_AGE_KEY_FILE"
			fi

			if [ ! -f "$profile_user_f" ] || ! grep -q 'SOPS_AGE_KEY_FILE' "$profile_user_f"; then
				sudo -u "$LI__USER" "sh" -c "echo export SOPS_AGE_KEY_FILE=/srv/docker/age.key >> \"$profile_user_f\""
				Mbs:Io:print "Added SOPS_AGE_KEY_FILE to $profile_user_f"
			else
				Mbs:Io:print "$profile_user_f already configured with SOPS_AGE_KEY_FILE"
			fi

			local inst_type="${LI__KOMODO_PREP__TYPE:=komodoperiphery}"

			mkdir -p "/srv/docker/stacks/$inst_type"
			mkdir -p "/srv/docker/data/$inst_type"

			echo "$LI__KOMODO_PREP__SOPS_KEY" >/srv/docker/age.key

			# FIXME: Copy komodoperiphery/komodo stacks (from an encrypted zip)

			chown -R "root:docker" /srv/docker
			chmod -R g+rw /srv/docker

			Mbs:Io:print "Komodo prep finished"

			return 0
		}
		#endregion Bundler import [linux-init.mod/s0.komodo-prep.sh]
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
		#region Bundler import [linux-init.mod/s1.docker-login.sh]

		Mbs:LinuxInit:dockerLogin() {
			Mbs:Io:print "Docker login"

			local docker_group="docker"

			if Mbs:Var:isEmpty "$home_user_d"; then
				home_user_d=$(sudo -u "$LI__USER" sh -c 'echo $HOME')
			fi
			local auth_f="$home_user_d/.docker/config.json"

			if grep -q "index.docker.io" "$auth_f"; then
				Mbs:Io:print "Already logged to DockerHub, skipping"
				return 0
			fi

			Mbs:Io:print "Please prepare docker hub user and password"
			Mbs:Io:paktc

			if Mbs:Var:isEmpty "$LI__USER"; then
				Mbs:Io:error "Missing LI__USER, please enter the normal user name and press enter"
				read -r
				LI__USER="$REPLY"
			fi

			if ! Mbs:User:isNormal "$LI__USER"; then
				Mbs:Io:error "LI__USER problem, it must be set, it must be a normal user, it must exists"
				return 1
			fi

			if ! Mbs:User:isCurrentInGroup "$LI__USER" "$docker_group"; then
				Mbs:Io:error "LI__USER found, $LI__USER isn't in $docker_group group"
				read -p "Do you want to add $LI__USER to $docker_group group? Y/N: " -n 1 -r
				if [[ $REPLY =~ ^[Yy]$ ]]; then
					usermod -aG "$docker_group" "$LI__USER"
				else
					Mbs:Io:error "Cannot proceed"
					return 1
				fi
			fi

			sudo -u "$LI__USER" docker login -u "$LI__DOCKER_LOGIN__USERNAME"
			return 0
		}
		#endregion Bundler import [linux-init.mod/s1.docker-login.sh]
		Mbs:LinuxInit:dockerLogin || Mbs:Script:die "Failed to login to Docker"
	fi

	# Docker - custom bridge network
	if Mbs:Var:isTrue "$LI__DOCKER_NETWORK_CUSTOM_BRIDGE__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s1.docker-custom-bridge.sh]

		Mbs:LinuxInit:createCustomDockerBridgeNetwork() {
			Mbs:Io:print "Creating Docker custom bridge network"

			local docker_group="docker"

			Mbs:Var:isSet "LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME" || return 1

			if ! Mbs:User:isCurrentRunningAsRoot 2>/dev/null && ! Mbs:User:isCurrentInGroup "$docker_group"; then
				Mbs:Io:error "Current user isn't in $docker_group group, cannot proceed"
				Mbs:Io:error "Add current user to $docker_group group or run this script as root"
				return 1
			fi

			if docker network ls | grep "$LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME" 1>/dev/null 2>&1; then
				Mbs:Io:print "Docker bridge network '$LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME' already exists, skipping"
				return 0
			fi

			docker network create "$LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME"
			Mbs:Io:print "Docker custom bridge network '$LI__DOCKER_NETWORK_CUSTOM_BRIDGE__NAME' created"
			return 0
		}
		#endregion Bundler import [linux-init.mod/s1.docker-custom-bridge.sh]
		Mbs:LinuxInit:createCustomDockerBridgeNetwork || Mbs:Script:die "Failed to create custom Docker bridge network"
	fi

	# Backup - restore
	if Mbs:Var:isTrue "$LI__BACKUP_RESTORE__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s1.backup-restore.sh]

		Mbs:LinuxInit:restoreBackup() {
			Mbs:Io:print "Restoring backup"

			Mbs:Var:isSet "LI__BACKUP_RESTORE__FILE_PATH" || return 1

			if [ ! -f "$LI__BACKUP_RESTORE__FILE_PATH" ]; then
				Mbs:Io:print "Cannot find $LI__BACKUP_RESTORE__FILE_PATH, please check"
				return 1
			else
				tar --same-owner -xf "$LI__BACKUP_RESTORE__FILE_PATH" -C /
			fi

			Mbs:Io:print "Backup restored"
			return 0
		}
		#endregion Bundler import [linux-init.mod/s1.backup-restore.sh]
		Mbs:LinuxInit:restoreBackup || Mbs:Script:die "Failed to restore backup"
	fi

	if Mbs:Var:isTrue "$LI__DOCKER_COMPOSE_START__IS_ENABLED"; then
		Mbs:Io:printSep
		#region Bundler import [linux-init.mod/s1.docker-compose-start.sh]

		Mbs:LinuxInit:startDockerCompose() {
			Mbs:Io:print "Starting docker compose"

			local docker_group="docker"
			if ! Mbs:User:isCurrentRunningAsRoot 2>/dev/null && ! Mbs:User:isCurrentInGroup "$docker_group"; then
				Mbs:Io:error "Current user isn't in $docker_group group, cannot proceed"
				Mbs:Io:error "Add current user to $docker_group group or run this script as root"
				return 1
			fi

			Mbs:LinuxInit:checkConfig "LI__DOCKER_COMPOSE_START__FILE_PATH" || return 1

			if [ ! -f "$LI__DOCKER_COMPOSE_START__FILE_PATH" ]; then
				Mbs:Io:error "Cannot find $LI__DOCKER_COMPOSE_START__FILE_PATH compose file, please check"
				Mbs:LinuxInit:paktc
				return 1
			fi

			docker compose -f "$LI__DOCKER_COMPOSE_START__FILE_PATH" up -d
			Mbs:Io:print "Services in $LI__DOCKER_COMPOSE_START__FILE_PATH compose file should be up and running"

			return 0
		}
		#endregion Bundler import [linux-init.mod/s1.docker-compose-start.sh]
		Mbs:LinuxInit:startDockerCompose || Mbs:Script:die "Failed to start Docker Compose"
	fi

	echo "2" | tee "$helper_f" >/dev/null
	Mbs:Io:printSep
	Mbs:Io:success "Second part of the config done"
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
		Init a new Linux machine.

		USAGE: linux-init.sh.tmp.out <COMMAND>

		COMMANDS:
		  cfg  Create a config template.
		  run  run Load config and init the machine.
	EOF
	exit
}

_argc_version() {
	echo linux-init.sh.tmp.out 0.0.1
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
			_argc_die 'error: `linux-init.sh.tmp.out` requires a subcommand but one was not provided'$'\n'"  [subcommands: $_argc_subcmds]"
			;;
		esac
	done
	_argc_tools=(sudo)
	if [[ -n ${_argc_action:-} ]]; then
		$_argc_action
	else
		_argc_usage
	fi
}

_argc_usage_cfg() {
	cat <<-'EOF'
		Create a config template.

		USAGE: linux-init.sh.tmp.out cfg [OUT-FILE]

		ARGS:
		  [OUT-FILE]  Where to write the file. Defaults to /etc/linux-init/config.env
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
	_argc_tools=(sudo)
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

		USAGE: linux-init.sh.tmp.out run [OPTIONS] [CFG-FILE]

		ARGS:
		  [CFG-FILE]  Config file location. Defaults to /etc/linux-init/config.env

		OPTIONS:
		  -d, --data-dir <DATA-DIR>  Data dir location. Defaults to /etc/linux-init/data
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
	_argc_tools=(sudo)
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
