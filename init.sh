#!/bin/bash
os=$OSTYPE

# check to os and execute os specific stepts
if echo "$os" | grep -q ""; then
    on_windows
fi
if echo "$os" | grep -q "darwin"; then
    on_mac
fi
if echo "$os" | grep -q "linux"; then
    on_linux
fi

# add starship to default rc files
if [ -f .zshrc ]; then
    echo "eval \"$(starship init zsh)\"" >> .zshrc
fi

if [ -f .bashrc ]; then
    echo "eval \"$(starship init bash)\"" >> .bashrc
fi

if [ -f .config/fish/config.fish ]; then
    echo "starship init fish | source" >> .config/fish/config.fish
fi

# starship install on windows
on_windows(){
    cd "C:\Users\$USER" ||exit 1
    if [ ! "$(winget install --id Starship.Starship)" ]; then
    exit 1
    fi
    echo "Invoke-Expression (&starship init powershell)" >> "$PROFILE"
}

# starship install on linux systems
on_linux(){
    curl -sS https://starship.rs/install.sh | sh
    cd ~/ || exit 1
}

# starship install on MacOS
on_mac(){
    cd ~/ || exit 1
    if [ ! "$(brew install starship)" ]; then
    curl -sS https://starship.rs/install.sh | sh
    fi
}
