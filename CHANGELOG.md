# Changelog

## [2.0.0](https://github.com/stevearc/stickybuf.nvim/compare/v1.0.0...v2.0.0) (2024-01-14)


### ⚠ BREAKING CHANGES

* remove old deprecated functions, commands, and shims

### cleanup

* remove old deprecated functions, commands, and shims ([92d07c7](https://github.com/stevearc/stickybuf.nvim/commit/92d07c71c7a7397da45a4473f9325b2beb8de7b9))


### Features

* option to provide custom handling when pin is triggered ([#21](https://github.com/stevearc/stickybuf.nvim/issues/21)) ([7e58094](https://github.com/stevearc/stickybuf.nvim/commit/7e58094251281e9a4dc0dd0223bf7248d0d50e3b))


### Bug Fixes

* disable for Neogit commit message ([#23](https://github.com/stevearc/stickybuf.nvim/issues/23)) ([f3398f8](https://github.com/stevearc/stickybuf.nvim/commit/f3398f8639e903991acdf66e2d63de7a78fe708e))
* don't pin telescope prompt ([#26](https://github.com/stevearc/stickybuf.nvim/issues/26)) ([42973af](https://github.com/stevearc/stickybuf.nvim/commit/42973af199ad7765dc820e88b51ec86cfde90537))
* unpin doesn't completely clear state ([#25](https://github.com/stevearc/stickybuf.nvim/issues/25)) ([4271bfc](https://github.com/stevearc/stickybuf.nvim/commit/4271bfc6c85dc035eb9e8484954f9179d90e87ab))

## 1.0.0 (2023-09-18)


### ⚠ BREAKING CHANGES

* disable pinning popup windows by default

### Features

* add built-in support for gkeep.nvim ([fc75dc2](https://github.com/stevearc/stickybuf.nvim/commit/fc75dc22d12e5446c72a0d5f067cd7a16b3d921a))
* add support for neotest ([db2965c](https://github.com/stevearc/stickybuf.nvim/commit/db2965ccd97b3f1012b19a76d8541f9843b12960))
* add support for nvim-spectre ([#17](https://github.com/stevearc/stickybuf.nvim/issues/17)) ([c661eeb](https://github.com/stevearc/stickybuf.nvim/commit/c661eeb50d54909698636c0d1b6144ffbceb0fe0))
* API supports a post-restore callback ([#8](https://github.com/stevearc/stickybuf.nvim/issues/8)) ([8359988](https://github.com/stevearc/stickybuf.nvim/commit/8359988ff41f50288998bad2096541ef8919892d))


### Bug Fixes

* 1: Pin neogit commit message buffer ([f9d8cd3](https://github.com/stevearc/stickybuf.nvim/commit/f9d8cd38e03d8dd12148a3c8da89ee22668588fa))
* apply stylua to files ([4d90423](https://github.com/stevearc/stickybuf.nvim/commit/4d90423edc7ca56b88437e1c3500d91a45366529))
* check auto-pin when selecting an unpinned window ([#10](https://github.com/stevearc/stickybuf.nvim/issues/10)) ([162f6c0](https://github.com/stevearc/stickybuf.nvim/commit/162f6c0bbbd7da56bcb19519dcbdfa01e0787a27))
* disable pinning popup windows by default ([a25fd91](https://github.com/stevearc/stickybuf.nvim/commit/a25fd910d5a695567c3199335875bc347a530a3b))
* don't allow opening buffers in floating windows ([66f639d](https://github.com/stevearc/stickybuf.nvim/commit/66f639d9953cd4eb5cf20ed03f5f4d0bf3fd4cfa))
* make tests less flaky ([2801889](https://github.com/stevearc/stickybuf.nvim/commit/28018899bb29bdb71c1fab8a4d0dc17c8b1e0895))
* pin more Neogit buffers ([#20](https://github.com/stevearc/stickybuf.nvim/issues/20)) ([92b105a](https://github.com/stevearc/stickybuf.nvim/commit/92b105adac2efa408b4c01796b14fe3f917e17a6))
* set nomodified on hidden buffers ([#6](https://github.com/stevearc/stickybuf.nvim/issues/6)) ([8e58489](https://github.com/stevearc/stickybuf.nvim/commit/8e58489cc1b680b7f0fdb24c120fd88820cedb56))
* shorten cleanup timeout ([#13](https://github.com/stevearc/stickybuf.nvim/issues/13)) ([771caf4](https://github.com/stevearc/stickybuf.nvim/commit/771caf43582ecddef90a17f7a07f234cfee01005))
* type errors ([189f1db](https://github.com/stevearc/stickybuf.nvim/commit/189f1dba1e086eb6c4438940921efdc624b93cca))
