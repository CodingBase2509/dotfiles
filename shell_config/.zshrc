eval "$(starship init zsh)"

# source files
source ~/.dotfiles/shell_config/git_alias.sh

# alias
alias _='sudo '
alias ..='cd .. '
alias ...='cd ../.. '
alias ....='cd ../../.. '

alias ls='gls --color=auto '
alias l='ls '
alias ll='ls -la '
alias grep='grep --color=auto '

export LS_COLORS='di=36:fi=1;37:ln=35:ex=31:or=33:mi=33:bd=45:cd=44:so=38;41'

alias vi='nvim '
alias vim='nvim '
alias c='code'
alias c.='code .'
alias cat='bat'

# environment variables
export ICLOUD='~/Library/Mobile Documents/com~apple~CloudDocs'

# configuration to use the gnu flavoured commands (Linux)
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export MANPATH="/opt/homebrew/opt/coreutils/libexec/gnuman:${MANPATH}"
