#!/usr/bin/env bash

_argc_scripts_build_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# shellcheck source=const.sh
. "$_argc_scripts_build_dir/const.sh"

_cleanup_file() {
	local input_file="$1"
	local output_file="${2:-}" # Default to empty if not provided

	# Ensure input file parameter is provided
	if [[ -z "$input_file" ]]; then
		echo "Usage: cleanup_file <input_file> [output_file]" >&2
		return 1
	fi

	# Ensure input file exists
	if [[ ! -f "$input_file" ]]; then
		echo "ERROR: File '$input_file' not found." >&2
		return 1
	fi

	# Process file with sed:
	# 1. Delete standalone lines containing only shellcheck directives
	# 2. Strip trailing shellcheck inline comments from commands
	# 3. Delete lines containing the BASH_SOURCE path resolution UNLESS preceded by '# mbs keep'
	# shellcheck disable=SC2016
	local sed_script='
		/^[[:space:]]*#[[:space:]]*shellcheck/d

        s/([^[:space:]].*)[[:space:]]*#[[:space:]]*shellcheck.*$/\1/

        /^[[:space:]]*#[[:space:]]*!mbs[[:space:]]+keep/ {
            N
            s/.*\n//
            b
        }
        
        /\$\(cd -P "\$\(dirname "\$\(realpath "\$\{BASH_SOURCE\[0\]}"\)"\)" >\/dev\/null 2>&1 && pwd\)/d
    '

	if [[ -n "$output_file" ]]; then
		sed -E "$sed_script" "$input_file" >"$output_file.tmp.${FUNCNAME[0]}"
		mv "$output_file.tmp.${FUNCNAME[0]}" "$output_file"
	else
		sed -E "$sed_script" "$input_file"
	fi
}

_bundle_sh_file() {
	local entrypoint_file="${1:-}"
	local output_file="${2:-}"

	if [[ -z "$entrypoint_file" ]]; then
		echo "Usage: bundle_sh_file <entrypoint.sh> [output.sh]" >&2
		return 1
	fi

	if [[ ! -f "$entrypoint_file" ]]; then
		echo "ERROR: Entrypoint file not found [$entrypoint_file]" >&2
		return 1
	fi

	# Strutture dati locali per tracciare lo stato dei file (ricorsione)
	local -A VISITED=()
	local -A CURRENT_STACK=()

	# Risoluzione percorsi assoluti per l'entrypoint e la directory root
	local entrypoint_real
	entrypoint_real=$(realpath "$entrypoint_file" 2>/dev/null || readlink -f "$entrypoint_file")
	local root_dir
	root_dir=$(dirname "$entrypoint_real")

	# Funzione ricorsiva interna
	_bundle_file_recursive() {
		local target_file
		target_file=$(realpath "$1" 2>/dev/null || readlink -f "$1")
		local base_dir
		base_dir=$(dirname "$target_file")

		# Percorso relativo per i tag di commento
		local relative_path_tag="${target_file#"$root_dir"/}"

		# 1. Verifica l'esistenza fisica del file
		if [[ ! -f "$target_file" ]]; then
			echo "ERROR: File not found [$target_file]" >&2
			return 1
		fi

		# 2. Controllo Import Circolare
		if [[ -n "${CURRENT_STACK[$target_file]:-}" ]]; then
			echo "ERROR: Circular import detected!" >&2
			echo "File [$target_file] is trying to import itself or a parent of itself." >&2
			return 1
		fi

		# 3. Controllo Idempotenza (Importato una sola volta)
		if [[ -n "${VISITED[$target_file]:-}" ]]; then
			echo "File [${target_file}] already imported" >&2
			return 0
		fi

		# Registra lo stato
		CURRENT_STACK[$target_file]=1
		VISITED[$target_file]=1

		# Stampa il tag di inizio import (tranne per l'entrypoint principale)
		if [[ "$target_file" != "$entrypoint_real" ]]; then
			echo "#region Bundler import [$relative_path_tag]"
		fi

		local prev_shellcheck_source=""

		# Legge il file riga per riga
		# shellcheck disable=SC2002
		cat "$target_file" | while IFS= read -r line || [[ -n "$line" ]]; do

			# Controlla se la riga corrente è una direttiva shellcheck source
			if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*shellcheck[[:space:]]+source=([^[:space:]]+) ]]; then
				prev_shellcheck_source="${BASH_REMATCH[1]}"
				continue
			fi

			# Identifica le righe che usano 'source' o '.'
			if [[ "$line" =~ ^[[:space:]]*(source|\.)[[:space:]]+([^;\&\|]+) ]]; then
				local raw_path=""
				local is_dynamic=0

				# Se c'è un hint shellcheck source valido, usa sempre quello
				if [[ -n "$prev_shellcheck_source" ]]; then
					raw_path="$prev_shellcheck_source"
					prev_shellcheck_source=""
				else
					raw_path="${BASH_REMATCH[2]}"
					raw_path=$(echo "$raw_path" | xargs)

					# Clean quotes (con fix shellcheck SC2295)
					raw_path="${raw_path%"\""}"
					raw_path="${raw_path#"\""}"
					raw_path="${raw_path%"'"}"
					raw_path="${raw_path#"'"}"

					# Se senza hint il percorso contiene variabili ($ o command substitution),
					# significa che è un import da valutare solo a runtime.
					if [[ "$raw_path" == *\$* || "$raw_path" == *"\$("* ]]; then
						is_dynamic=1
					fi
				fi

				# Se l'import è dinamico e senza hint, lascia la riga invariata
				if [[ $is_dynamic -eq 1 ]]; then
					echo "$line"
					continue
				fi

				# Costruzione full path
				local full_path
				if [[ "$raw_path" == /* ]]; then
					full_path="$raw_path"
				else
					full_path="$base_dir/$raw_path"
				fi

				full_path=$(realpath "$full_path" 2>/dev/null || readlink -f "$full_path")

				# Chiamata ricorsiva
				_bundle_file_recursive "$full_path" || return 1
			else
				# Se la riga corrente non è un source, resetta l'hint salvato
				prev_shellcheck_source=""

				# Mantiene lo shebang solo per il file principale
				if [[ "$line" =~ ^#! && "$target_file" != "$entrypoint_real" ]]; then
					continue
				fi
				echo "$line"
			fi
		done

		# Stampa il tag di fine import
		if [[ "$target_file" != "$entrypoint_real" ]]; then
			echo "#endregion Bundler import [$relative_path_tag]"
		fi

		unset "CURRENT_STACK[$target_file]"
	}

	# Esecuzione del bundling
	if [[ -n "$output_file" ]]; then
		_bundle_file_recursive "$entrypoint_real" >"$output_file.tmp.${FUNCNAME[0]}" || return 1
		mv "$output_file.tmp.${FUNCNAME[0]}" "$output_file"
		chmod +x "$output_file"
		echo "Bundle created successfully at [$output_file]" >&2
	else
		_bundle_file_recursive "$entrypoint_real" || return 1
	fi
}

_bundle_includes_file() {
	local entrypoint_file="${1:-}"
	local output_file="${2:-}"

	if [[ -z "$entrypoint_file" ]]; then
		echo "Usage: _bundle_includes_file <entrypoint.sh> [output.sh]" >&2
		return 1
	fi

	if [[ ! -f "$entrypoint_file" ]]; then
		echo "ERROR: Entrypoint file not found [$entrypoint_file]" >&2
		return 1
	fi

	# Resolve absolute paths and base directory
	local entrypoint_real
	entrypoint_real=$(realpath "$entrypoint_file" 2>/dev/null || readlink -f "$entrypoint_file")
	local base_dir
	base_dir=$(dirname "$entrypoint_real")

	process_stream() {
		local prev_include_source=""
		local line

		# Read the main entrypoint file line by line
		while IFS= read -r line || [[ -n "$line" ]]; do
			# Check if current line is a !mbs include hint directive
			if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*!mbs[[:space:]]+include=([^[:space:]]+) ]]; then
				prev_include_source="${BASH_REMATCH[1]}"
				continue
			fi

			# Match base64 lines that represent file references
			if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)=\$\(base64[[:space:]]+-w0[[:space:]]+([^;\&\|]+)\) ]]; then
				local var_name="${BASH_REMATCH[1]}"
				local raw_path=""
				local is_dynamic=0

				# Use the hint if available
				if [[ -n "$prev_include_source" ]]; then
					raw_path="$prev_include_source"
					prev_include_source=""
				else
					raw_path="${BASH_REMATCH[2]}"
					raw_path=$(echo "$raw_path" | xargs)

					# Strip quotes
					raw_path="${raw_path%"\""}"
					raw_path="${raw_path#"\""}"
					raw_path="${raw_path%"'"}"
					raw_path="${raw_path#"'"}"

					# Mark as dynamic if path contains runtime variables
					if [[ "$raw_path" == *\$* || "$raw_path" == *"\$("* ]]; then
						is_dynamic=1
					fi
				fi

				# Leave dynamic imports untouched
				if [[ $is_dynamic -eq 1 ]]; then
					echo "$line"
					continue
				fi

				# Resolve absolute path for target file
				local full_path
				if [[ "$raw_path" == /* ]]; then
					full_path="$raw_path"
				else
					full_path="$base_dir/$raw_path"
				fi

				full_path=$(realpath "$full_path" 2>/dev/null || readlink -f "$full_path")

				# Verify target file exists
				if [[ ! -f "$full_path" ]]; then
					echo "ERROR: Included file not found [$full_path]" >&2
					return 1
				fi

				# Output header and dump base64 encoded content without line breaks
				local relative_path_tag="${full_path#"$base_dir"/}"
				echo "# File included (base64) [$relative_path_tag]"
				local encoded_content
				encoded_content=$(base64 -w0 "$full_path")
				echo "${var_name}=\"${encoded_content}\""
				echo "" # Ensure trailing newline after base64 output
			else
				# Reset hint if current line is not an import
				prev_include_source=""
				echo "$line"
			fi
		done <"$entrypoint_real"
	}

	# Execute process stream and write to output file or stdout
	if [[ -n "$output_file" ]]; then
		local tmp_file="$output_file.tmp.${FUNCNAME[0]}"

		process_stream >"$tmp_file" || {
			rm -f "$tmp_file"
			return 1
		}

		if [[ "$entrypoint_real" -ef "$output_file" ]]; then
			cat "$tmp_file" >"$output_file"
		else
			mv "$tmp_file" "$output_file"
		fi
		rm -f "$tmp_file"
		chmod +x "$output_file"
		echo "Included files created successfully at [$output_file]" >&2
	else
		process_stream
	fi
}

_move_meta_comments() {
	local input_file="$1"
	local output_file="${2:-}" # Left empty if not provided

	# Check if input file exists
	if [[ ! -f "$input_file" ]]; then
		echo "ERROR: File '$input_file' does not exist." >&2
		return 1
	fi

	# Processing logic
	process_stream() {
		local -a meta_lines=()
		local line
		local inserted=false

		_print_meta_lines() {
			echo "#region Meta moved"
			printf '%s\n' "$@"
			echo "#endregion Meta moved"
			echo ""
		}

		_dedupe_array() {
			# declare -n creates a reference (nameref) to the array passed as an argument
			declare -n arr_ref="$1"

			# Safety check: exit if the array variable is unset
			[[ -z "${arr_ref+x}" ]] && return 0

			# Temporary associative array to track unique items (acts like a hash set)
			declare -A seen
			# Temporary indexed array to store the result while preserving order
			declare -a result=()

			# Loop through all elements of the original array
			for item in "${arr_ref[@]}"; do
				# If the item has not been seen yet
				if [[ -z "${seen[$item]+x}" ]]; then
					seen["$item"]=1   # Mark it as seen
					result+=("$item") # Add it to the clean result array
				fi
			done

			# Overwrite the original array with the deduplicated results
			arr_ref=("${result[@]}")
		}

		# 1. Extract and transform all meta lines into an array
		while IFS= read -r line; do
			meta_lines+=("${line//!mbs meta/@meta}")
		done < <(grep -E '^[[:space:]]*#.*!mbs meta' "$input_file")

		# 2. Process the file and insert the meta block before the first code line
		while IFS= read -r line || [[ -n "$line" ]]; do
			# Skip existing meta lines (they will be moved)
			if [[ "$line" =~ ^[[:space:]]*#.*!mbs[[:space:]]+meta ]]; then
				continue
			fi

			# Check for the first actual line of code (not empty and not a comment)
			if [[ "$inserted" == false && ! "$line" =~ ^[[:space:]]*($|#) ]]; then
				if ((${#meta_lines[@]} > 0)); then
					_dedupe_array meta_lines
					_print_meta_lines "${meta_lines[@]}"
				fi
				inserted=true
			fi

			echo "$line"
		done <"$input_file"

		# If the file had no code lines (only comments/empty), append at the end
		if [[ "$inserted" == false && ${#meta_lines[@]} -gt 0 ]]; then
			_dedupe_array meta_lines
			_print_meta_lines "${meta_lines[@]}"
		fi
	}

	if [[ -z "$output_file" ]]; then
		# No output file provided -> print to stdout
		process_stream
	else
		# Output file provided -> use a safe temporary file
		local tmp_file="$output_file.tmp.${FUNCNAME[0]}"

		process_stream >"$tmp_file"

		# If writing back to the input file, preserve original permissions
		if [[ "$input_file" -ef "$output_file" ]]; then
			cat "$tmp_file" >"$output_file"
		else
			mv "$tmp_file" "$output_file"
		fi
		rm -f "$tmp_file"
	fi
}

_format_file() {
	local input_file="$1"
	local output_file="${2:-}" # Default to empty if not provided

	# Ensure input file parameter is provided
	if [[ -z "$input_file" ]]; then
		echo "Usage: cleanup_file <input_file> [output_file]" >&2
		return 1
	fi

	# Ensure input file exists
	if [[ ! -f "$input_file" ]]; then
		echo "ERROR: File '$input_file' not found." >&2
		return 1
	fi

	# Process file with shfmt
	if [[ -n "$output_file" ]]; then
		shfmt -s -i 0 -bn "$input_file" >"$output_file.tmp.${FUNCNAME[0]}"
		mv "$output_file.tmp.${FUNCNAME[0]}" "$output_file"
	else
		shfmt -s -i 0 -bn "$input_file"
	fi
}

build_entrypoint() {
	local src_dir="$src_dir"
	local bin_dir="$bin_dir"

	if [[ ! -d "$src_dir" ]]; then
		echo "ERROR: Source directory '$src_dir' not found." >&2
		return 1
	fi

	# 1. Crea la cartella di output come prima istruzione
	mkdir -p "$bin_dir" || return 1

	# Attiva nullglob per evitare che il wildcard *.sh venga trattato come stringa letterale se non ci sono match
	shopt -s nullglob
	local sh_files=("$src_dir"/*.sh)
	shopt -u nullglob

	if [[ ${#sh_files[@]} -eq 0 ]]; then
		echo "No .sh files found in '$src_dir'." >&2
		return 0
	fi

	# 2. Cicla su tutti i file .sh
	local file
	for file in "${sh_files[@]}"; do
		local filename tmp_f
		filename=$(basename "$file")
		tmp_f="$src_dir/$filename.tmp.out"

		echo ">> [$filename] Processing"

		# 3. Invocazione in sequenza delle 3 funzioni
		echo "> [$filename] Bundling"
		_bundle_sh_file "$src_dir/$filename" "$tmp_f" || {
			echo "ERROR: Error during bundling for [$filename]" >&2
			return 1
		}

		echo "> [$filename] Including files"
		_bundle_includes_file "$tmp_f" "$tmp_f" || {
			echo "ERROR: Error during include file for [$filename]" >&2
			return 1
		}

		echo "> [$filename] Relocating meta comments"
		_move_meta_comments "$tmp_f" "$tmp_f" || {
			echo "ERROR: Error during meta moving for [$filename]" >&2
			return 1
		}

		echo "> [$filename] Argc build"
		argc --argc-build "$tmp_f" "$tmp_f" || {
			echo "ERROR: Error during argc build for [$filename]" >&2
			return 1
		}

		echo "> [$filename] Cleanup"
		_cleanup_file "$tmp_f" "$tmp_f" || {
			echo "ERROR: Error during cleanup for [$filename]" >&2
			return 1
		}

		echo "> [$filename] Format"
		_format_file "$tmp_f" "$tmp_f" || {
			echo "ERROR: Error during format for [$filename]" >&2
			return 1
		}

		echo "> [$filename] Move & chmod script"
		chmod +x "$tmp_f"
		mv "$tmp_f" "$bin_dir/$filename"

		echo ">> [$filename] Finished"
		echo ""
	done

	echo "Build completed successfully for all files."
}
