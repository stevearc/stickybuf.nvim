# stickybuf.nvim

Neovim plugin for locking a buffer to a window

Have you ever accidentally opened a file into your file explorer or quickfix window?

https://user-images.githubusercontent.com/506791/124820653-9bc20d00-df22-11eb-91c1-26ac8183367f.mp4

This may eventually be addressed [within vim
itself](https://github.com/neovim/neovim/issues/12517), but until then we can
provide a solution with plugins. Stickybuf allows you to pin a window to a
specific buffer, buftype, or filetype. Anything that opens a non-matching buffer
in that window will be reverted and re-routed to the nearest available window.

## Requirements

- Neovim 0.8+

## Installation

stickybuf.nvim supports all the usual plugin managers

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

| Command          | description                                                                               |
| ---------------- | ----------------------------------------------------------------------------------------- |
| `PinBuffer[!]`   | Pin the current buffer to the window.                                                     |
| `PinBuftype[!]`  | Pin the current buftype to the window. It will allow any buffers with the same buftype.   |
| `PinFiletype[!]` | Pin the current filetype to the window. It will allow any buffers with the same filetype. |
| `UnpinBuffer`    | Remove any type of pinning from the current window.                                       |

## API

### pin(winid, opts)

`select(opts)` \
Select the entry under the cursor

| Param | Type           | Desc                                               |                                       |
| ----- | -------------- | -------------------------------------------------- | ------------------------------------- |
| winid | `nil\|integer` | The window to pin                                  |                                       |
| opts  | `table`        |                                                    |                                       |
|       | vertical       | `boolean`                                          | Open the buffer in a vertical split   |
|       | horizontal     | `boolean`                                          | Open the buffer in a horizontal split |
|       | split          | `"aboveleft"\|"belowright"\|"topleft"\|"botright"` | Split modifier                        |
|       | preview        | `boolean`                                          | Open the buffer in a preview window   |
|       | tab            | `boolean`                                          | Open the buffer in a new tab          |

## Configuration

```lua
require("stickybuf").setup({
  -- 'bufnr' will pin the exact buffer (PinBuffer)
  -- 'buftype' will pin the buffer type (PinBuftype)
  -- 'filetype' will pin the filetype (PinFiletype)
  buftype = {
    [""]     = false,
    acwrite  = false,
    help     = "buftype",
    nofile   = false,
    nowrite  = false,
    quickfix = "buftype",
    terminal = false,
    prompt   = "bufnr",
  },
  wintype = {
    autocmd  = false,
    popup    = "bufnr",
    preview  = false,
    command  = false,
    [""]     = false,
    unknown  = false,
    floating = false,
  },
  filetype = {
    aerial = "filetype",
    nerdtree = "filetype",
    ['neotest-summary'] = "filetype",
  },
  bufname = {
    ["Neogit.*Popup"] = "bufnr",
  },
  -- Some autocmds for plugins that need a bit more logic
  -- Set to `false` to disable the autocmd
  autocmds = {
    -- Only pin defx if it was opened as a split (has fixed height/width)
    defx = [[au FileType defx if &winfixwidth || &winfixheight | silent! PinFiletype | endif]],
    -- Only pin fern if it was opened as a split (has fixed height/width)
    fern = [[au FileType fern if &winfixwidth || &winfixheight | silent! PinFiletype | endif]],
    -- Only pin neogit if it was opened as a split (there is more than one window)
    neogit = [[au FileType NeogitStatus,NeogitLog,NeogitGitCommandHistory if winnr('$') > 1 | silent! PinFiletype | endif]],
  }
})
```

You can also use autocmd to pin buffers conditionally

```vim
" Pin the buffer to any window that is fixed width or height
autocmd BufEnter * if &winfixwidth || &winfixheight | silent! PinBuffer | endif
```

## Plugin support

Stickybuf provides built-in support for:

- quickfix
- help
- [NERDtree](https://github.com/preservim/nerdtree)
- [defx](https://github.com/Shougo/defx.nvim)
- [fern](https://github.com/lambdalisue/fern.vim)
- [aerial](https://github.com/stevearc/aerial.nvim)
- [neogit](https://github.com/TimUntersberger/neogit)
- [neotest](https://github.com/rcarriga/neotest)

If there is another project that you would like to add out-of-the-box support
for, submit a pull request with a change to [the default config
file](https://github.com/stevearc/stickybuf.nvim/blob/master/lua/stickybuf/config.lua)

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
