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

-- Navigate diagnostics with Left/Right
vim.keymap.set("n", "<Left>", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })
vim.keymap.set("n", "<Right>", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })

-- Cycle through unstaged files with Up/Down
local function goto_unstaged_file(direction)
  local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 or not root then
    vim.notify("Not in a git repository", vim.log.levels.WARN)
    return
  end

  local files = vim.fn.systemlist("git -C " .. vim.fn.shellescape(root) .. " diff --name-only")
  if #files == 0 then
    vim.notify("No unstaged files", vim.log.levels.INFO)
    return
  end

  local current = vim.fn.expand("%:p")
  local idx = nil
  for i, f in ipairs(files) do
    if root .. "/" .. f == current then
      idx = i
      break
    end
  end

  local next_idx
  if idx == nil then
    next_idx = 1
  else
    next_idx = ((idx - 1 + direction) % #files) + 1
  end

  vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. files[next_idx]))
end

vim.keymap.set("n", "<Down>", function()
  goto_unstaged_file(1)
end, { desc = "Next unstaged file" })
vim.keymap.set("n", "<Up>", function()
  goto_unstaged_file(-1)
end, { desc = "Previous unstaged file" })

-- Copy absolute path of current file to clipboard
vim.keymap.set("n", "cp", function()
  local path
  for _, picker in ipairs(Snacks.picker.get({ source = "explorer" })) do
    if picker:current_win() then
      local item = picker:current()
      path = item and Snacks.picker.util.path(item)
      break
    end
  end
  path = path or vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Copy absolute file path" })

vim.keymap.set("n", "<M-l>", "<C-w>5>", { desc = "Widen window" })
vim.keymap.set("n", "<M-h>", "<C-w>5<", { desc = "Narrow window" })

-- vim.keymap.set("n", "<C-u>", "<C-u>zz", { remap = true, desc = "Half page up, center cursor" })
-- vim.keymap.set("n", "<C-d>", "<C-d>zz", { remap = true, desc = "Half page down, center cursor" })
-- Räkna ord i markering och kopiera till klippbord
vim.keymap.set("v", "<leader>wc", function()
  vim.cmd('normal! "wy')
  local text = vim.fn.getreg("w")
  local count = 0
  for _ in text:gmatch("%S+") do
    count = count + 1
  end
  local count_str = tostring(count)
  vim.fn.setreg("+", count_str)
  print("Words: " .. count_str)
end, { desc = "Count words in selection" })

-- Open images with feh
vim.keymap.set("n", "gx", function()
  local path = vim.fn.expand("<cfile>")
  if
    path:match("%.png$")
    or path:match("%.jpg$")
    or path:match("%.jpeg$")
    or path:match("%.gif$")
    or path:match("%.webp$")
    or path:match("%.svg$")
    or path:match("%.bmp$")
  then
    vim.fn.jobstart({ "feh", "--auto-zoom", path }, { detach = true })
  else
    vim.ui.open(path)
  end
end, { desc = "Open file or URL (images with feh)" })

-- Yanks selected line location (good for pasting to external AI)
vim.keymap.set("v", "<leader>yl", function()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  local filepath = vim.fn.expand("%:p"):gsub("^" .. os.getenv("HOME"), "~")
  local result = filepath .. ":" .. start_line .. "-" .. end_line
  vim.fn.setreg("+", result)
  print("Yanked: " .. result)
end, { desc = "Yank file location of selection" })

-- Restarts language server
vim.keymap.set("n", "<leader>lr", function()
  vim.cmd("lsp restart")
end, { desc = "LSP restart" })

-- Toggle true/false under cursor, fallback to normal increment
vim.keymap.set("n", "<C-a>", function()
  local word = vim.fn.expand("<cword>")
  if word == "true" then
    vim.cmd("normal! ciwfalse")
  elseif word == "false" then
    vim.cmd("normal! ciwtrue")
  else
    vim.cmd("normal! \x01")
  end
end, { desc = "Toggle true/false (or increment)" })

-- OpenCode
vim.keymap.set({ "n", "x" }, "<leader>aa", function()
  require("opencode").ask("@this: ")
end, { desc = "Ask OpenCode…" })
vim.keymap.set({ "n", "x" }, "<leader>as", function()
  require("opencode").select()
end, { desc = "Select OpenCode…" })
vim.keymap.set({ "n", "x" }, "<leader>go", function()
  return require("opencode").operator("@this ")
end, { desc = "Append range to OpenCode", expr = true })
vim.keymap.set("n", "<leader>goo", function()
  return require("opencode").operator("@this ") .. "_"
end, { desc = "Append line to OpenCode", expr = true })
