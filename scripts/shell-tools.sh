#!/usr/bin/env bash

install_shell_tools() {
    if [ "$PLATFORM" = windows ]; then
        printf 'Additional shell tools are optional on Windows; skipping installation.\n'
        return
    fi

    local packages=()
    if ! command -v nvim >/dev/null 2>&1; then packages+=(neovim); fi
    if ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1; then
        packages+=(bat)
    fi
    if [ "$PLATFORM" = macos ] && ! command -v gls >/dev/null 2>&1; then
        packages+=(coreutils)
    fi

    if [ "${#packages[@]}" -eq 0 ]; then
        printf 'Shell tools are already installed.\n'
        return
    fi
    printf 'Installing missing shell tools: %s\n' "${packages[*]}"
    case "$PLATFORM" in
        macos)
            require_command brew
            brew install "${packages[@]}"
            ;;
        linux)
            if command -v apt-get >/dev/null 2>&1; then
                run_as_root apt-get update
                run_as_root apt-get install -y "${packages[@]}"
            elif command -v dnf >/dev/null 2>&1; then
                run_as_root dnf install -y "${packages[@]}"
            elif command -v zypper >/dev/null 2>&1; then
                run_as_root zypper --non-interactive install "${packages[@]}"
            elif command -v pacman >/dev/null 2>&1; then
                run_as_root pacman -S --needed --noconfirm "${packages[@]}"
            else
                fail "Install these tools manually, then rerun: ${packages[*]} (supported: apt-get, dnf, zypper, pacman)."
            fi
            ;;
    esac
}
