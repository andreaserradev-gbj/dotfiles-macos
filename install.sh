#!/bin/bash
# install.sh — install the fundamental tooling (Brewfile) and stow every
# package in this repo into $HOME.
#
#   ./install.sh            # brew bundle, back up conflicts, stow
#   ./install.sh --no-brew  # stow only (brew not installed / already done)
#   ./install.sh --dry-run  # print what would happen, change nothing
#
# Package layout is GNU Stow's: <package>/.config/<app>/... becomes
# ~/.config/<app>/... . Nothing is copied — every file in $HOME is a symlink
# into this checkout, so `git pull` is the update mechanism.
set -e

DOTFILES_DIR=$(cd "$(dirname "$0")" && pwd)
# The package list lives in ./packages, shared with preflight-macos.sh.
# Plain while-read, not mapfile: /bin/bash on macOS is 3.2.
PACKAGES=()
while IFS= read -r line; do
    line=${line%%#*}
    line=${line//[[:space:]]/}
    [ -z "$line" ] && continue
    if [ ! -d "$DOTFILES_DIR/$line" ]; then
        echo "!! packages lists '$line' but there is no such directory" >&2
        exit 1
    fi
    PACKAGES+=("$line")
done < "$DOTFILES_DIR/packages"

DO_BREW=1
DRY_RUN=0

for arg in "$@"; do
    case "$arg" in
        --no-brew) DO_BREW=0 ;;
        --dry-run) DO_BREW=0; DRY_RUN=1 ;;
        *)
            echo "!! Unknown argument: $arg" >&2
            echo "   Usage: $0 [--no-brew] [--dry-run]" >&2
            exit 1
            ;;
    esac
done

# --- 1. tooling -------------------------------------------------------------
if [ "$DO_BREW" -eq 1 ]; then
    if ! xcode-select -p >/dev/null 2>&1; then
        echo "!! Xcode command line tools missing. Run: xcode-select --install" >&2
        exit 1
    fi
    if ! command -v brew >/dev/null 2>&1; then
        echo "!! Homebrew not found. Install it first: https://brew.sh" >&2
        exit 1
    fi
    echo ">>> brew bundle"
    brew bundle --file "$DOTFILES_DIR/Brewfile"
fi

if ! command -v stow >/dev/null 2>&1; then
    echo "!! stow not found — run without --no-brew, or: brew install stow" >&2
    exit 1
fi

# --- 2. back up conflicting real files --------------------------------------
# Stow refuses to overwrite an existing regular file, and on a machine that
# already has dotfiles that is the normal case. Move those aside first.
#
# Two rules keep this from eating its own work:
#
#   * Only a REGULAR FILE counts as a conflict. `[ -e ]` is also true for a
#     symlink pointing into this repo — the state a previous run leaves behind
#     — and for a directory symlink stow created by folding. Backing those up
#     would move files out of the repo through the link.
#   * The scan walks the PACKAGE tree, which lives in this repo and is never a
#     symlink, so `find` cannot traverse into $HOME and loop back.
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
conflicts=()
for pkg in "${PACKAGES[@]}"; do
    while IFS= read -r -d '' src; do
        rel=${src#"$DOTFILES_DIR/$pkg/"}
        dst="$HOME/$rel"
        # -f is false for symlinks (even dangling ones) and for directories,
        # which is exactly the set stow will not clobber by itself.
        if [ -f "$dst" ] && [ ! -L "$dst" ]; then
            conflicts+=("$dst")
        fi
    done < <(find "$DOTFILES_DIR/$pkg" -type f -print0)
done

if [ ${#conflicts[@]} -gt 0 ]; then
    echo ">>> backing up ${#conflicts[@]} conflicting file(s) to $BACKUP_DIR"
    for dst in "${conflicts[@]}"; do
        rel=${dst#"$HOME/"}
        echo "    $dst"
        if [ "$DRY_RUN" -eq 0 ]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
            mv "$dst" "$BACKUP_DIR/$rel"
        fi
    done
fi

# --- 3. stow ----------------------------------------------------------------
# -R restows: delete then stow, so a file deleted from the repo disappears from
# $HOME instead of leaving a dangling symlink.
#
# --no-folding is REQUIRED, not cosmetic. By default stow folds a whole tree
# into one directory symlink: ~/.config/herdr would become a link to this repo.
# Several of these apps keep mutable state in their config dir — herdr writes
# session.json and its socket there, lazygit writes state.yml — so folding would
# make them write into the checkout. Per-file links keep state in $HOME.
#
# --no-folding also makes every run idempotent: with folding, run 1 creates the
# directory link and run 2 has to split it open again, which is where stow's
# "(reverts previous action)" noise comes from.
STOW_OPTS=(-R -v --no-folding -t "$HOME")
[ "$DRY_RUN" -eq 1 ] && STOW_OPTS+=(--simulate)

echo ">>> stow ${PACKAGES[*]}"
cd "$DOTFILES_DIR"
stow "${STOW_OPTS[@]}" "${PACKAGES[@]}"

# --- 4. Claude Code status line ---------------------------------------------
# ~/.claude/settings.json is NOT stowed: Claude Code rewrites it (theme, model,
# permissions), and a symlink would turn every one of those writes into a diff
# in this repo. Instead, merge the one key the `claude` package needs.
#
# Only adds statusLine when the key is ABSENT, so a hand-tuned status line is
# never overwritten and re-running is a no-op. Claude Code itself is not
# required: the file is created if missing and read on its first launch.
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
STATUSLINE='{"type": "command", "command": "~/.claude/statusline.sh", "padding": 0}'

if ! command -v jq >/dev/null 2>&1; then
    echo "!! jq not found — skipping statusLine merge into $CLAUDE_SETTINGS" >&2
elif [ -f "$CLAUDE_SETTINGS" ] && ! jq -e . "$CLAUDE_SETTINGS" >/dev/null 2>&1; then
    echo "!! $CLAUDE_SETTINGS is not valid JSON — leaving it alone" >&2
elif [ -f "$CLAUDE_SETTINGS" ] && jq -e 'has("statusLine")' "$CLAUDE_SETTINGS" >/dev/null; then
    echo ">>> claude: statusLine already set in $CLAUDE_SETTINGS, leaving it"
else
    echo ">>> claude: adding statusLine to $CLAUDE_SETTINGS"
    if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
        [ -f "$CLAUDE_SETTINGS" ] || echo '{}' > "$CLAUDE_SETTINGS"
        # jq cannot edit in place. Write to a temp file, then `cat >` it back
        # so the original keeps its inode and permissions (0600 if Claude
        # Code created it) instead of inheriting mktemp's.
        tmp=$(mktemp "$CLAUDE_SETTINGS.XXXXXX")
        jq --argjson sl "$STATUSLINE" '. + {statusLine: $sl}' "$CLAUDE_SETTINGS" > "$tmp"
        cat "$tmp" > "$CLAUDE_SETTINGS"
        rm -f "$tmp"
    fi
fi

echo
if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run: nothing was changed."
else
    echo "Done. Open a new terminal (or: exec zsh -l)."
fi
