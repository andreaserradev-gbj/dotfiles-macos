# Fundamental tooling for a macOS dev machine, installed by install.sh
# (`brew bundle --file Brewfile`). Deliberately no site-specific taps and no
# host-only CLIs: everything here is a tool you would install by hand anyway.

# --- the symlink layer -------------------------------------------------------
brew "stow"

# --- base CLI ---------------------------------------------------------------
brew "git"
brew "git-delta" # pager for git and lazygit
brew "gh"
brew "jq"
brew "ripgrep" # nvim pickers + fzf
brew "fd"
brew "wget"

# --- shell ------------------------------------------------------------------
brew "starship"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
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
brew "nvm"

# --- editor and terminal ----------------------------------------------------
brew "neovim"
brew "tree-sitter-cli" # nvim-treesitter needs the CLI on 0.12+
brew "gcc"             # nvim-treesitter builds parsers at runtime
brew "lazygit"
brew "herdr"

# Formatters, resolved from PATH by conform.nvim.
brew "prettier"
brew "stylua"
brew "shfmt"

# LSP servers, resolved from PATH because nvim ships with Mason disabled
# (lua/plugins/lsp.lua). Every name here is a launcher nvim-lspconfig probes:
#   bashls -> bash-language-server, cssls/htmlls/jsonls ->
#   vscode-langservers-extracted, yamlls -> yaml-language-server,
#   lua_ls -> lua-language-server, marksman, vtsls (owns its own node).
brew "bash-language-server"
brew "vscode-langservers-extracted"
brew "yaml-language-server"
brew "lua-language-server"
brew "marksman"
brew "vtsls"

cask "ghostty"
cask "font-jetbrains-mono-nerd-font"
