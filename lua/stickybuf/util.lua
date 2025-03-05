local M = {}

---@param bufnr integer
---@return boolean
M.is_empty_buffer = function(bufnr)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  return vim.api.nvim_buf_line_count(bufnr) == 1
    and vim.bo[bufnr].buftype == ""
    and vim.api.nvim_buf_get_lines(bufnr, 0, 1, true)[1] == ""
end

---@param winid nil|integer
---@return boolean
M.is_sticky_win = function(winid)
  local ok, bufnr = pcall(vim.api.nvim_win_get_var, winid or 0, "sticky_original_bufnr")
  return ok and vim.api.nvim_buf_is_valid(bufnr)
end

---@param winid nil|integer
---@return boolean
M.is_floating_win = function(winid)
  return vim.api.nvim_win_get_config(winid or 0).relative ~= ""
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

---@param bufnr nil|integer
M.override_bufhidden = function(bufnr)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  -- We have to override bufhidden so that the buffer won't be
  -- unloaded or deleted if we navigate away from it
  local bufhidden = vim.bo[bufnr].bufhidden
  if bufhidden == "unload" or bufhidden == "delete" or bufhidden == "wipe" then
    vim.b[bufnr].prev_bufhidden = bufhidden
    vim.bo[bufnr].bufhidden = "hide"

    local group = vim.api.nvim_create_augroup("StickyBufOnHide", { clear = false })
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
          local was_modified = vim.bo[args.buf].modified
          if was_modified then
            vim.bo[args.buf].modified = false
          end
          -- We need a long delay for this to make sure we're not going to restore this buffer
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              if M.is_buf_in_any_win(args.buf) then
                vim.bo[args.buf].modified = was_modified
              else
                vim.cmd(string.format("silent! b%s! %d", prev_bufhidden, args.buf))
              end
            end
          end, 100)
        end
      end,
    })
  end
end

---@param bufnr nil|integer
M.restore_bufhidden = function(bufnr)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local prev_bufhidden = vim.b[bufnr].prev_bufhidden
  if prev_bufhidden then
    vim.bo[bufnr].bufhidden = prev_bufhidden
    vim.b[bufnr].prev_bufhidden = nil
    local group = vim.api.nvim_create_augroup("StickyBufOnHide", { clear = false })
    vim.api.nvim_clear_autocmds({
      buffer = bufnr,
      group = group,
    })
    if not M.is_buf_in_any_win(bufnr) then
      vim.cmd(string.format("silent! b%s! %d", prev_bufhidden, bufnr))
    end
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
