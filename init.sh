#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SKIP_INSTALL=false

for argument in "$@"; do
    case "$argument" in
        --skip-install) SKIP_INSTALL=true ;;
        -h|--help)
            printf 'Usage: bash init.sh [--skip-install]\n\nInstall Warp, Starship and shell tools, then link their configuration.\n--skip-install  Only configure files and shell initialization.\n'
            exit 0
            ;;
        *) printf 'Unknown option: %s\n' "$argument" >&2; exit 1 ;;
    esac
done

source "$REPO_ROOT/scripts/common.sh"
source "$REPO_ROOT/scripts/homebrew.sh"
source "$REPO_ROOT/scripts/install.sh"
source "$REPO_ROOT/scripts/shell-tools.sh"
source "$REPO_ROOT/scripts/starship.sh"
source "$REPO_ROOT/scripts/aliases.sh"
source "$REPO_ROOT/scripts/warp.sh"

detect_platform
detect_setup_shell
configure_paths
printf 'Setting up Warp and Starship on %s\n' "$PLATFORM"

if [ "$SKIP_INSTALL" = false ]; then
    if [ "$PLATFORM" = macos ]; then ensure_homebrew; fi
    install_starship
    install_warp
    install_shell_tools
fi

configure_starship
configure_aliases
configure_warp
printf '\nSetup complete. Restart your shell and Warp.\n'
printf 'In Warp: Settings > Appearance > Input > Shell (PS1). Select a custom theme under Themes.\n'
