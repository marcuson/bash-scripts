#!/usr/bin/env bash

# @describe Encrypt/decrypt a file using a password and GPG.
# @meta version 0.0.1
# @meta require-tools curl
# @meta require-tools jq
# @option -u --url! Mealie base URL.
# @option -k --api-key! API key.

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

	# FIXME: Unregister traps
	exit 1
}
#endregion Bundler import [utils.mod/script.sh]

_entry() {
	local mealie_url="${argc_url%/}"
	local mealie_api_key="$argc_api_key"

	local api_base_url="${mealie_url}/api"
	local auth_header="Authorization: Bearer ${mealie_api_key}"
	local inbox_tag_name="INBOX"

	Mbs:Io:print "Checking if tag '$inbox_tag_name' exists..."

	# 1. Get or Create the target tag to obtain its full object (id, name, slug)
	local tag_list tag_obj
	tag_list=$(curl -s -H "$auth_header" "${api_base_url}/organizers/tags?perPage=1000")
	tag_obj=$(echo "$tag_list" | jq -c ".items[] | select(.name == \"$inbox_tag_name\")")

	if [ -z "$tag_obj" ]; then
		Mbs:Io:print "Tag not found. Creating tag '$inbox_tag_name'..."
		tag_obj=$(curl -s -X 'POST' \
			-H "$auth_header" \
			-H 'Content-Type: application/json' \
			-d "{\"name\": \"$inbox_tag_name\"}" \
			"${api_base_url}/organizers/tags")

		# If creation failed (e.g., due to Mealie v1.x group requirements)
		if echo "$tag_obj" | jq -e '.detail' >/dev/null; then
			Mbs:Script:die "Error creating tag: $(echo "$tag_obj" | jq -r '.detail')"
		fi
	fi

	local tag_id
	tag_id=$(echo "$tag_obj" | jq -r '.id')
	Mbs:Io:print "Using Tag ID: $tag_id"

	# 2. Fetch recipes and find those with no tags
	Mbs:Io:print "Fetching all untagged recipes..."
	# Note: perPage=1000 is used to avoid complex pagination logic for most home libraries
	local recipes_json
	recipes_json=$(curl -s --fail-with-body -H "$auth_header" "${api_base_url}/recipes?perPage=1000&queryFilter=tags.name%20IS%20null")

	# Filter for IDs of recipes where the 'tags' array is empty
	local untagged_slugs
	untagged_slugs=$(echo "$recipes_json" | jq -r '.items[] | select(.tags | length == 0) | .slug')

	if [ -z "$untagged_slugs" ]; then
		Mbs:Io:print "No untagged recipes found."
		return 0
	fi

	# Count how many we found
	local untagged_count
	untagged_count=$(echo "$untagged_slugs" | wc -l)
	Mbs:Io:print "Found $untagged_count untagged recipes. Applying tag..."

	# 3. Perform Bulk Tag Action
	# Convert IDs into a JSON array
	local untagged_slugs_array
	untagged_slugs_array=$(echo "$untagged_slugs" | jq -R . | jq -s -c .)

	# Mealie Bulk Action Body
	# Note: Newer Mealie versions may require the full tag object inside the array
	local bulk_payload
	bulk_payload=$(jq -n \
		--argjson recipes "$untagged_slugs_array" \
		--argjson tag "[$tag_obj]" \
		'{recipes: $recipes, tags: $tag}')

	local api_response_code
	api_response_code=$(curl -o /dev/null -w "%{http_code}\n" -s -X 'POST' \
		-H "$auth_header" \
		-H 'Content-Type: application/json' \
		-d "$bulk_payload" \
		"${api_base_url}/recipes/bulk-actions/tag")

	if [[ $api_response_code == "200" ]]; then
		Mbs:Io:print "Successfully assigned '$inbox_tag_name' to $untagged_count recipes."
	else
		Mbs:Script:die "HTTP status code from server: $api_response_code"
	fi
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
	_argc_require_params "error: the following required arguments were not provided:" "${_argc_required_flag_options[@]}"
	_argc_require_tools "${_argc_tools[@]}"
	if [ -n "${argc__fn:-}" ]; then
		$argc__fn "${argc__positionals[@]}"
	fi
}

_argc_usage() {
	cat <<-'EOF'
		Encrypt/decrypt a file using a password and GPG.

		USAGE: mealietag.sh.tmp.out --url <URL> --api-key <API-KEY>

		OPTIONS:
		  -u, --url <URL>          Mealie base URL.
		  -k, --api-key <API-KEY>  API key.
		  -h, --help               Print help
		  -V, --version            Print version
	EOF
	exit
}

_argc_version() {
	echo mealietag.sh.tmp.out 0.0.1
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
		--url | -u)
			_argc_take_args "--url <URL>" 1 1 "-" ""
			_argc_index=$((_argc_index + _argc_take_args_len + 1))
			if [[ -z ${argc_url:-} ]]; then
				argc_url="${_argc_take_args_values[0]:-}"
			else
				_argc_die 'error: the argument `--url` cannot be used multiple times'
			fi
			;;
		--api-key | -k)
			_argc_take_args "--api-key <API-KEY>" 1 1 "-" ""
			_argc_index=$((_argc_index + _argc_take_args_len + 1))
			if [[ -z ${argc_api_key:-} ]]; then
				argc_api_key="${_argc_take_args_values[0]:-}"
			else
				_argc_die 'error: the argument `--api-key` cannot be used multiple times'
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
	_argc_required_flag_options+=('argc_url:--url <URL>' 'argc_api_key:--api-key <API-KEY>')
	_argc_tools=(curl)
	if [[ -n ${_argc_action:-} ]]; then
		$_argc_action
	else
		if [[ ${argc__positionals[0]:-} == "help" ]] && [[ ${#argc__positionals[@]} -eq 1 ]]; then
			_argc_usage
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

_argc_require_params() {
	local message="$1" missed_envs="" item name render_name
	for item in "${@:2}"; do
		name="${item%%:*}"
		render_name="${item##*:}"
		if [[ -z ${!name:-} ]]; then
			missed_envs="$missed_envs"$'\n'"  $render_name"
		fi
	done
	if [[ -n ${missed_envs} ]]; then
		_argc_die "$message$missed_envs"
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
