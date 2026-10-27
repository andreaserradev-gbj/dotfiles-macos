# Shell functions.

# fcd — cd into a directory picked with fzf, then list it.
fcd() {
    local dir
    dir=$(find . -type d -not -path '*/.*' | fzf) || return
    cd "$dir" && l
}

# fv — open a file picked with fzf.
fv() {
    local file
    file=$(find . -type f -not -path '*/.*' | fzf) || return
    nvim "$file"
}

# f — copy a picked file's path to the macOS clipboard.
f() {
    find . -type f -not -path '*/.*' | fzf | pbcopy
}

# fh — copy a picked history entry to the macOS clipboard.
fh() {
    history | fzf | pbcopy
}

# load-nvmrc — switch Node to the version in .nvmrc while walking the tree.
# Installs the version on first sight. Without the chpwd hook in 90-final.zsh
# this does nothing, so it is called explicitly once at shell start too.
load-nvmrc() {
    command -v nvm >/dev/null 2>&1 || return
    local nvmrc_path node_version
    nvmrc_path=$(nvm_find_nvmrc)
    if [[ -n $nvmrc_path ]]; then
        node_version=$(nvm version "$(<"$nvmrc_path")")
        if [[ $node_version == 'N/A' ]]; then
            nvm install
        elif [[ $node_version != "$(nvm version)" ]]; then
            nvm use
        fi
    elif [[ $(nvm version) != "$(nvm version default)" ]]; then
        nvm use default >/dev/null
    fi
}
