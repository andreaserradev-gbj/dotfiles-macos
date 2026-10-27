# Completions.
#
# compinit is run once, here, before anything that defines a completion
# function: the brew plugins sourced later in 90-final.zsh call compdef, which
# requires it.
#
# FLAGS: `-i` ignores insecure directories (any group-writable dir on fpath,
# normal under a Homebrew prefix) instead of stopping to ask — otherwise a
# non-interactive shell hangs on the prompt. `-d <file>` puts the dump in the
# cache dir: the default is ~/.zcompdump in $HOME, and a stale dump there
# silently hides completions added by a Homebrew upgrade.
#
# NOTE: there is no `-U` flag. compinit's option loop accepts only
# -d -D -i -u -C -w; an unknown letter silently ENDS the loop, so `compinit -U
# -d file` ignores the dumpfile and writes ~/.zcompdump. Do not add -U.
mkdir -p "$XDG_CACHE_HOME/zsh"
autoload -Uz compinit
compinit -i -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Case-insensitive, substring matching in the completion menu.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select

# nvm's completion is a BASH function (`complete -o default -F __nvm nvm`),
# and Homebrew installs it under the keg's etc/bash_completion.d/ — a path zsh
# never reads. Nothing else loads it: nvm.sh defines only nvm itself, which is
# why `nvm <TAB>` completes filenames without this block. The file boots
# bashcompinit itself, but compinit must already have run, which it has above.
if [[ -r "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ]]; then
    source "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
fi
