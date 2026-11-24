-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.lsp.inlay_hint.enable(false)
vim.opt.swapfile = false

local osc52 = require("vim.ui.clipboard.osc52")

local function copy_both(reg)
  local to_local = osc52.copy(reg) -- hemmadatorn via terminalen
  return function(lines, regtype)
    to_local(lines, regtype)
    local cmd = vim.fn.executable("wl-copy") == 1 and { "wl-copy" } or { "xclip", "-selection", "clipboard" }
    vim.system(cmd, { stdin = table.concat(lines, "\n") }) -- kontorets clipboard
  end
end

local function paste()
  return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
end

vim.g.clipboard = {
  name = "dual-clipboard",
  copy = { ["+"] = copy_both("+"), ["*"] = copy_both("*") },
  paste = { ["+"] = paste, ["*"] = paste },
}
vim.opt.clipboard = "unnamedplus"
