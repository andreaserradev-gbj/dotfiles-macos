# Tool initialisation that needs an interactive shell.

# zoxide — `z dir` jumps to the most-used matching directory. `--cmd cd` would
# steal `cd`; leave the default `z` and alias `cdz` in 30-aliases.zsh instead.
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# fzf — key bindings (Ctrl-R history, Ctrl-T files, Alt-C cd) and fuzzy
# completion for **<TAB>. `fzf --zsh` is the supported entry point since 0.48;
# it supersedes sourcing shell/key-bindings.zsh by hand.
if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
fi
