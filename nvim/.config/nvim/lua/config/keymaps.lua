-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "<C-a>", "<Home>")
vim.keymap.set("i", "<C-b>", "<Left>")
vim.keymap.set("i", "<C-d>", "<Delete>")
vim.keymap.set("i", "<C-e>", "<End>")
vim.keymap.set("i", "<C-f>", "<Right>")
vim.keymap.set("i", "<C-n>", "<Down>")
vim.keymap.set("i", "<C-p>", "<Up>")
vim.keymap.set("i", "<C-v>", "<PageDown>")
vim.keymap.set("i", "<M-v>", "<PageUp>")

-- <C-h> and <C-w> already delete the previous character/word in Neovim.
-- Keep Emacs-style kills separate from the unnamed and clipboard registers.
vim.keymap.set("i", "<C-k>", function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]
  local line = vim.api.nvim_get_current_line()
  if col < #line then
    vim.fn.setreg("z", line:sub(col + 1), "c")
    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, #line, {})
  elseif row < vim.api.nvim_buf_line_count(0) then
    vim.fn.setreg("z", "\n", "c")
    vim.api.nvim_buf_set_text(0, row - 1, col, row, 0, {})
  end
end)
vim.keymap.set("i", "<C-y>", "<C-r><C-o>z")

-- Word boundaries follow Neovim's 'iskeyword' option.
local function word_boundary(backward)
  local match = vim.fn.searchpos(backward and [[\<]] or [[\k\>]], backward and "bnW" or "ncW")
  if match[1] == 0 then
    if backward then
      return { 1, 0 }
    end
    local last = vim.api.nvim_buf_line_count(0)
    local line = vim.api.nvim_buf_get_lines(0, last - 1, last, false)[1]
    return { last, #line }
  end
  if backward then
    return { match[1], match[2] - 1 }
  end
  local line = vim.api.nvim_buf_get_lines(0, match[1] - 1, match[1], false)[1]
  local char = vim.fn.matchstr(line:sub(match[2]), "^.")
  return { match[1], match[2] - 1 + #char }
end

vim.keymap.set("i", "<M-b>", function()
  vim.api.nvim_win_set_cursor(0, word_boundary(true))
end)
vim.keymap.set("i", "<M-f>", function()
  vim.api.nvim_win_set_cursor(0, word_boundary(false))
end)

local function kill_word(backward)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local target = word_boundary(backward)
  local first, last = cursor, target
  if backward then
    first, last = target, cursor
  end
  if first[1] == last[1] and first[2] == last[2] then
    return
  end
  local text = vim.api.nvim_buf_get_text(0, first[1] - 1, first[2], last[1] - 1, last[2], {})
  vim.fn.setreg("z", table.concat(text, "\n"), "c")
  vim.api.nvim_buf_set_text(0, first[1] - 1, first[2], last[1] - 1, last[2], {})
  if backward then
    vim.api.nvim_win_set_cursor(0, target)
  end
end

vim.keymap.set("i", "<M-d>", function()
  kill_word(false)
end)
vim.keymap.set("i", "<M-BS>", function()
  kill_word(true)
end)
