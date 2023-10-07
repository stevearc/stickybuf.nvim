local config = {}
local util = require("stickybuf.util")
local M = {}

-- TODO remove after https://github.com/folke/neodev.nvim/pull/163 lands
---@diagnostic disable: inject-field

---@class (exact) stickybuf.WinPinConfig
---@field allow fun(bufnr: integer): boolean
---@field restore_callback? fun(winid: integer)

---@param bufnr integer
local function open_in_best_window(bufnr)
  -- Open the buffer in the first window that doesn't have a sticky buffer
  for winnr = 1, vim.fn.winnr("$") do
    local winid = vim.fn.win_getid(winnr)
    if not M.is_pinned(winid) and not util.is_floating_win(winid) then
      -- Also have to make sure that the window wouldn't be auto-pinned. The auto-pin only
      -- triggers on BufEnter, but we may have not entered the buffer yet (e.g. aerial)
      -- See https://github.com/stevearc/stickybuf.nvim/issues/10
      if not config.get_auto_pin(vim.api.nvim_win_get_buf(winid)) then
        vim.cmd.wincmd({ count = winnr, args = { "w" } })
        vim.cmd.buffer({ args = { bufnr } })
        return
      end
    end
  end
  -- If none exists, open the buffer in a vsplit from the first window
  vim.fn.win_execute(vim.fn.win_getid(1), string.format("vertical rightbelow sbuffer %d", bufnr))
  vim.cmd.wincmd({ count = 2, args = { "w" } })
end

local function _on_buf_enter(bufnr)
  if util.is_empty_buffer(bufnr) then
    return
  end
  -- TODO remove after https://github.com/folke/neodev.nvim/pull/163 lands
  ---@type stickybuf.WinPinConfig
  ---@diagnostic disable-next-line: undefined-field
  local sticky_conf = vim.w.sticky_win
  if sticky_conf then
    if not sticky_conf.allow(bufnr) then
      -- If this was a sticky window and the buffer no longer matches, restore it
      util.override_bufhidden(bufnr)
      local winid = vim.api.nvim_get_current_win()
      vim.fn.win_execute(winid, "noau buffer " .. vim.w.sticky_original_bufnr)
      -- Then open the new buffer in the appropriate location
      vim.defer_fn(function()
        open_in_best_window(bufnr)
        util.restore_bufhidden(bufnr)
        if sticky_conf.restore_callback then
          sticky_conf.restore_callback(winid)
        end
      end, 1)
    else
      -- This was a sticky window and the new buffer does match
      if vim.w.sticky_original_bufnr ~= bufnr then
        -- If this is a new buffer for the window
        util.override_bufhidden(bufnr)
        vim.w.sticky_original_bufnr = bufnr
        util.restore_bufhidden(vim.w.sticky_original_bufnr)
      end
    end
  else
    -- Check if this buffer should be auto-pinned
    local pintype = config.get_auto_pin(bufnr)
    if pintype then
      if type(pintype) == "function" then
        M.pin(0, { allow = pintype })
      else
        M.pin(0, { allow_type = pintype })
      end
    end
  end
end

---@deprecated
---@param bang ""|"!"
M.pin_buffer = function(bang)
  vim.notify_once(
    "Deprecated[stickybuf.pin_buffer] use stickybuf.pin instead\nThis function will be removed on 2023-07-01",
    vim.log.levels.WARN
  )
  if bang == "!" or not M.is_pinned() then
    M.pin()
  end
end

---@deprecated
---@param bang ""|"!"
M.pin_buftype = function(bang)
  vim.notify_once(
    "Deprecated[stickybuf.pin_buftype] use stickybuf.pin instead\nThis function will be removed on 2023-07-01",
    vim.log.levels.WARN
  )
  if bang == "!" or not M.is_pinned() then
    M.pin(0, { allow_type = "buftype" })
  end
end

---@deprecated
---@param bang ""|"!"
M.pin_filetype = function(bang)
  vim.notify_once(
    "Deprecated[stickybuf.pin_filetype] use stickybuf.pin instead\nThis function will be removed on 2023-07-01",
    vim.log.levels.WARN
  )
  if bang == "!" or not M.is_pinned() then
    M.pin(0, { allow_type = "filetype" })
  end
end

---Pin the buffer in the specified window
---@param winid nil|integer
---@param opts nil|table
---    allow nil|fun(bufnr: integer): boolean Return true to allow switching to the buffer
---    allow_type nil|"bufnr"|"buftype"|"filetype" Allow switching to buffers with a matching value
---    restore_callback nil|fun(winid: integer) Called after a buffer is restored into the pinned window
---@note
--- You cannot specify both 'allow' and 'allow_type'
M.pin = function(winid, opts)
  if not winid or winid == 0 then
    winid = vim.api.nvim_get_current_win()
  end
  opts = opts or {}
  local bufnr = vim.api.nvim_win_get_buf(winid)
  if opts.allow and opts.allow_type then
    error("Cannot specify both 'allow' and 'allow_type'")
  end
  if opts.allow_type == "buftype" then
    local buftype = vim.bo[bufnr].buftype
    opts.allow = function(newbuf)
      return vim.bo[newbuf].buftype == buftype
    end
  end
  if opts.allow_type == "filetype" then
    local filetype = vim.bo[bufnr].filetype
    opts.allow = function(newbuf)
      return vim.bo[newbuf].filetype == filetype
    end
  end
  if not opts.allow then
    opts.allow = function(newbuf)
      return newbuf == bufnr
    end
  end
  vim.w[winid].sticky_win = opts
  vim.w[winid].sticky_original_bufnr = bufnr
  util.override_bufhidden(vim.api.nvim_win_get_buf(winid))
end

---Remove any pinning logic for the window
---@param winid nil|integer
M.unpin = function(winid)
  if not winid or winid == 0 then
    winid = vim.api.nvim_get_current_win()
  end
  vim.w[winid].sticky_win = nil
  -- TODO we actually only want to do this if the buffer isn't pinned in any other windows
  util.restore_bufhidden()
end

---@param winid nil|integer
---@return boolean
M.is_pinned = function(winid)
  return vim.w[winid or 0].sticky_original_bufnr ~= nil
end

---@deprecated
---@param keep_bufhidden boolean
M.unpin_buffer = function(keep_bufhidden)
  vim.notify_once(
    "Deprecated[stickybuf.unpin_buffer] use stickybuf.unpin instead\nThis function will be removed on 2023-07-01",
    vim.log.levels.WARN
  )
  M.unpin()
end

local commands = {
  {
    cmd = "PinBuffer",
    callback = function(args)
      if args.bang or not M.is_pinned() then
        M.pin()
      end
    end,
    def = {
      desc = "Pin the current buffer to the current window",
      bang = true,
      bar = true,
    },
  },
  {
    cmd = "PinBuftype",
    callback = function(args)
      if args.bang or not M.is_pinned() then
        M.pin(0, { allow_type = "buftype" })
      end
    end,
    def = {
      desc = "Pin the buffer in the current window, but allow other buffers with the same buftype",
      bang = true,
      bar = true,
    },
  },
  {
    cmd = "PinFiletype",
    callback = function(args)
      if args.bang or not M.is_pinned() then
        M.pin(0, { allow_type = "filetype" })
      end
    end,
    def = {
      desc = "Pin the buffer in the current window, but allow other buffers with the same filetype",
      bang = true,
      bar = true,
    },
  },
  {
    cmd = "UnpinBuffer",
    deprecated = true,
    callback = function(args)
      vim.notify_once(
        "Deprecated[UnpinBuffer] use :Unpin instead.\nThis command will be removed on 2023-07-01",
        vim.log.levels.WARN
      )
      M.unpin()
    end,
    def = {
      desc = "[Deprecated] Remove pinning for the current window",
      bar = true,
    },
  },
  {
    cmd = "Unpin",
    callback = function(args)
      M.unpin()
    end,
    def = {
      desc = "Remove pinning for the current window",
      bar = true,
    },
  },
}

---Used for documentation generation
---@private
M.get_all_commands = function()
  local cmds = vim.deepcopy(commands)
  for _, v in ipairs(cmds) do
    v.callback = nil
    -- Remove all function values from the command definition so we can serialize it
    for k, param in pairs(v.def) do
      if type(param) == "function" then
        v.def[k] = nil
      end
    end
  end
  return cmds
end

M._has_setup = false

---@param opts nil|table
M.setup = function(opts)
  M._has_setup = true
  if vim.fn.has("nvim-0.8") == 0 then
    vim.notify_once(
      "stickybuf has dropped support for Neovim <0.8. Please use the nvim-0.6 branch or upgrade Neovim",
      vim.log.levels.ERROR
    )
    return
  end
  if opts and not opts.get_auto_pin and not vim.tbl_isempty(opts) then
    vim.notify_once(
      "stickybuf has completely changed its setup() options. Please see :help stickybuf-options for the new format.",
      vim.log.levels.ERROR
    )
  end
  config = vim.tbl_deep_extend("keep", opts or {}, {
    get_auto_pin = M.should_auto_pin,
  })
  local aug = vim.api.nvim_create_augroup("Stickybuf", {})
  vim.api.nvim_create_autocmd("BufEnter", {
    desc = "Restore pinned buffer, if necessary",
    group = aug,
    callback = function(args)
      -- Delay just in case the buffer is blank when entered but some process is
      -- about to set all the filetype/buftype/etc options
      vim.defer_fn(function()
        if args.buf == vim.api.nvim_get_current_buf() then
          _on_buf_enter(args.buf)
        end
      end, 5)
    end,
  })

  for _, v in pairs(commands) do
    vim.api.nvim_create_user_command(v.cmd, v.callback, v.def)
  end
end

local builtin_supported_filetypes = {
  "aerial",
  "nerdtree",
  "neotest-summary",
  "startuptime",
  "toggleterm",
  "fugitive",
  "notify",
  "fugitiveblame",
  "neo-tree",
  "GoogleKeepList",
  "GoogleKeepMenu",
  "NvimTree",
  "OverseerList",
  "spectre_panel",
}

---The default function for config.get_auto_pin
---@param bufnr integer
---@return nil|"bufnr"|"buftype"|"filetype"
M.should_auto_pin = function(bufnr)
  local buftype = vim.bo[bufnr].buftype
  local filetype = vim.bo[bufnr].filetype
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if buftype == "help" or buftype == "quickfix" then
    return "buftype"
  elseif buftype == "prompt" or vim.startswith(bufname, "DAP ") then
    return "bufnr"
  elseif vim.tbl_contains(builtin_supported_filetypes, filetype) then
    return "filetype"
  elseif bufname:match("Neogit.*Popup") then
    return "bufnr"
  elseif filetype == "defx" and (vim.wo.winfixwidth or vim.wo.winfixheight) then
    -- Only pin defx if it was opened as a split (has fixed height/width)
    return "filetype"
  elseif filetype == "fern" and (vim.wo.winfixwidth or vim.wo.winfixheight) then
    -- Only pin fern if it was opened as a split (has fixed height/width)
    return "filetype"
  elseif vim.startswith(filetype, "Neogit") then
    if vim.fn.winnr("$") > 1 then
      return "filetype"
    end
  end
end

return M
