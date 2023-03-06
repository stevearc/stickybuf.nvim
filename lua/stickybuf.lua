local config = require("stickybuf.config")
local util = require("stickybuf.util")
local M = {}

---@param bufnr integer
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
  local stick_type = util.get_stick_type()
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
    end, 1)
  elseif stick_type then
    if stick_type == "bufnr" then
      M.pin_buffer()
    elseif stick_type == "buftype" then
      M.pin_buftype()
    elseif stick_type == "filetype" then
      M.pin_filetype()
    else
      error(string.format("Unknown sticky buf type '%s'", stick_type))
    end
  end
end

---@param bang ""|"!"
---@param cmd string
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

---@param bang ""|"!"
M.pin_buffer = function(bang)
  if already_pinned(bang, "PinBuffer") then
    return
  end
  vim.w.sticky_original_bufnr = vim.api.nvim_get_current_buf()
  vim.w.sticky_bufnr = vim.api.nvim_get_current_buf()
  util.override_bufhidden()
end

---@param bang ""|"!"
M.pin_buftype = function(bang)
  if already_pinned(bang, "PinBuftype") then
    return
  end
  vim.w.sticky_original_bufnr = vim.api.nvim_get_current_buf()
  vim.w.sticky_buftype = vim.bo.buftype
  util.override_bufhidden()
end

---@param bang ""|"!"
M.pin_filetype = function(bang)
  if already_pinned(bang, "PinFiletype") then
    return
  end
  vim.w.sticky_original_bufnr = vim.api.nvim_get_current_buf()
  vim.w.sticky_filetype = vim.bo.filetype
  util.override_bufhidden()
end

---@param keep_bufhidden boolean
M.unpin_buffer = function(keep_bufhidden)
  vim.w.sticky_original_bufnr = nil
  vim.w.sticky_bufnr = nil
  vim.w.sticky_buftype = nil
  vim.w.sticky_filetype = nil
  if keep_bufhidden then
    util.restore_bufhidden()
  end
end

---@param opts nil|table
M.setup = function(opts)
  if vim.fn.has("nvim-0.8") == 0 then
    vim.notify_once(
      "stickybuf has dropped support for Neovim <0.8. Please use the nvim-0.6 branch or upgrade Neovim",
      vim.log.levels.ERROR
    )
    return
  end
  config:update(opts)
  local aug = vim.api.nvim_create_augroup("Stickybuf", {})
  vim.api.nvim_create_autocmd("BufEnter", {
    desc = "Restore pinned buffer, if necessary",
    group = aug,
    callback = function()
      -- Delay just in case the buffer is blank when entered but some process is
      -- about to set all the filetype/buftype/etc options
      vim.defer_fn(_on_buf_enter, 5)
    end,
  })

  vim.api.nvim_create_user_command("PinBuffer", function(args)
    M.pin_buffer(args.bang and "!" or "")
  end, { bar = true, bang = true })
  vim.api.nvim_create_user_command("PinBuftype", function(args)
    M.pin_buftype(args.bang and "!" or "")
  end, { bar = true, bang = true })
  vim.api.nvim_create_user_command("PinFiletype", function(args)
    M.pin_filetype(args.bang and "!" or "")
  end, { bar = true, bang = true })
  vim.api.nvim_create_user_command("UnpinBuffer", M.unpin_buffer, {
    desc = "Remove pinning for the current buffer",
  })
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
