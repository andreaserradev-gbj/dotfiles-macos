# Tool initialisation that must not depend on interactive-only state.

# nvm — version manager for Node. Sourced from Homebrew's keg: the formula
# ships nvm.sh under opt/nvm, and its caveat is explicit that Homebrew's copy is
# unsupported upstream, which is why this is a plain source rather than
# `nvm`-managed shell integration.
if [[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]]; then
    source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
fi
