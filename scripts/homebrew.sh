#!/usr/bin/env bash

find_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        command -v brew
        return
    fi

    local prefix
    local prefixes=(/opt/homebrew /usr/local)
    if [ "$(uname -m)" = x86_64 ]; then prefixes=(/usr/local /opt/homebrew); fi
    for prefix in "${prefixes[@]}"; do
        if [ -x "$prefix/bin/brew" ]; then
            printf '%s\n' "$prefix/bin/brew"
            return
        fi
    done
    return 1
}

install_homebrew() (
    require_command curl
    download_dir="$(mktemp -d)"
    trap 'rm -rf -- "$download_dir"' EXIT
    curl -fSL --retry 3 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
        -o "$download_dir/install-homebrew.sh"
    # Keep the official installer's confirmation and sudo prompts interactive.
    /bin/bash "$download_dir/install-homebrew.sh"
)

ensure_homebrew() {
    local brew_binary shell_environment init_line profile
    if brew_binary="$(find_homebrew)"; then
        printf 'Homebrew is already installed: %s\n' "$brew_binary"
    else
        printf 'Installing Homebrew first.\n'
        install_homebrew
        brew_binary="$(find_homebrew)" || fail 'Homebrew installation finished, but brew could not be found.'
    fi

    # This must run in the current process so subsequent installs can use brew.
    shell_environment="$("$brew_binary" shellenv)"
    eval "$shell_environment"
    require_command brew

    # macOS uses Zsh by default. Respect a custom Zsh configuration directory.
    profile="${ZDOTDIR:-$HOME}/.zprofile"
    printf -v init_line 'eval "$(%q shellenv)"' "$brew_binary"
    if [ -f "$profile" ] && grep -Fqx -- "$init_line" "$profile"; then return; fi
    append_config "$profile" "$init_line" Homebrew
}
