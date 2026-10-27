-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.textwidth = 140

-- Over SSH there is no local clipboard tool: yanks would stay inside the remote
-- session. Make them sync over OSC 52 so `yy`/`d`/`p` reach the terminal's
-- clipboard. `clipboard=unnamedplus` is required because LazyVim leaves it empty
-- under SSH, which would otherwise keep `yy` on the unnamed register (never "+").
if vim.env.SSH_TTY then
  vim.opt.clipboard = "unnamedplus"
  local osc52 = require("vim.ui.clipboard.osc52")
  -- Most terminals block OSC 52 *reads* (a security default), so a real paste
  -- query would hang/return empty. Paste from the last yank instead; to paste
  -- FROM the local clipboard, use the terminal's own paste (Cmd+V).
  local function paste()
    return vim.split(vim.fn.getreg('"'), "\n")
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end
