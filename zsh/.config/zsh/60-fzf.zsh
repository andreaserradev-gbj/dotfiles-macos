# fzf appearance.
#
# The bindings themselves come from `fzf --zsh` in 25-integrations.zsh; this
# file only styles the picker so every fzf invocation (Ctrl-R, Ctrl-T, the
# functions in 40-functions.zsh) looks the same.
#
# fzf-preview.sh ships with Homebrew's fzf formula and previews files with bat,
# which is why the bat theme matters here too.
export FZF_DEFAULT_OPTS='
    --height=60%
    --layout=reverse
    --border=rounded
    --info=inline
    --preview="fzf-preview.sh {}"
    --preview-window="right:55%:wrap"
    --bind="ctrl-/:toggle-preview"
    --color="fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8,fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8"
    --color="info:#cba6f7,prompt:#89b4fa,pointer:#f5e0dc,marker:#a6e3a1,spinner:#f5e0dc,header:#a6e3a1"
    --color="border:#585b70,label:#cba6f7,query:#cdd6f4"
'
