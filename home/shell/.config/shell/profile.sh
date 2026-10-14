# profile.sh - login environment (POSIX sh; sourced by any login shell)
# Only `export` and POSIX-safe syntax here - no zsh/bash-only features.

export EDITOR="${EDITOR:-nvim}"
export PAGER="${PAGER:-less}"

# ~/.local/bin before system PATH
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# XDG base dirs (defaults match the XDG spec when unset)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
