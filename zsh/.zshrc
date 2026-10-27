# Interactive zsh entry point.
#
# Every module lives in ~/.config/zsh/ and is sourced in filename order, so the
# numeric prefixes ARE the load order. Add a file, don't append here.
#
# No framework: oh-my-zsh would own $ZSH, install itself over the network and
# take over compinit. The two plugins this config actually wants
# (autosuggestions, syntax-highlighting) are Homebrew packages sourced from
# 90-final.zsh.
for _module in "$HOME/.config/zsh"/*.zsh; do
    [[ -r $_module ]] && source "$_module"
done
unset _module
