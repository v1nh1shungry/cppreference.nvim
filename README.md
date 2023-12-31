# cppreference.nvim

**Attension! This repository is about to be archived soon. I know it's ridiculous to deprecate a plugin that was just created YESTERDAY. But I do realize that let the browser and cppman in the same plugin is really a bad idea. And I prefer cppman, why not? So there is a successor, [v1nh1shungry/cppman.nvim](https://github.com/v1nh1shungry/cppman.nvim), by me too. Seriously I promise I will keep this one as long as possible 😅. However, if you have any idea about this plugin, please feel free contact me. Thank you for taking a look at this silly plugin!**

A deadly silly plugin for searching and viewing [cppreference](http://cppreference.com/) pages in your favorite editor.

**NOTE**: currently only Linux (WSL included) is supported!

# Showcase

* Browser:

![](https://user-images.githubusercontent.com/98312435/256899350-4350d581-2eee-4d24-bac2-959d6de6bca1.gif)

* [cppman](https://github.com/aitjcize/cppman):

![](https://user-images.githubusercontent.com/98312435/256899443-e7d06f27-8e8d-40cd-ad2a-6dfdadd67603.gif)

# Features

* Dual view: your favorite browser, or [cppman](https://github.com/aitjcize/cppman)! You don't even have to leave dear neovim.

* Fuzzy search (powered by [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)): what you can expect from [a vscode extension](https://github.com/Guyutongxue/VSC_CppReference) or [a browser extension](https://github.com/huhu/cpp-search-extension) is now available in the great neovim!

# Installation

1. Make sure you have `curl` installed and be available in `$PATH`.

2. * If you use the browser, make sure `xdg-open` is available in `$PATH` which is used to open the browser.
   
   * If you use `cppman`, make sure you have `cppman` installed and be available in `$PATH`. And make sure you have set the `cppman`'s source to `cppreference.com` (which is the default value. If you haven't modified this option after the installation you don't have to do anything).

3. [lazy.nvim](https://github.com/folke/lazy.nvim):
   
   ```lua
   {
     'v1nh1shungry/cppreference.nvim'
     dependencies = 'nvim-telescope/telescope.nvim',
     opts = {},
   }
   ```

# Configuration

```lua
-- default configuration
require('cppreference').setup {
  -- viewer to display the cppreference page
  -- can be 'browser' or 'cppman'
  view = 'browser',
  cppman = {
    -- where the cppman window displays
    -- can be 'split', 'vsplit' or 'tab'
    position = 'split',
  },
}
```

# Usage

* `require('cppreference').fuzzy_search()`

* `require('cppreference').open(keyword)`: find all entries contain `keyword`, if there is only one entry then directly open it. Otherwise launch a fuzzy search pane and let you select one of the related entries.

* `require('cppreference').update_index()`: use `curl` to download the latest index used in the fuzzy search.

# FAQ ~~(actually nobody asks)~~

* **Q:** An entry exists in the fuzzy search pane, but `cppman` says **NO**?

  **A:** The plugin eventually relies on `cppman` to locate the page if you use `cppman` as the viewer, and `cppman` can only locate objects own an individual page. In this case you have to use the browser to open the URL, which can be found in the index file.

# TODO

- [x] `require('cppreference').open(word)`: directly offer the keyword, useful to play with `expand('<cword>')`

- [ ] ~~Windows support~~ Cross-platform support: I don't use neovim in Windows (WSL instead), and I don't even own a Mac. So I agree this is an important feature but I'm not able to achieve it currently.

  - [ ] Check unsupported platform

  - [x] Linux (WSL included)

  - [ ] Windows

  - [ ] MacOS

- [x] Seriously it's much better to open [cppman](https://github.com/aitjcize/cppman) instead of browser, but it's kind of hard to hack in.
  
  - [x] ~~`keywordprg` and~~ the `K` key support

- [ ] Fuzzy search: better sorter, use `vim.ui.select` when `telescope.nvim` is absent

- [ ] Compatibility check: for example, `statuscolumn` is available in a recent version.

- [ ] Hide the buffer instead of wiping it when the manpage is no longer displayed, so that we can have a browse history in the jumplist.

- [x] cppman position config support: `split`, `vsplit`, `tab`

- [ ] Seriously cppman and browser just share different index. Currently both use [Guyutongxue/cppreference-index](https://github.com/Guyutongxue/cppreference-index). It's better to have cppman use [aitjcize/cppman/cppman/lib/index.db](https://github.com/aitjcize/cppman/blob/master/cppman/lib/index.db) instead, which requires [kkharji/sqlite.lua](https://github.com/kkharji/sqlite.lua) to query, sigh.

# Credits

* [Guyutongxue/VSC_CppReference](https://github.com/Guyutongxue/VSC_CppReference): the plugin uses the index from [Guyutongxue/cppreference-index](https://github.com/Guyutongxue/cppreference-index).

* [skywind3000/vim-cppman](https://github.com/skywind3000/vim-cppman)
