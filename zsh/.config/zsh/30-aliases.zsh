# Aliases.
#
# Deliberately no yabai/skhd/process-compose/ngrok aliases: those were tied to
# one machine's macOS workflow and a local service stack, and neither belongs in
# a generic laptop config.

alias nv='nvim'
alias lz='lazygit'
alias hd='herdr'
alias cls='clear && fastfetch'

# eza — `l` for everyday listing, `lg*` for git-aware trees, `ll` for the
# long form with sizes.
alias l='eza --icons'
alias lg='eza --tree --level=1 --icons --git --git-ignore'
alias lg2='eza --tree --level=2 --icons --git --git-ignore'
alias lg3='eza --tree --level=3 --icons --git --git-ignore'
alias ll='eza -lg --icons'

# bat as a pager-friendly cat. --paging=never because the terminal already
# scrolls, and the theme resolves from bat's own config.
alias cat='bat --paging=never'

# zoxide under the name actually typed; the bare `z` stays for muscle memory
# in scripts.
if command -v zoxide >/dev/null 2>&1; then
    alias cdz='z'
fi
