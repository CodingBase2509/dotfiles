# Git
if ! command -v git >/dev/null 2>&1; then return 0; fi

alias g='git '
alias gst='git status '
alias gi='git init'
alias gc='git clone'
alias gcs='git clone --recurse-submodules'

alias gcho='git checkout '
alias gchb='git checkout -b '
alias gchdev='git checkout develop'
alias gchm='git checkout master '

alias gb='git branch '
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gbsu='git branch --set-upstream-to=origin/$(git symbolic-ref --short HEAD)'

alias gl='git pull'
alias glf='git pull --force'
alias glo='git pull origin $(git symbolic-ref --short HEAD)'
alias gp='git push'
alias gpf='git push --force'
alias gpo='git push origin $(git symbolic-ref --short HEAD)'
alias gf='git fetch --all --prune'
alias gcmsg='git commit -m'

alias gstsh='git stash '
alias gstp='git stash pop '
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'

alias ga='git add '
alias gaa='git add --all '
alias grm='git rm'
alias grmc='git rm --cached'

alias glog='git log'
alias gm='git merge'
alias grb='git rebase'

alias gr='git remote'
alias gra='git remote add'
