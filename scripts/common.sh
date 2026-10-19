#!/usr/bin/env bash

fail() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

detect_platform() {
    case "$(uname -s)" in
        Darwin) PLATFORM=macos ;;
        Linux) PLATFORM=linux ;;
        MINGW*|MSYS*) PLATFORM=windows ;;
        *) fail 'Supported systems: macOS, Linux, and Windows via Git Bash.' ;;
    esac
}

configure_paths() {
    STARSHIP_TARGET="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"
    case "$PLATFORM" in
        macos)
            WARP_CONFIG_DIR="$HOME/.warp"
            WARP_DATA_DIR="$HOME/.warp"
            ;;
        linux)
            WARP_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/warp-terminal"
            WARP_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/warp-terminal"
            ;;
        windows)
            require_command cygpath
            : "${APPDATA:?APPDATA must be set}" "${LOCALAPPDATA:?LOCALAPPDATA must be set}" "${USERPROFILE:?USERPROFILE must be set}"
            STARSHIP_TARGET="$(cygpath -u "${STARSHIP_CONFIG:-$USERPROFILE/.config/starship.toml}")"
            WARP_CONFIG_DIR="$(cygpath -u "$LOCALAPPDATA")/warp/Warp/config"
            WARP_DATA_DIR="$(cygpath -u "$APPDATA")/warp/Warp/data"
            ;;
    esac
    local path
    for path in "$STARSHIP_TARGET" "$WARP_CONFIG_DIR" "$WARP_DATA_DIR"; do
        case "$path" in /*) ;; *) fail "Configuration paths must be absolute: $path" ;; esac
    done
}

backup_path() {
    local target="$1" backup
    backup="${target}.backup.$(date +%Y%m%d-%H%M%S).$$"
    while [ -e "$backup" ] || [ -L "$backup" ]; do backup="${backup}.1"; done
    mv -- "$target" "$backup"
    printf 'Backup: %s\n' "$backup"
}

link_file() {
    local source_file="$1" target="$2"
    [ -f "$source_file" ] || fail "Source file is missing: $source_file"
    if [ "$source_file" -ef "$target" ]; then return; fi
    # Windows may have received a copy on a previous run.
    if [ "$PLATFORM" = windows ] && [ -f "$target" ] && cmp -s "$source_file" "$target"; then return; fi
    mkdir -p -- "$(dirname -- "$target")"
    if [ -e "$target" ] || [ -L "$target" ]; then backup_path "$target"; fi
    if [ "$PLATFORM" = windows ]; then
        # Native apps cannot read MSYS-only emulated symlinks.
        if ! MSYS=winsymlinks:nativestrict ln -s -- "$source_file" "$target"; then
            cp -- "$source_file" "$target"
            printf 'Copied (native symlinks unavailable): %s\n' "$target"
            return
        fi
    else
        ln -s -- "$source_file" "$target"
    fi
    printf 'Linked: %s -> %s\n' "$target" "$source_file"
}

append_shell_init() {
    local target="$1" shell_name="$2" line="$3"
    # Ignore comments, but recognize existing initialization with flags.
    if [ -f "$target" ] && grep -Eq "^[[:space:]]*([^#[:space:]].*)?starship[[:space:]]+init[[:space:]]+$shell_name([[:space:]\"')|;]|$)" "$target"; then
        return
    fi
    append_config "$target" "$line"
}

append_config() {
    local target="$1" line="$2" label="${3:-Starship prompt}"
    mkdir -p -- "$(dirname -- "$target")"
    if [ -L "$target" ] && [ ! -e "$target" ]; then backup_path "$target"; fi
    backup_config_file "$target"
    printf '\n# %s (dotfiles setup)\n%s\n' "$label" "$line" >> "$target"
    printf 'Configured shell: %s\n' "$target"
}

backup_config_file() {
    local target="$1"
    if [ -f "$target" ]; then
        local backup
        backup="$(mktemp "${target}.backup.XXXXXX")"
        cp -p -- "$target" "$backup"
        printf 'Backup: %s\n' "$backup"
    fi
}

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        require_command sudo
        sudo "$@"
    fi
}
