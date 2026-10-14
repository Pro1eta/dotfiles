# .zprofile - login shell (zsh). Runs once per login (tty/SSH).
# Loads the shared login environment, then sets zsh-specific state.

# 1. login environment (single POSIX source, shared by any login shell)
[ -f "${HOME}/.config/shell/profile.sh" ] && . "${HOME}/.config/shell/profile.sh"

# 2. zsh history location (XDG) - exported here, not in .zshrc
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
[ -d "$XDG_CACHE_HOME/zsh" ] || mkdir -p "$XDG_CACHE_HOME/zsh"
[ -d "$XDG_STATE_HOME/zsh" ] || mkdir -p "$XDG_STATE_HOME/zsh"
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTORY_IGNORE="(cd|cd -|cd ..|pwd|ls|exit|)"
