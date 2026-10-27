# Last-loaded module: plugins, prompt, hooks.
#
# Order inside this file matters:
#   1. widgets/completions plugins (autosuggestions),
#   2. the prompt,
#   3. zsh-syntax-highlighting, which must be sourced last of everything,
#   4. hooks, which only register callbacks.

# --- zsh plugins from Homebrew -------------------------------------------------
# Homebrew installs autosuggestions to share/zsh-autosuggestions and
# syntax-highlighting to share/zsh-syntax-highlighting (its own Makefile sets
# SHARE_DIR=$(PREFIX)/share/$NAME). Guarded because a partially-installed
# Homebrew must not abort the shell.
_brew_share="${HOMEBREW_PREFIX:-/opt/homebrew}/share"

if [[ -r "$_brew_share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$_brew_share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# --- prompt -------------------------------------------------------------------
# Without this starship is not initialised at all: the binary is on PATH but
# nothing emits a prompt from it.
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# zsh-syntax-highlighting goes LAST: it wraps the line editor's widgets, so
# anything defining widgets after it would render unhighlighted.
if [[ -r "$_brew_share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$_brew_share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
unset _brew_share

# --- hooks --------------------------------------------------------------------
# Node follows .nvmrc on every directory change, and once at startup so a shell
# opened inside a project starts on the right version.
autoload -U add-zsh-hook
if (( $+functions[load-nvmrc] )); then
    add-zsh-hook chpwd load-nvmrc
    load-nvmrc
fi
