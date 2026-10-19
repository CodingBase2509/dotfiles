#!/usr/bin/env bash

detect_setup_shell() {
    # init.sh itself runs in Bash, so inspect its parent before using $SHELL.
    local parent_shell=''
    if command -v ps >/dev/null 2>&1; then
        parent_shell="$(ps -p "$PPID" -o comm= 2>/dev/null)" || parent_shell=''
        parent_shell="${parent_shell##*/}"
        parent_shell="${parent_shell#-}"
    fi
    case "$parent_shell" in
        bash|zsh|fish) SETUP_SHELL="$parent_shell" ;;
        *) SETUP_SHELL="${SHELL:-}"; SETUP_SHELL="${SETUP_SHELL##*/}" ;;
    esac
}

configure_aliases() {
    if [ "$PLATFORM" = windows ]; then
        printf 'PowerShell aliases are configured through the PowerShell profile.\n'
        return
    fi

    local rc_file source_line temporary_file input_file
    case "$SETUP_SHELL" in
        zsh) rc_file="${ZDOTDIR:-$HOME}/.zshrc" ;;
        bash) rc_file="$HOME/.bashrc" ;;
        *) printf 'Aliases require Bash or Zsh; skipping shell %s.\n' "${SETUP_SHELL:-unknown}"; return ;;
    esac

    printf -v source_line 'source %q' "$REPO_ROOT/shell_config/alias.sh"
    if [ -f "$rc_file" ] && grep -Fqx -- "$source_line" "$rc_file"; then return; fi
    mkdir -p -- "$(dirname -- "$rc_file")"
    # Migrate a dangling link, e.g. to the old shell_config/.zshrc.
    if [ -L "$rc_file" ] && [ ! -e "$rc_file" ]; then backup_path "$rc_file"; fi
    backup_config_file "$rc_file"
    input_file=/dev/null
    if [ -f "$rc_file" ]; then input_file="$rc_file"; fi

    temporary_file="$(mktemp "${rc_file}.tmp.XXXXXX")"
    # Pass the line through ENVIRON so awk doesn't reinterpret path backslashes.
    if ! DOTFILES_ALIAS_SOURCE="$source_line" awk '
        function insert_loader() {
            print "# Dotfiles aliases (dotfiles setup)"
            print ENVIRON["DOTFILES_ALIAS_SOURCE"]
            print ""
            inserted = 1
        }
        !inserted && $0 !~ /^[[:space:]]*#/ && /starship[[:space:]]+init[[:space:]]+(bash|zsh)/ {
            insert_loader()
        }
        { print }
        END { if (!inserted) insert_loader() }
    ' "$input_file" > "$temporary_file"; then
        rm -f -- "$temporary_file"
        fail "Could not configure aliases in $rc_file"
    fi
    # Write through valid symlinks and preserve existing file permissions.
    if ! cat "$temporary_file" > "$rc_file"; then
        rm -f -- "$temporary_file"
        fail "Could not write $rc_file"
    fi
    rm -f -- "$temporary_file"
    printf 'Configured aliases: %s\n' "$rc_file"
}
