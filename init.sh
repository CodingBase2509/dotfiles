#!/bin/bash
os=$OSTYPE

# starship install on windows
on_windows(){
    echo "Install starship"

    cd "C:\Users\$USER" ||exit 1
    if [ ! "$(winget install --id Starship.Starship)" ]; then
    exit 1
    fi
    echo "Invoke-Expression (&starship init powershell)" >> "$PROFILE"
}

# starship install on linux systems
on_linux(){
    echo "Install starship"

    curl -sS https://starship.rs/install.sh | sh
    cd ~/ || exit 1
    ln -s "$(pwd)"/starship.toml ~/.config/starship.toml
}

# starship install on MacOS
on_mac(){
    echo "Install starship"

    cd ~/ || exit 1
    if [ ! "$(brew install starship)" ]; then
    curl -sS https://starship.rs/install.sh | sh
    fi
    ln -s "$(pwd)"/starship.toml ~/.config/starship.toml
}

# check to os and execute os specific stepts
if echo "$os" | grep -q "darwin"; then
    echo "Detect MacOS as OS"
    on_mac
fi
if echo "$os" | grep -q "linux"; then
    echo "Detect linux distro as OS"
    on_linux
fi
if echo "$os" | grep -q ""; then
    echo "Detect Windows as OS"
    on_windows
fi

# add starship to default rc files
if [ -f .zshrc ]; then
    echo "Add starship to .zshrc"
    echo "eval \"$(starship init zsh)\"" >> .zshrc
fi

if [ -f .bashrc ]; then
    echo "Add starship to .bashrc"
    echo "eval \"$(starship init bash)\"" >> .bashrc
fi

if [ -f .config/fish/config.fish ]; then
    echo "Add starship to .config/fish"
    echo "starship init fish | source" >> .config/fish/config.fish
fi
