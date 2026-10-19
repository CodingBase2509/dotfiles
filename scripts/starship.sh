#!/usr/bin/env bash

configure_starship() {
    link_file "$REPO_ROOT/starship.toml" "$STARSHIP_TARGET"

    if [ "$PLATFORM" = windows ]; then
        configure_powershell
        return
    fi

    local default_shell zsh_rc bash_rc fish_rc
    default_shell="$SETUP_SHELL"
    zsh_rc="${ZDOTDIR:-$HOME}/.zshrc"
    bash_rc="$HOME/.bashrc"
    fish_rc="${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"

    if [ "$default_shell" = zsh ] || [ -f "$zsh_rc" ]; then
        append_shell_init "$zsh_rc" zsh 'eval "$(starship init zsh)"'
    fi
    if [ "$default_shell" = bash ] || [ -f "$bash_rc" ]; then
        append_shell_init "$bash_rc" bash 'eval "$(starship init bash)"'
        configure_bash_login
    fi
    if [ "$default_shell" = fish ] || [ -f "$fish_rc" ]; then
        append_shell_init "$fish_rc" fish 'starship init fish | source'
    fi
    case "$default_shell" in
        zsh|bash|fish) ;;
        *) printf 'Shell %s: add Starship initialization manually.\n' "${default_shell:-unknown}" ;;
    esac
}

configure_bash_login() {
    # Login shells (including Warp) read the first of these files, not .bashrc.
    local login_file candidate
    login_file="$HOME/.bash_profile"
    for candidate in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
        if [ -f "$candidate" ]; then login_file="$candidate"; break; fi
    done
    if [ -f "$login_file" ] && grep -Eq '^[[:space:]]*[^#[:space:]].*(source|\.)[[:space:]].*\.bashrc|^[[:space:]]*(source|\.)[[:space:]].*\.bashrc' "$login_file"; then
        return
    fi
    append_config "$login_file" 'if [ -n "${BASH_VERSION:-}" ] && [ -f "$HOME/.bashrc" ]; then . "$HOME/.bashrc"; fi'
}

configure_powershell() {
    local executable configured=false
    for executable in powershell.exe pwsh.exe; do
        if command -v "$executable" >/dev/null 2>&1; then
            "$executable" -NoLogo -NoProfile -File \
                "$(cygpath -w "$REPO_ROOT/scripts/powershell-profile.ps1")"
            configured=true
        fi
    done
    [ "$configured" = true ] || fail 'PowerShell was not found; Starship shell initialization could not be configured.'
}
