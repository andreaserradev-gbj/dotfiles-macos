# dotfiles-macos

> **For my personal use, published as a learning reference.** These are the
> dotfiles for my own Mac; the repo exists so the setup is reproducible and so
> others can read it, compare ideas, or fork it for their own machines. It is
> **not** a community project: I don't provide support, and **PRs will not be
> accepted** — every change is verified against my own hardware first, so
> anything merged here has to be something I can run. If it helped you, take
> what you need: the [license is MIT](#license) and stripping it down to your
> machines is the intended use.

Minimal macOS dotfiles, stowed with GNU Stow. The point is a working terminal,
editor and shell on a fresh Mac in one command, with no package-manager
framework and nothing site-specific baked in.

Ported from my NixOS config (`dotfiles-nix`) and an older Stow repo, keeping only
what is portable: the Neovim/LazyVim tree, starship, bat, and the herdr keymap
are copied from `dotfiles-nix` where they were already plain files.

## Install

```sh
git clone <this repo> ~/code/dotfiles-macos
cd ~/code/dotfiles-macos
./scripts/preflight-macos.sh   # read-only audit of the machine first
./install.sh                   # brew bundle, back up conflicts, stow everything
```

`./install.sh --dry-run` prints what would be stowed without touching anything;
`--no-brew` skips the Homebrew step when the tooling is already installed.

Stow is the update mechanism: every file in `$HOME` is a symlink into this
checkout, so `git pull` is the whole update. `install.sh` uses `stow -R`, which
also removes links for files deleted from the repo. `--no-folding` keeps
per-file links so apps that keep mutable state in their config dir (herdr's
`session.json`, lazygit's `state.yml`) write to `$HOME`, not into the checkout.

`preflight-macos.sh` changes nothing and reports: login shell, brew prefix,
every Brewfile tool that is missing, Ghostty/font state, XDG variables, existing
files that `install.sh` would back up, and any site-specific references still in
shell/git/gh config.

## What is in here

| package | lands at | notes |
| --- | --- | --- |
| `zsh` | `~/.zshenv`, `~/.zshrc`, `~/.config/zsh/*.zsh` | no framework; numbered modules are sourced in order |
| `ghostty` | `~/.config/ghostty/config` | Ghostty reads the XDG path on macOS too |
| `herdr` | `~/.config/herdr/config.toml` | keymap mirrors the zellij layout I had |
| `starship` | `~/.config/starship/starship.toml` | |
| `bat` | `~/.config/bat/{config,themes/}` | Catppuccin Mocha theme, also used by delta |
| `lazygit` | `~/.config/lazygit/config.yml` | delta as diff renderer |
| `gitconfig` | `~/.gitconfig` | **no `user.email`** — see below |
| `git` | `~/.config/git/ignore` | global ignore |
| `nvim` | `~/.config/nvim` | LazyVim; plugins bootstrap themselves on first launch |

Tooling comes from the `Brewfile`: stow, git/delta/gh/jq/ripgrep/fd/wget,
starship, fzf, zoxide, eza, bat, fastfetch, nvm, neovim, tree-sitter-cli,
lazygit, herdr, the formatters and LSP servers Neovim expects on `PATH`, plus
the Ghostty and JetBrains Mono Nerd Font casks.

## Decisions worth knowing

**No oh-my-zsh.** It owns `$ZSH`, installs itself over the network and takes over
`compinit`. The two plugins actually used (autosuggestions,
syntax-highlighting) are Homebrew formulae sourced from `90-final.zsh`, so the
whole shell is bytes in this repo.

**No `user.email` in `.gitconfig`.** The address to commit with is a per-site
decision, and hardcoding one in a shared dotfiles repo is how commits end up
attributed to the wrong identity. Set it once, override per repo:

```sh
git config --global user.name "Your Name"
git config user.email "you@example.com"        # per repo, when it differs
```

**Neovim uses Homebrew for LSP servers, not Mason.** `lua/plugins/lsp.lua`
disables Mason so LazyVim resolves every server from `$PATH`. That is why the
`Brewfile` lists the language servers explicitly: one install tree, upgraded by
`brew upgrade`, nothing invisible. `lazyvim.json` still enables the `nix` extra;
it is inert unless you open a `.nix` file and no Nix LSP is installed here.

**lazygit's key is `git.diffRenderers`.** lazygit 0.64 renamed it from
`git.pagers` and newer versions reject the stale name. After a major upgrade,
re-check `lazygit --version` and the schema before assuming the config still
loads.

**nvm from Homebrew** is unsupported upstream, and its own caveat says installs
are destroyed on upgrade unless `NVM_DIR` points somewhere stable.
`10-environment.zsh` sets `NVM_DIR=~/.nvm` for that reason. Alternative: `fnm` or
`mise` — but the `.nvmrc` hook in `40-functions.zsh` is written against nvm.

## Verifying a fresh install

`-i` matters: `.zshrc` is only read by interactive shells, so `zsh -l -c` would
report every alias as missing.

```sh
zsh -i -l -c 'echo $EDITOR; whence -w lg hd nv'      # env + aliases
zsh -i -l -c 'echo ${+functions[load-nvmrc]}'        # 1 = function loaded
ghostty +validate-config                             # parses (silent, exit 0)
herdr config check                                   # prints "config: ok"
bat --list-themes | grep -i catppuccin               # bat theme visible
starship prompt                                      # prompt renders
git config --get core.pager                          # delta
```

CI runs `shellcheck` and `stylua --check`, verifies every `Brewfile` name exists
on Homebrew, and executes both scripts under bash 3.2 (what `/bin/bash` is on
macOS). Locally:

```sh
shellcheck install.sh scripts/*.sh
stylua --check nvim/.config/nvim
```

## Not included on purpose

- Window management (`yabai`, `skhd`, `sketchybar`): machine-specific macOS
  workflow, and they require SIP partially disabled.
- Host-specific service stacks: envchain namespaces, vendor CLIs, `ngrok`, AWS
  tooling.
- `secrets/`, `~/.ssh`, `~/.config/gh`: credentials never live in a dotfiles
  repo. Run `gh auth login` and let it write its own state.
- Agent harnesses (omp/claude/codex): which one you run depends on the site;
  add the config package when that is known.

## License

[MIT](LICENSE). Fork it, strip it to your own machines, reuse the parts that
fit — that is the intended use. This repo is maintained for my own hardware
only; see the notice at the top regarding contributions and support.
