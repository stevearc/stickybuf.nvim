if not vim.g.no_stickybuf_init then
  vim.defer_fn(function()
    local stickybuf = require("stickybuf")
    if not stickybuf._has_setup then
      vim.notify_once(
        'Deprecated: stickybuf now requires you to call require("stickybuf").setup() in order to function.\nSet vim.g.no_stickybuf_init = true to disable this auto-bootstrapping.\nThis shim will be removed on 2023-07-01',
        vim.log.levels.WARN
      )
      stickybuf.setup()
    end
  end, 5000)
end
