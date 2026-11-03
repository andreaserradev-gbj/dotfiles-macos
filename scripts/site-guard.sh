#!/bin/bash
# site-guard.sh — refuse commits that would publish site-specific names.
#
# This repo is public. Names of employers, internal hosts, account ids and
# work email addresses must never reach it. The names themselves cannot live
# here either, so they come from a PRIVATE pattern file outside the repo
# (the same one scripts/preflight-macos.sh reads):
#
#   ${SITE_PATTERNS_FILE:-~/.config/dotfiles-macos/site-patterns}
#   one case-insensitive extended regex per line, # comments allowed
#
# Install once per clone (hooks are never committed, so a fresh clone has none):
#
#   ln -sf ../../scripts/site-guard.sh .git/hooks/pre-commit
#   ln -sf ../../scripts/site-guard.sh .git/hooks/commit-msg
#
# As pre-commit (no args) it checks the author identity and every staged
# added line and file name. As commit-msg ($1 = message file) it checks the
# message. Bypass deliberately with `git commit --no-verify`.
set -u

PATTERNS="${SITE_PATTERNS_FILE:-$HOME/.config/dotfiles-macos/site-patterns}"
if [ ! -f "$PATTERNS" ]; then
    echo "site-guard: no pattern file at $PATTERNS — nothing to check" >&2
    exit 0
fi

# What could be published by this commit.
if [ $# -ge 1 ]; then
    stage="commit message"
    # Drop git's own "# ..." help lines; they are not part of the message.
    subject=$(grep -v '^#' "$1")
else
    stage="staged changes"
    subject=$(
        git var GIT_AUTHOR_IDENT
        git var GIT_COMMITTER_IDENT
        git diff --cached --name-only
        git diff --cached -U0 --no-color | grep '^+' | grep -v '^+++ '
    )
fi

fail=0
while IFS= read -r pat; do
    case "$pat" in ''|'#'*) continue ;; esac
    hits=$(printf '%s\n' "$subject" | grep -iE -- "$pat" | head -3)
    if [ -n "$hits" ]; then
        fail=1
        echo "site-guard: pattern '$pat' found in $stage:" >&2
        printf '%s\n' "$hits" | cut -c1-160 | sed 's/^/    /' >&2
    fi
done < "$PATTERNS"

if [ "$fail" -ne 0 ]; then
    echo "site-guard: commit refused — this repo is public." >&2
    echo "  Move site-specific config to a local, non-stowed file instead." >&2
    echo "  Identity: git config user.email <your noreply address>" >&2
    exit 1
fi
exit 0
