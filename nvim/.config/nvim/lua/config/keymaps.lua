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

// <C-h> and <C-w> already delete the previous character/word in Neovim.
// Keep Emacs-style kills separate from the unnamed and clipboard registers.
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
