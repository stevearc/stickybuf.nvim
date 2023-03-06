local config = require("stickybuf.config")
local M = {}

---@return boolean
M.is_empty_buffer = function()
  return vim.api.nvim_buf_line_count(0) == 1
    and vim.bo.buftype == ""
    and vim.api.nvim_buf_get_lines(0, 0, 1, true)[1] == ""
end

---@return string
M.get_win_type = function()
  local wt = vim.fn.win_gettype()
  if wt == "" and vim.api.nvim_win_get_config(0).relative ~= "" then
    return "floating"
  else
    return wt
  end
end

---@return nil|string
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

---@param winid nil|integer
---@return boolean
M.is_sticky_win = function(winid)
  local ok, bufnr = pcall(vim.api.nvim_win_get_var, winid or 0, "sticky_original_bufnr")
  return ok and vim.api.nvim_buf_is_valid(bufnr)
end

---@return boolean
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

    local group = vim.api.nvim_create_augroup("StickyBufOnHide", { clear = false })
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_clear_autocmds({
      buffer = bufnr,
      group = group,
    })
    vim.api.nvim_create_autocmd("BufHidden", {
      group = group,
      buffer = bufnr,
      callback = function(args)
        local ok, prev_bufhidden = pcall(vim.api.nvim_buf_get_var, args.buf, "prev_bufhidden")
        if ok then
          -- Set nomodified on the buffer. If we try to quit nvim shortly after
          -- leaving a modified buffer (e.g. a Telescope prompt), nvim will NOT quit
          -- and instead inform you that you have modified buffers to take care of.
          -- To avoid that we set nomodified, and restore the previous modified state
          -- if we end up not garbage collecting this buffer.
          -- (see https://github.com/stevearc/stickybuf.nvim/pull/6)
          local was_modified = vim.api.nvim_buf_get_option(args.buf, "modified")
          if was_modified then
            vim.api.nvim_buf_set_option(args.buf, "modified", false)
          end
          -- We need a long delay for this to make sure we're not going to restore this buffer
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              if M.is_buf_in_any_win(args.buf) then
                vim.api.nvim_buf_set_option(args.buf, "modified", was_modified)
              else
                vim.cmd(string.format("silent! b%s! %d", prev_bufhidden, args.buf))
              end
            end
          end, 1000)
        end
      end,
    })
  end
end

M.restore_bufhidden = function()
  if vim.b.prev_bufhidden then
    vim.bo.bufhidden = vim.b.prev_bufhidden
    vim.b.prev_bufhidden = nil
    local group = vim.api.nvim_create_augroup("StickyBufOnHide", { clear = false })
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_clear_autocmds({
      buffer = bufnr,
      group = group,
    })
  end
end

---@param bufnr integer
---@return boolean
M.is_buf_in_any_win = function(bufnr)
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(winid) and bufnr == vim.api.nvim_win_get_buf(winid) then
      return true
    end
  end
  return false
end

return M
