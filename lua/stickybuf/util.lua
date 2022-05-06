local config = require("stickybuf.config")
local M = {}

M.is_empty_buffer = function()
  return vim.api.nvim_buf_line_count(0) == 1
    and vim.bo.buftype == ""
    and vim.api.nvim_buf_get_lines(0, 0, 1, true)[1] == ""
end

M.get_win_type = function()
  local wt = vim.fn.win_gettype()
  if wt == "" and vim.api.nvim_win_get_config(0).relative ~= "" then
    return "floating"
  else
    return wt
  end
end

M.get_stick_type = function()
  if M.is_empty_buffer() then
    return nil
  end
  local bufname = vim.api.nvim_buf_get_name(0)
  local stick = config.buftype[vim.bo.buftype]
    or config.wintype[M.get_win_type()]
    or config.filetype[vim.bo.filetype]
    or config.bufname[bufname]
  if stick then
    return stick
  end
  for pattern, mode in pairs(config.bufname) do
    if string.find(bufname, pattern) == 1 then
      return mode
    end
  end
end

M.is_sticky_win = function(winid)
  local ok, bufnr = pcall(vim.api.nvim_win_get_var, winid or 0, "sticky_original_bufnr")
  return ok and vim.api.nvim_buf_is_valid(bufnr)
end

M.is_sticky_match = function()
  if not M.is_sticky_win() then
    return true
  end
  if vim.w.sticky_bufnr and vim.w.sticky_bufnr ~= vim.api.nvim_get_current_buf() then
    return false
  end
  if vim.w.sticky_buftype and vim.w.sticky_buftype ~= vim.bo.buftype then
    return false
  end
  if vim.w.sticky_filetype and vim.w.sticky_filetype ~= vim.bo.filetype then
    return false
  end
  return true
end

M.override_bufhidden = function()
  -- We have to override bufhidden so that the buffer won't be
  -- unloaded or deleted if we navigate away from it
  local bufhidden = vim.bo.bufhidden
  if bufhidden == "unload" or bufhidden == "delete" or bufhidden == "wipe" then
    vim.b.prev_bufhidden = bufhidden
    vim.bo.bufhidden = "hide"
    vim.cmd([[
    augroup StickyBufOnHide
      au! * <buffer>
      autocmd BufHidden <buffer> call luaeval("require'stickybuf'.on_buf_hidden(tonumber(_A))", expand('<abuf>'))
    augroup END
    ]])
  end
end

M.restore_bufhidden = function()
  if vim.b.prev_bufhidden then
    vim.bo.bufhidden = vim.b.prev_bufhidden
    vim.b.prev_bufhidden = nil
    vim.cmd([[
    augroup StickyBufOnHide
      au! * <buffer>
    augroup END
    ]])
  end
end

M.is_buf_in_any_win = function(bufnr)
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if bufnr == vim.api.nvim_win_get_buf(winid) then
      return true
    end
  end
  return false
end

return M
