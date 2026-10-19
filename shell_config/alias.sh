#!/usr/bin/env bash
# Source this file from Bash or Zsh so aliases affect the calling shell.
_dotfiles_load_aliases() {
    local loader_path config_dir alias_file
    if [ -n "${ZSH_VERSION:-}" ]; then
        loader_path="${(%):-%x}"
        config_dir="${loader_path:A:h}"
    elif [ -n "${BASH_VERSION:-}" ]; then
        loader_path="${BASH_SOURCE[0]}"
        # macOS readlink has no portable -f option; resolve links explicitly.
        while [ -L "$loader_path" ]; do
            config_dir="$(CDPATH= cd -P -- "$(dirname -- "$loader_path")" && pwd)" || return
            loader_path="$(readlink -- "$loader_path")" || return
            case "$loader_path" in /*) ;; *) loader_path="$config_dir/$loader_path" ;; esac
        done
        config_dir="$(CDPATH= cd -P -- "$(dirname -- "$loader_path")" && pwd)" || return
    else
        printf 'Dotfiles aliases require Bash or Zsh.\n' >&2
        return 1
    fi

    case "${OSTYPE:-}" in
        darwin*) export ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs" ;;
    esac

    for alias_file in "$config_dir"/aliases/*.sh; do
        source "$alias_file" || return
    done
}

if _dotfiles_load_aliases; then
    unset -f _dotfiles_load_aliases
else
    unset -f _dotfiles_load_aliases
    return 1
fi
