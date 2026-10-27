return {
  -- LSP servers + formatters come from Homebrew (Brewfile), not Mason.
  -- Disabling Mason makes LazyVim set the servers up directly from $PATH, so
  -- the versions are whatever `brew upgrade` gives you instead of a second,
  -- invisible install tree.
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},
        cssls = {},
        html = {},
        jsonls = {},
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = "Replace" },
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
            },
          },
        },
        marksman = {},
        yamlls = {},
      },
    },
  },
}
