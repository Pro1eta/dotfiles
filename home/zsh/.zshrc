# .zshrc - interactive shell loader. No feature logic here.
# Features live in ~/.config/zsh/<module>.zsh (see loader below).

case $- in # only run for interactive shells
    *i*) ;;
      *) return;;
esac

ZDOT="${HOME}/.config/zsh"

# load order matters: each module may depend on previous ones
# NOTE: don't name this array "modules" - that is a read-only special param
zsh_modules=(options history completion functions keybindings prompt aliases plugins)
for m in $zsh_modules; do
    [ -f "$ZDOT/$m.zsh" ] && source "$ZDOT/$m.zsh"
done

# custom completions (need compinit from completion.zsh first)
# (N) = no error when the dir has no *.zsh yet
for f in "$ZDOT"/completions/*.zsh(N); do
    [ -f "$f" ] && source "$f"
done
