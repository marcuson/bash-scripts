#!/usr/bin/env bash
# shellcheck disable=SC1091

# @describe Encrypt/decrypt a file using a password and GPG.
# @meta version 0.0.1
# @meta require-tools gpg

set -euo pipefail

_this_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# shellcheck source=utils.mod/io.sh
source "$_this_dir/utils.mod/io.sh"

# @cmd Encrypt a file.
# @option -p --pass! Passphrase to use.
# @arg file! File to encrypt.
enc() {
    # shellcheck disable=SC2154
    local in_f="$argc_file"
    # shellcheck disable=SC2154
    local pass="$argc_pass"

    gpg --batch -c --passphrase "$pass" --output "$in_f.gpg" "$in_f"
    Mbs:Io:success "File [$in_f] encrypted"
}

# @cmd Decrypt a file.
# @option -p --pass! Passphrase to use.
# @arg file! File to decrypt.
dec() {
    local in_f="$argc_file"
    local pass="$argc_pass"
    local out_f
    out_f=$(basename "$in_f")
    out_f="${out_f%.*}"

    gpg --batch -d --passphrase "$pass" --output "$out_f" "$in_f"
    Mbs:Mbs:Io:success "File [$in_f] decrypted"
}

eval "$(argc --argc-eval "$0" "$@")"
