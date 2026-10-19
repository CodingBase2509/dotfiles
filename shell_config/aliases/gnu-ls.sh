# Homebrew exposes GNU ls as gls; Linux usually provides it as ls.
if command -v gls >/dev/null 2>&1; then
    alias ls='gls --color=auto '
    alias l='gls --color=auto '
    alias ll='gls --color=auto -la '
    export LS_COLORS='di=36:fi=1;37:ln=35:ex=31:or=33:mi=33:bd=45:cd=44:so=38;41'
elif command -v ls >/dev/null 2>&1; then
    if command ls --color=auto -d . >/dev/null 2>&1; then
        alias ls='ls --color=auto '
        export LS_COLORS='di=36:fi=1;37:ln=35:ex=31:or=33:mi=33:bd=45:cd=44:so=38;41'
    fi
    alias l='ls '
    alias ll='ls -la '
fi
