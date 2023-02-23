local config = require("stickybuf.config")
local util = require("stickybuf.util")
local M = {}

local function open_in_best_window(bufnr)
  -- Open the buffer in the first window that doesn't have a sticky buffer
  for winnr = 1, vim.fn.winnr("$") do
    local winid = vim.fn.win_getid(winnr)
    if not util.is_sticky_win(winid) then
      vim.cmd(string.format("%dwincmd w", winnr))
      vim.cmd(string.format("buffer %d", bufnr))
      return
    end
  end
  -- If none exists, open the buffer in a vsplit from the first window
  vim.fn.win_execute(vim.fn.win_getid(1), string.format("vertical rightbelow sbuffer %d", bufnr))
  vim.cmd([[2wincmd w]])
end

local function _on_buf_enter()
  if util.is_empty_buffer() then
    return
  end
  local stick_info = util.get_stick_info()
  if not util.is_sticky_match() then
    -- If this was a sticky buffer window and the buffer no longer matches, restore it
    util.override_bufhidden()
    local winid = vim.api.nvim_get_current_win()
    local newbuf = vim.api.nvim_get_current_buf()
    vim.fn.win_execute(winid, "noau buffer " .. vim.w.sticky_original_bufnr)
    -- Then open the new buffer in the appropriate location
    vim.defer_fn(function()
      open_in_best_window(newbuf)
      util.restore_bufhidden()
      if vim.w[winid].sticky_callback then
        vim.w[winid].sticky_callback()
      end
    end, 1)
  elseif stick_info then
    local stick_type = stick_info[1]
    local stick_callback = stick_info.callback

    if stick_type == "bufnr" then
      M.pin_buffer(false, stick_callback)
    elseif stick_type == "buftype" then
      M.pin_buftype(false, stick_callback)
    elseif stick_type == "filetype" then
      M.pin_filetype(false, stick_callback)
    else
      error(string.format("Unknown sticky buf type '%s'", stick_type))
    end
  end
end

M.on_buf_enter = function()
  -- Delay just in case the buffer is blank when entered but some process is
  -- about to set all the filetype/buftype/etc options
  vim.defer_fn(_on_buf_enter, 5)
end

M.on_buf_hidden = function(bufnr)
  local ok, prev_bufhidden = pcall(vim.api.nvim_buf_get_var, bufnr, "prev_bufhidden")
  if ok then
    -- Set nomodified on the buffer. If we try to quit nvim shortly after
    -- leaving a modified buffer (e.g. a Telescope prompt), nvim will NOT quit
    -- and instead inform you that you have modified buffers to take care of.
    -- To avoid that we set nomodified, and restore the previous modified state
    -- if we end up not garbage collecting this buffer.
    -- (see https://github.com/stevearc/stickybuf.nvim/pull/6)
    local was_modified = vim.api.nvim_buf_get_option(bufnr, "modified")
    if was_modified then
      vim.api.nvim_buf_set_option(bufnr, "modified", false)
    end
    -- We need a long delay for this to make sure we're not going to restore this buffer
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        if util.is_buf_in_any_win(bufnr) then
          vim.api.nvim_buf_set_option(bufnr, "modified", was_modified)
        else
          vim.cmd(string.format("silent! b%s! %d", prev_bufhidden, bufnr))
        end
      end
    end, 1000)
  end
end

local function already_pinned(bang, cmd)
  if util.is_sticky_win() then
    if bang == "" then
      error(
        string.format(
          "Window is already pinned. Use '%s!' to override or 'silent! %s' to ignore this error",
          cmd,
          cmd
        )
      )
      return true
    end
  end
  M.unpin_buffer(true)
end

M.pin_buffer = function(bang, callback)
  if already_pinned(bang, "PinBuffer") then
    return
  end
  vim.w.sticky_callback = callback
  vim.w.sticky_original_bufnr = vim.api.nvim_get_current_buf()
  vim.w.sticky_bufnr = vim.api.nvim_get_current_buf()
  util.override_bufhidden()
end

M.pin_buftype = function(bang, callback)
  if already_pinned(bang, "PinBuftype") then
    return
  end
  vim.w.sticky_callback = callback
  vim.w.sticky_original_bufnr = vim.api.nvim_get_current_buf()
  vim.w.sticky_buftype = vim.bo.buftype
  util.override_bufhidden()
end

M.pin_filetype = function(bang, callback)
  if already_pinned(bang, "PinFiletype") then
    return
  end
  vim.w.sticky_callback = callback
  vim.w.sticky_original_bufnr = vim.api.nvim_get_current_buf()
  vim.w.sticky_filetype = vim.bo.filetype
  util.override_bufhidden()
end

M.unpin_buffer = function(keep_bufhidden)
  vim.w.sticky_original_bufnr = nil
  vim.w.sticky_bufnr = nil
  vim.w.sticky_buftype = nil
  vim.w.sticky_filetype = nil
  if keep_bufhidden then
    util.restore_bufhidden()
  end
end

M.setup = function(opts)
  config:update(opts)
  vim.cmd([[
  augroup StickyBuf
    au!
    autocmd BufEnter * lua require'stickybuf'.on_buf_enter()
  augroup END
  ]])
  vim.cmd(
    [[command! -bar -bang PinBuffer call luaeval("require'stickybuf'.pin_buffer(_A)", expand('<bang>'))]]
  )
  vim.cmd(
    [[command! -bar -bang PinBuftype call luaeval("require'stickybuf'.pin_buftype(_A)", expand('<bang>'))]]
  )
  vim.cmd(
    [[command! -bar -bang PinFiletype call luaeval("require'stickybuf'.pin_filetype(_A)", expand('<bang>'))]]
  )
  vim.cmd([[command! -bar UnpinBuffer lua require'stickybuf'.unpin_buffer()]])
  local cmd = [[augroup StickyBufIntegration
    au!
  ]]
  for _, autocmd in pairs(config.autocmds) do
    if autocmd then
      cmd = string.format("%s\n%s", cmd, autocmd)
    end
  end
  cmd = string.format("%s\naugroup END", cmd)
  vim.cmd(cmd)
end

return M
