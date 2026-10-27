#!/bin/bash
# preflight-macos.sh — READ-ONLY audit of a Mac before stowing dotfiles-macos.
#
# Run it ON the Mac (it changes nothing):
#
#   ./scripts/preflight-macos.sh
#
# It answers the questions that decide whether install.sh will be smooth:
# which tools are already there, which real files would be backed up, whether
# fonts/XDG are in the state the config expects, and whether site-specific
# references or credentials are lying around that should NOT come along.
#
# Exit status: 0 always (it is a report, not a gate). Read the WARN lines.
set -u

ok()   { printf '  ok    %s\n' "$1"; }
warn() { printf '  WARN  %s\n' "$1"; }
info() { printf '  ..    %s\n' "$1"; }
# head_ accepts an optional title; "${1-}" because `set -u` rejects a bare $1.
head_() { printf '\n== %s\n' "${1-}"; }

IS_MAC=0
[ "$(uname -s)" = Darwin ] && IS_MAC=1

head_ "platform"
if [ "$IS_MAC" -eq 1 ]; then
    info "macOS $(sw_vers -productVersion) ($(uname -m))"
    case "$(uname -m)" in
        arm64) info "Apple Silicon: expect /opt/homebrew and Ghostty >= 1.2 works" ;;
        x86_64) info "Intel: expect /usr/local, brew is slower but supported" ;;
    esac
else
    info "$(uname -s) $(uname -m) — not macOS, most checks below will be skipped"
fi

head_ "shell"
info "login shell: $SHELL"
if [ "$SHELL" != "${SHELL#*zsh}" ]; then
    ok "zsh is the login shell"
else
    warn "login shell is not zsh — run: chsh -s /bin/zsh (then log out and back in)"
fi
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    info "\$HOME/.zshrc exists and is a real file (install.sh will back it up)"
fi

head_ "homebrew"
if command -v brew >/dev/null 2>&1; then
    BREW_PREFIX=$(brew --prefix)
    ok "brew at $BREW_PREFIX"
    case "$BREW_PREFIX" in
        /opt/homebrew) info "Apple Silicon prefix" ;;
        /usr/local) info "Intel prefix" ;;
    esac
    if [ -z "${HOMEBREW_PREFIX:-}" ]; then
        warn "HOMEBREW_PREFIX is not exported in this shell — .zshenv's shellenv line covers it"
    fi
else
    warn "brew not installed — install.sh will refuse to run without --no-brew"
fi

head_ "tools (Brewfile order)"
# name:command — the command is what the config actually invokes.
TOOLS="
stow:stow
git:git
git-delta:delta
gh:gh
jq:jq
ripgrep:rg
fd:fd
wget:wget
starship:starship
fzf:fzf
zoxide:zoxide
eza:eza
bat:bat
fastfetch:fastfetch
nvm:nvm
neovim:nvim
tree-sitter-cli:tree-sitter
gcc:gcc
lazygit:lazygit
herdr:herdr
prettier:prettier
stylua:stylua
shfmt:shfmt
bash-language-server:bash-language-server
vscode-langservers-extracted:vscode-json-language-server
yaml-language-server:yaml-language-server
lua-language-server:lua-language-server
marksman:marksman
vtsls:vtsls
"
missing=0
present=0
for pair in $TOOLS; do
    name=${pair%%:*}
    cmd=${pair#*:}
    if command -v "$cmd" >/dev/null 2>&1; then
        present=$((present + 1))
    elif [ "$name" = nvm ]; then
        # nvm is a shell FUNCTION from nvm.sh, not a binary, so `command -v`
        # only sees it inside a shell that sourced 20-tools.zsh. Not a missing
        # tool: the formula is checked separately, by path.
        if [ -s "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm/nvm.sh" ]; then
            present=$((present + 1))
        else
            missing=$((missing + 1))
            printf '  miss  %-28s (%s)\n' "$name" "opt/nvm/nvm.sh"
        fi
    else
        missing=$((missing + 1))
        printf '  miss  %-28s (%s)\n' "$name" "$cmd"
    fi
done
info "$present present, $missing missing"

head_ "macOS apps"
if [ "$IS_MAC" -eq 1 ]; then
    # Ghostty's config keys need >= 1.2.3 for config.ghostty naming; the
    # Brewfile cask requires macOS >= 13.
    if [ -d /Applications/Ghostty.app ]; then
        gv=$(defaults read /Applications/Ghostty.app/Contents/Info CFBundleShortVersionString 2>/dev/null)
        ok "Ghostty ${gv:-installed}"
        case "$gv" in
            1.0*|1.1*) warn "Ghostty < 1.2 reads only ~/Library/Application Support; upgrade before stowing the XDG config" ;;
        esac
    else
        info "Ghostty not installed yet (cask)"
    fi
    if system_profiler SPFontsDataType 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
        ok "JetBrainsMono Nerd Font installed"
    else
        info "JetBrainsMono Nerd Font not installed yet (cask)"
    fi
else
    info "skipped (not macOS)"
fi

head_ "XDG layout"
for v in XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME; do
    info "$v=${!v:-<unset — 10-environment.zsh sets it>}"
done
if [ -d "$HOME/Library/Application Support/herdr" ]; then
    warn "herdr state exists in ~/Library/Application Support — it reads ~/.config/herdr, so that state is orphaned"
fi
if [ -d "$HOME/Library/Application Support/com.mitchellh.ghostty" ]; then
    warn "Ghostty config in ~/Library/Application Support overrides the XDG file (loaded after it)"
    find "$HOME/Library/Application Support/com.mitchellh.ghostty" -maxdepth 1 -type f -print 2>/dev/null | sed 's/^/          /'
fi

head_ "existing dotfiles that install.sh would back up"
REPO=$(cd "$(dirname "$0")/.." && pwd)
PACKAGES="zsh ghostty herdr starship bat lazygit gitconfig git nvim"
found=0
for pkg in $PACKAGES; do
    [ -d "$REPO/$pkg" ] || continue
    while IFS= read -r -d '' src; do
        rel=${src#"$REPO/$pkg/"}
        dst="$HOME/$rel"
        if [ -f "$dst" ] && [ ! -L "$dst" ]; then
            found=$((found + 1))
            printf '  file  %s\n' "$dst"
        fi
    done < <(find "$REPO/$pkg" -type f -print0)
done
[ "$found" -eq 0 ] && ok "no conflicting real files — stow will be clean"

head_ "site-specific references and secrets (must NOT come along)"
# Two independent checks, because they come from different sources.
#
# 1. Secret-shaped strings. Site-agnostic: these prefixes are credentials
#    wherever they appear, so no configuration is needed.
secrets=0
for pat in 'ghp_[A-Za-z0-9]{20}' 'sk-[A-Za-z0-9]{20}' 'AKIA[0-9A-Z]{16}' 'BEGIN [A-Z ]*PRIVATE KEY'; do
    hits=$(grep -rIlE "$pat" "$HOME/.zshrc" "$HOME/.zsh_history" "$HOME/.config/zsh" \
            "$HOME/.gitconfig" "$HOME/.config/gh" "$HOME/.ssh" 2>/dev/null | head -5)
    if [ -n "$hits" ]; then
        secrets=1
        warn "credential-shaped string '$pat' in:"
        printf '%s\n' "$hits" | sed 's/^/          /'
    fi
done
[ "$secrets" -eq 0 ] && ok "no credential-shaped strings in shell/git/gh/ssh config"

# 2. Your own site vocabulary. There is deliberately no built-in list: names of
#    projects, hosts or vendors belong to whoever runs this, not to the repo.
#    Put one extended-regex per line in the file below (comments with #), e.g.
#        acme-corp
#        git\.acme\.internal
#        AWS_PROFILE=acme
#    Keep that file OUT of any repository.
PATTERNS="${SITE_PATTERNS_FILE:-$HOME/.config/dotfiles-macos/site-patterns}"
if [ -f "$PATTERNS" ]; then
    site=0
    while IFS= read -r pat; do
        case "$pat" in ''|'#'*) continue ;; esac
        hits=$(grep -rIliE "$pat" "$HOME/.zshrc" "$HOME/.config/zsh" "$HOME/.gitconfig" \
                "$HOME/.config/gh" 2>/dev/null | head -5)
        if [ -n "$hits" ]; then
            site=1
            warn "site pattern '$pat' in:"
            printf '%s\n' "$hits" | sed 's/^/          /'
        fi
    done < "$PATTERNS"
    [ "$site" -eq 0 ] && ok "no site-specific references matching $PATTERNS"
else
    info "no pattern file at $PATTERNS — skipping the site-vocabulary check"
    info "  create it to list names that must not travel (one regex per line)"
fi

head_ "credentials (never copy these into a dotfiles repo)"
for p in "$HOME/.ssh" "$HOME/.config/gh/hosts.yml" "$HOME/.aws" "$HOME/.config/sops/age/keys.txt"; do
    if [ -e "$p" ]; then
        info "present: $p"
    fi
done
info "re-create these on the new machine instead of copying them"

head_ "salvage candidates (exists only on this Mac, not in the repo)"
# Paths that hold decisions/state no dotfiles repo has. Presence is reported,
# never contents; copy what you still want, then wipe.
for p in \
    "$HOME/.config/wezterm" \
    "$HOME/.config/yabai" \
    "$HOME/.config/skhd" \
    "$HOME/.config/sketchybar" \
    "$HOME/.config/nvim/lazy-lock.json" \
    "$HOME/.ssh/config" \
    "$HOME/.gnupg" \
    "$HOME/.config/gh/hosts.yml" \
    "$HOME/.aws/config" \
    "$HOME/.todo" \
    "$HOME/bin" \
    "$HOME/.local/bin" \
    "$HOME/Library/Application Support/Code/User/settings.json" \
    "$HOME/Library/Application Support/Code/User/keybindings.json" \
    "$HOME/.nvm/versions/node"
do
    [ -e "$p" ] || continue
    info "present: ${p/#$HOME/\$HOME}"
done

head_ "before the machine goes"
info "Repos/scratch worth a look before the machine goes:"
info "  ~/code/*            — anything uncommitted or unpushed?"
info "  ~/Documents, ~/Desktop"
info "  shell history: ~/.zsh_history (what you actually typed is the best spec)"
info "  browser bookmarks / password manager export are NOT in this repo"

head_ "next steps"
cat <<'EOF'
  1. Decide what to keep: this report lists every tool that is missing.
  2. Anything you want to salvage from the old setup, do it now — the Mac is
     going away. Candidates not in dotfiles-macos: WezTerm config, window
     manager configs, any notes/scratch in ~/code.
  3. On the NEW Mac: clone the repo, then ./install.sh
EOF
exit 0
