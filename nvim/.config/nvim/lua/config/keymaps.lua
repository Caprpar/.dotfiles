-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- Ny rad under, stanna i normal mode
vim.keymap.set("n", "ö", "o<Esc>", { silent = true, desc = "New line below (stay in normal)" })

-- Ny rad över, stanna i normal mode
vim.keymap.set("n", "Ö", "O<Esc>", { silent = true, desc = "New line above (stay in normal)" })
