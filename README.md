# stickybuf.nvim

Neovim plugin for locking a buffer to a window

Have you ever accidentally opened a file into your file explorer or quickfix window?

https://user-images.githubusercontent.com/506791/124820653-9bc20d00-df22-11eb-91c1-26ac8183367f.mp4

This may eventually be addressed [within vim
itself](https://github.com/neovim/neovim/issues/12517), but until then we can
provide a solution with plugins. Stickybuf allows you to pin a window to a
specific buffer, buftype, or filetype. Anything that opens a non-matching buffer
in that window will be reverted and re-routed to the nearest available window.

<!-- TOC -->

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Commands](#commands)
- [API](#api)
- [Configuration](#configuration)
- [Plugin support](#plugin-support)
- [How does it work?](#how-does-it-work)

<!-- /TOC -->

## Requirements

- Neovim 0.8+

## Installation

stickybuf.nvim supports all the usual plugin managers

<details>
  <summary>lazy.nvim</summary>

```lua
{
  'stevearc/stickybuf.nvim',
  opts = {},
}
```

</details>

<details>
  <summary>Packer</summary>

```lua
require('packer').startup(function()
    use {
      'stevearc/stickybuf.nvim',
      config = function() require('stickybuf').setup() end
    }
end)
```

</details>

<details>
  <summary>Paq</summary>

```lua
require "paq" {
    {'stevearc/stickybuf.nvim'};
}
```

</details>

<details>
  <summary>vim-plug</summary>

```vim
Plug 'stevearc/stickybuf.nvim'
```

</details>

<details>
  <summary>dein</summary>

```vim
call dein#add('stevearc/stickybuf.nvim')
```

</details>

<details>
  <summary>Pathogen</summary>

```sh
git clone --depth=1 https://github.com/stevearc/stickybuf.nvim.git ~/.vim/bundle/
```

</details>

<details>
  <summary>Neovim native package</summary>

```sh
git clone --depth=1 https://github.com/stevearc/stickybuf.nvim.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/pack/stickybuf/start/stickybuf.nvim
```

</details>

## Quick start

Add the following to your init.lua

```lua
require("stickybuf").setup()
```

## Commands

| Command          | Description                                                                          |
| ---------------- | ------------------------------------------------------------------------------------ |
| `PinBuffer[!]`   | Pin the current buffer to the current window                                         |
| `PinBuftype[!]`  | Pin the buffer in the current window, but allow other buffers with the same buftype  |
| `PinFiletype[!]` | Pin the buffer in the current window, but allow other buffers with the same filetype |
| `Unpin`          | Remove pinning for the current window                                                |

## API

<!-- API -->

### pin(winid, opts)

`pin(winid, opts)` \
Pin the buffer in the specified window

| Param                  | Type                                  | Desc                                                                                                   |
| ---------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| winid                  | `nil\|integer`                        |                                                                                                        |
| opts                   | `nil\|stickybuf.pinOpts`              |                                                                                                        |
| >allow                 | `nil\|fun(bufnr: integer): boolean`   | Return true to allow switching to the buffer                                                           |
| >allow_type            | `nil\|"bufnr"\|"buftype"\|"filetype"` | Allow switching to buffers with a matching value                                                       |
| >restore_callback      | `nil\|fun(winid: integer)`            | Called after a buffer is restored into the pinned window                                               |
| >handle_foreign_buffer | `nil\|fun(bufnr: integer)`            | Called when a buffer enters a pinned window. The default implementation opens in a near or new window. |

**Note:**
<pre>
You cannot specify both 'allow' and 'allow_type'
</pre>

### unpin(winid)

`unpin(winid)` \
Remove any pinning logic for the window

| Param | Type           | Desc |
| ----- | -------------- | ---- |
| winid | `nil\|integer` |      |

### is_pinned(winid)

`is_pinned(winid): boolean`

| Param | Type           | Desc |
| ----- | -------------- | ---- |
| winid | `nil\|integer` |      |

### setup(opts)

`setup(opts)`

| Param | Type         | Desc |
| ----- | ------------ | ---- |
| opts  | `nil\|table` |      |

### should_auto_pin(bufnr)

`should_auto_pin(bufnr): nil|"bufnr"|"buftype"|"filetype"` \
The default function for config.get_auto_pin

| Param | Type      | Desc |
| ----- | --------- | ---- |
| bufnr | `integer` |      |


<!-- /API -->

## Configuration

```lua
require("stickybuf").setup({
  -- This function is run on BufEnter to determine pinning should be activated
  get_auto_pin = function(bufnr)
    -- You can return "bufnr", "buftype", "filetype", or a custom function to set how the window will be pinned.
    -- You can instead return an table that will be passed in as "opts" to `stickybuf.pin`.
    -- The function below encompasses the default logic. Inspect the source to see what it does.
    return require("stickybuf").should_auto_pin(bufnr)
  end
})
```

You can also use autocmd to pin buffers conditionally

```lua
vim.api.nvim_create_autocmd("BufEnter", {
  desc = "Pin the buffer to any window that is fixed width or height",
  callback = function(args)
    local stickybuf = require("stickybuf")
    if not stickybuf.is_pinned() and (vim.wo.winfixwidth or vim.wo.winfixheight) then
      stickybuf.pin()
    end
  end
})
```

## Plugin support

Stickybuf provides built-in support for:

- quickfix
- help
- [NERDtree](https://github.com/preservim/nerdtree)
- [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua)
- [defx](https://github.com/Shougo/defx.nvim)
- [fern](https://github.com/lambdalisue/fern.vim)
- [aerial](https://github.com/stevearc/aerial.nvim)
- [neogit](https://github.com/TimUntersberger/neogit)
- [neotest](https://github.com/rcarriga/neotest)
- [vim-startuptime](https://github.com/dstein64/vim-startuptime)
- [toggleterm](https://github.com/akinsho/toggleterm.nvim)
- [vim-fugitive](https://github.com/tpope/vim-fugitive)
- [nvim-notify](https://github.com/rcarriga/nvim-notify)
- [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim)
- [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)
- [gkeep.nvim](https://github.com/stevearc/gkeep.nvim)
- [Overseer](https://github.com/stevearc/overseer.nvim)
- [nvim-spectre](https://github.com/nvim-pack/nvim-spectre)
- [grug-far](https://github.com/MagicDuck/grug-far.nvim)

If there is another project that you would like to add out-of-the-box support
for, submit a pull request, it's likely you'd only need to update the
`builtin_supported_filetypes` variable in [the main source
file](https://github.com/stevearc/stickybuf.nvim/blob/master/lua/stickybuf.lua)

## How does it work?

Since stickybuf is compensating for missing behavior in vim itself, the
implementation is necessarily something of a hack. When a buffer is pinned, its
information is stored on the current window in window-local variables. Stickybuf
registers a callback on `BufEnter` that examines the current window and, if that
window is pinned, restores the previous buffer and opens the new buffer in an
unpinned window.

Since stickybuf relies on being able to restore the pinned buffer after it is
hidden, it overrides the `bufhidden` option of pinned buffers and only cleans up
the buffer after a delay. The delay provides enough time to make sure that the
buffer isn't going to be restored to the pinned window.

**Warning**: If you are using any plugin or functionality that relies upon
`bufhidden`, particularly if it relies on `bufhidden` to trigger `BufUnload`,
`BufDelete`, or `BufWipeout` immediately, stickybuf _could_ cause issues. See
[#1](https://github.com/stevearc/stickybuf.nvim/issues/1) for a case where this
happens with Neogit.
