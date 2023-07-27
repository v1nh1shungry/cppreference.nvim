# cppreference.nvim

A deadly silly plugin for opening [cppreference](http://cppreference.com/) page in your browser from your favorite editor.

# Showcase

![](https://user-images.githubusercontent.com/98312435/256507363-f7e826b7-a340-4e42-ade6-669d569853c0.gif)

**NOTE**: the GIF is kind of broken because of the screen recorder. I may fix it when available.

# Installation

1. Make sure you have `curl` installed available in `$PATH`.

2. [lazy.nvim](https://github.com/folke/lazy.nvim):
   
   ```lua
   {
    'v1nh1shungry/cppreference.nvim'
    config = true,
    dependencies = 'nvim-telescope/telescope.nvim',
   }
   ```

# Usage

* `require('cppreference').fuzzy_search()`

* `require('cppreference').update_index()`

# TODO

- [ ] `require('cppreference').open(word)`: directly offer the keyword, useful to play with `expand('<cword>')`

- [ ] Seriously it's much better to open [cppman](https://github.com/aitjcize/cppman) instead of browser, but it's kind of hard to hack in.

# Credits

* [Guyutongxue/VSC_CppReference](https://github.com/Guyutongxue/VSC_CppReference): the plugin uses the index from [Guyutongxue/cppreference-index](https://github.com/Guyutongxue/cppreference-index).
