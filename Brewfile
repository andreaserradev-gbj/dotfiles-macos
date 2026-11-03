# Fundamental tooling for a macOS dev machine, installed by install.sh
# (`brew bundle --file Brewfile`). Deliberately no site-specific taps and no
# host-only CLIs: everything here is a tool you would install by hand anyway.
#
# This is also the ONLY tool list: scripts/preflight-macos.sh reads it to
# report what is missing. It checks for a command named like the formula;
# when they differ, say so in the comment with `# cmd: <command>`, or
# `# cmd: -` for a formula that installs nothing to run (sourced plugins).

# --- the symlink layer -------------------------------------------------------
brew "stow"

# --- base CLI ---------------------------------------------------------------
brew "git"
brew "git-delta" # cmd: delta — pager for git and lazygit
brew "gh"
brew "jq"
brew "ripgrep" # cmd: rg — nvim pickers + fzf
brew "fd"
brew "wget"

# --- shell ------------------------------------------------------------------
brew "starship"
brew "zsh-autosuggestions"     # cmd: - (sourced, no binary)
brew "zsh-syntax-highlighting" # cmd: - (sourced, no binary)
brew "fzf" # also installs bin/fzf-preview.sh, used by 60-fzf.zsh
brew "zoxide"
brew "eza"
brew "bat"
brew "fastfetch" # `cls` alias in 30-aliases.zsh

# --- node -------------------------------------------------------------------
# Homebrew's nvm is unsupported by upstream and only keeps installs across
# upgrades if NVM_DIR points at a stable dir; 10-environment.zsh sets
# NVM_DIR=~/.nvm for exactly that reason. (Alternative: fnm/mise, but nvm is
# what this config's .nvmrc hook expects.)
brew "nvm" # cmd: nvm — a shell function; preflight checks nvm.sh by path

# --- python -----------------------------------------------------------------
brew "uv" # also provides uvx

# --- containers -------------------------------------------------------------
# Colima runs the Docker engine in a Lima VM; the docker CLI is the client.
# Not stowed: ~/.docker/config.json (docker login and colima write to it).
# Create it once so the CLI finds the brew plugins and keeps logins in the
# keychain:
#   { "cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"],
#     "credsStore": "osxkeychain" }
# Start the VM: colima start --vm-type vz --vz-rosetta --cpu 4 --memory 8
brew "colima"
brew "docker"
brew "docker-compose"
brew "docker-buildx"
brew "docker-credential-helper" # cmd: docker-credential-osxkeychain

# --- editor and terminal ----------------------------------------------------
brew "neovim" # cmd: nvim
brew "tree-sitter-cli" # cmd: tree-sitter — nvim-treesitter needs the CLI on 0.12+
brew "gcc"             # nvim-treesitter builds parsers at runtime
brew "lazygit"
brew "herdr"

# Formatters, resolved from PATH by conform.nvim.
brew "prettier"
brew "stylua"
brew "shfmt"
brew "shellcheck" # linter; CI runs it on every script

# LSP servers, resolved from PATH because nvim ships with Mason disabled
# (lua/plugins/lsp.lua). Every name here is a launcher nvim-lspconfig probes:
#   bashls -> bash-language-server, cssls/htmlls/jsonls ->
#   vscode-langservers-extracted, yamlls -> yaml-language-server,
#   lua_ls -> lua-language-server, marksman, vtsls (owns its own node).
brew "bash-language-server"
brew "vscode-langservers-extracted" # cmd: vscode-json-language-server
brew "yaml-language-server"
brew "lua-language-server"
brew "marksman"
brew "vtsls"

cask "ghostty"
cask "font-jetbrains-mono-nerd-font"
