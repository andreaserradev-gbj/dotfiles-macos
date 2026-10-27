# Environment variables and PATH.
#
# Loaded first: everything below assumes XDG_CONFIG_HOME and NVM_DIR exist.

# XDG layout on macOS. Without it, CLI tools split between ~/.config and
# ~/Library/Application Support depending on which path crate they use —
# lazygit, for one, only finds ~/.config/lazygit through the fallback path.
# Exported before anything reads it (60-fzf, 90-final come later).
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

export EDITOR=nvim
export VISUAL=nvim

# nvm. Homebrew's nvm keeps user-installed Node versions only while NVM_DIR
# points at a stable directory — its own caveat: leaving NVM_DIR at the celler
# path destroys every install on upgrade.
export NVM_DIR="$HOME/.nvm"

# User-local binaries, ahead of brew: scripts installed by hand or by installers
# (herdr's curl installer, `npx`-installed CLIs) land here.
export PATH="$HOME/.local/bin:$PATH"

# Keep direnv's per-directory "loading" noise out of the prompt.
export DIRENV_LOG_FORMAT=""
