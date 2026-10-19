# Listing, searching and reading files
if command -v grep >/dev/null 2>&1 && printf 'test\n' | command grep --color=auto test >/dev/null 2>&1; then
    alias grep='grep --color=auto '
fi

if command -v bat >/dev/null 2>&1; then
    alias cat='bat'
elif command -v batcat >/dev/null 2>&1; then
    alias cat='batcat'
fi
