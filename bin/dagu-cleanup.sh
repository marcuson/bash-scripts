#!/usr/bin/env bash

# @describe Remove empty Dagu logs folders.
# @meta version 0.0.1
# @meta require-tools curl
# @meta require-tools grep
# @meta require-tools host
# @meta require-tools jq
# @arg dagu-home Home dir of Dagu.

set -euo pipefail

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

_entry() {
	config_dir=${argc_dagu_home:-/var/lib/dagu}
	logs_dir="$config_dir/logs"

	if [ ! -d "${config_dir}" ]; then
		Mbs:Script:die "Config dir '${config_dir}' does not exists."
	fi

	if [ ! -d "${logs_dir}" ]; then
		Mbs:Script:die "Logs dir '${logs_dir}' does not exists."
	fi

	Mbs:Io:print "Delete empty logs"
	logs_deleted_count=$(find "${logs_dir}" -mindepth 2 -type d -empty -print -delete | tee /dev/stderr | wc -l)
	Mbs:Io:print "$logs_deleted_count empty log dirs deleted."
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
		Remove empty Dagu logs folders.

		USAGE: dagu-cleanup.sh.tmp.out [DAGU-HOME]

		ARGS:
		  [DAGU-HOME]  Home dir of Dagu.
	EOF
	exit
}

_argc_version() {
	echo dagu-cleanup.sh.tmp.out 0.0.1
	exit
}

_argc_parse() {
	local _argc_key _argc_action
	local _argc_subcmds=""
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
		*)
			argc__positionals+=("$_argc_item")
			_argc_index=$((_argc_index + 1))
			;;
		esac
	done
	_argc_tools=(curl)
	if [[ -n ${_argc_action:-} ]]; then
		$_argc_action
	else
		if [[ ${argc__positionals[0]:-} == "help" ]] && [[ ${#argc__positionals[@]} -eq 1 ]]; then
			_argc_usage
		fi
		_argc_match_positionals 0
		local values_index values_size
		IFS=: read -r values_index values_size <<<"${_argc_match_positionals_values[0]:-}"
		if [[ -n $values_index ]]; then
			argc_dagu_home="${argc__positionals[values_index]}"
		fi
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

_entry
