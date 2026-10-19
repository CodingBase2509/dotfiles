#!/usr/bin/env bash

install_windows_package() {
    local package_id="$1"
    require_command winget.exe
    if winget.exe list --id "$package_id" --exact --source winget --accept-source-agreements >/dev/null 2>&1; then
        printf 'Already installed: %s\n' "$package_id"
        return
    fi
    winget.exe install --id "$package_id" --exact --source winget --accept-source-agreements --accept-package-agreements
}

install_starship() {
    if command -v starship >/dev/null 2>&1; then
        printf 'Starship is already installed.\n'
        return
    fi
    case "$PLATFORM" in
        macos)
            require_command brew
            brew install starship
            ;;
        linux) install_starship_linux ;;
        windows) install_windows_package Starship.Starship ;;
    esac
}

install_starship_linux() (
    require_command curl
    download_dir="$(mktemp -d)"
    trap 'rm -rf -- "$download_dir"' EXIT
    curl -fSL --retry 3 https://starship.rs/install.sh -o "$download_dir/install-starship.sh"
    # The official installer uses /usr/local/bin and asks for sudo if necessary.
    sh "$download_dir/install-starship.sh" --yes
)

install_warp() {
    case "$PLATFORM" in
        macos)
            if [ -d /Applications/Warp.app ] || [ -d "$HOME/Applications/Warp.app" ]; then
                printf 'Warp is already installed.\n'
                return
            fi
            require_command brew
            brew install --cask warp
            ;;
        linux)
            if command -v warp-terminal >/dev/null 2>&1; then
                printf 'Warp is already installed.\n'
                return
            fi
            install_warp_linux
            ;;
        windows) install_windows_package Warp.Warp ;;
    esac
}

install_warp_linux() (
    require_command curl
    case "$(uname -m)" in
        x86_64|amd64) architecture=x86_64 ;;
        aarch64|arm64) architecture=aarch64 ;;
        *) fail 'Warp requires x86_64 or ARM64.' ;;
    esac

    if command -v apt-get >/dev/null 2>&1; then
        package=deb; extension=deb; manager=apt-get
    elif command -v dnf >/dev/null 2>&1; then
        package=rpm; extension=rpm; manager=dnf
    elif command -v zypper >/dev/null 2>&1; then
        package=rpm; extension=rpm; manager=zypper
    elif command -v pacman >/dev/null 2>&1; then
        package=pacman; extension=pkg.tar.zst; manager=pacman
    else
        fail 'Automatic Warp installation requires apt-get, dnf, zypper, or pacman. Install Warp manually, then rerun.'
    fi
    if [ "$architecture" = aarch64 ]; then package="${package}_arm64"; fi

    download_dir="$(mktemp -d)"
    trap 'rm -rf -- "$download_dir"' EXIT
    # apt's sandbox user must be able to read the downloaded package.
    chmod 755 "$download_dir"
    package_file="$download_dir/warp-terminal.$extension"
    curl -fSL --retry 3 "https://app.warp.dev/download?package=$package" -o "$package_file"
    chmod 644 "$package_file"
    case "$manager" in
        apt-get) run_as_root apt-get install -y "$package_file" ;;
        dnf) run_as_root dnf install -y "$package_file" ;;
        zypper) run_as_root zypper --non-interactive install "$package_file" ;;
        pacman) run_as_root pacman -U --noconfirm "$package_file" ;;
    esac
)
