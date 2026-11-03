# CLAUDE.md

Personal macOS dotfiles, stowed with GNU Stow. **The repo is public.**

## Never commit site-specific information

No employer or client names, internal hosts or URLs, cloud account ids, registry
tokens, work email addresses, or home-directory paths. This applies to file
contents, file names, commit messages and the commit author.

When a change needs site-specific config, split it:

- the generic part (a tool, a portable setting) goes in the repo;
- the site part goes in a local, non-stowed file — for zsh, a regular file in
  `~/.config/zsh/` such as `45-<site>-<topic>.zsh`; for git identity,
  `~/.config/git/config` — and is recorded in `CLAUDE.local.md`, not here.

Commit with this repo's own identity (`git config user.email` set locally to the
GitHub noreply address), never the global one. `scripts/site-guard.sh`, installed
as the pre-commit and commit-msg hooks, enforces this from a private pattern
file; do not bypass it with `--no-verify`.

## Single sources of truth

- `packages` — the stow packages; read by `install.sh` and the preflight.
- `Brewfile` — the tools; the preflight derives its checks from it. Tag a
  formula `# cmd: <command>` when its command has a different name, `# cmd: -`
  when it has none.
- `~/.claude/settings.json` is not stowed (Claude Code rewrites it);
  `install.sh` merges the `statusLine` key only when it is absent.

## Verify before committing

```sh
shellcheck install.sh scripts/*.sh claude/.claude/statusline.sh
/bin/bash ./install.sh --dry-run          # macOS /bin/bash is 3.2: no mapfile, no assoc arrays
/bin/bash scripts/preflight-macos.sh
```
