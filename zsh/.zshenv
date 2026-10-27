# Homebrew on PATH for every zsh, login or not.
#
# brew's own instructions put this line in ~/.zprofile, which login shells
# read. Non-login shells (scripts, editors, `zsh -c`) would then miss brew's
# bin, so `herdr`, `bat` and friends vanish under them. .zshenv is read by
# every zsh, and `brew shellenv` is idempotent and cheap, so it lives here.
#
# Both prefixes are checked: /opt/homebrew is Apple Silicon, /usr/local is
# Intel.
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
