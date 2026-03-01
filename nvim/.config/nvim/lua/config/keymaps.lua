-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- Ny rad under, stanna i normal mode
-- vim.keymap.set("n", "ö", "o<Esc>", { silent = true, desc = "New line below (stay in normal)" })

-- Ny rad över, stanna i normal mode
-- vim.keymap.set("n", "Ö", "O<Esc>", { silent = true, desc = "New line above (stay in normal)" })

-- Exit insert mode med jk
vim.keymap.set("i", "jk", "<Esc>", { silent = true, desc = "Exit insert mode" })
vim.keymap.set("i", "<Esc>", "<Nop>", { silent = true, desc = "Disable Esc in insert mode" })

-- Navigate git hunks with H and L
vim.keymap.set("n", "H", "[h", { remap = true, desc = "Previous git hunk" })
vim.keymap.set("n", "L", "]h", { remap = true, desc = "Next git hunk" })

-- vim.keymap.set("n", "<C-u>", "<C-u>zz", { remap = true, desc = "Half page up, center cursor" })
-- vim.keymap.set("n", "<C-d>", "<C-d>zz", { remap = true, desc = "Half page down, center cursor" })
