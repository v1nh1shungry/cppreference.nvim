local config = require('cppreference.config')
local error = require('cppreference.utils').error

local function cppman(keyword)
  if vim.fn.executable('cppman') == 0 then
    error('`cppman` is not available in $PATH')
    return
  end

  vim.system({
    'cppman',
    '-f',
    keyword
  }, {}, vim.schedule_wrap(function(res)
    if string.find(res.stdout, 'nothing appropriate') then
      error("No manual for '" .. keyword .. "'")
      return
    end

    if config.options.cppman.position == 'tab' then
      vim.cmd 'tab split'
    else
      local avail = -1
      for i = 1, vim.fn.winnr('$') do
        local nr = vim.fn.winbufnr(i)
        if vim.fn.getbufvar(nr, 'cppman', '') ~= '' then
          avail = i
        end
      end
      if avail > 0 then
        vim.cmd.exec("'" .. avail .. " wincmd w'")
      else
        if config.options.cppman.position == 'vsplit' then
          vim.cmd.vsplit()
        else
          vim.cmd.split()
        end
      end
    end
    vim.system({
      'cppman',
      '--force-columns=' .. vim.fn.winwidth(0) - 2,
      keyword
    }, {}, vim.schedule_wrap(function(r)
      local content = vim.split(r.stdout, '\n')
      local win = vim.api.nvim_get_current_win()
      local winset = function(name, value)
        vim.api.nvim_set_option_value(name, value, { win = win })
      end
      local buf = vim.api.nvim_create_buf(false, true)
      local bufset = function(name, value) vim.api.nvim_set_option_value(name, value, { buf = buf }) end
      bufset('buftype', 'nofile')
      bufset('swapfile', false)
      bufset('bufhidden', 'wipe')
      bufset('ft', 'man')
      bufset('readonly', false)
      bufset('modifiable', true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
      vim.api.nvim_buf_set_name(buf, 'man://cppman/' .. keyword)
      bufset('readonly', true)
      bufset('modifiable', false)
      vim.fn.setbufvar(buf, 'cppman', true)
      vim.api.nvim_win_set_buf(win, buf)
      winset('number', false)
      winset('relativenumber', false)
      winset('signcolumn', 'no')
      winset('colorcolumn', '0')
      winset('statuscolumn', '')

      -- set up highlight
      -- https://github.com/aitjcize/cppman/blob/master/cppman/lib/cppman.vim
      vim.cmd [[
      syntax clear
      syntax case ignore
      syntax match  manReference       "[a-z_:+-\*][a-z_:+-~!\*<>()]\+ ([1-9][a-z]\=)"
      syntax match  manTitle           "^\w.\+([0-9]\+[a-z]\=).*"
      syntax match  manSectionHeading  "^[a-z][a-z_ \-:]*[a-z]$"
      syntax match  manSubHeading      "^\s\{3\}[a-z][a-z ]*[a-z]$"
      syntax match  manOptionDesc      "^\s*[+-][a-z0-9]\S*"
      syntax match  manLongOptionDesc  "^\s*--[a-z0-9-]\S*"

      syntax include @cppCode runtime! syntax/cpp.vim
      syntax match manCFuncDefinition  display "\<\h\w*\>\s*("me=e-1 contained

      syntax region manSynopsis start="^SYNOPSIS"hs=s+8 end="^\u\+\s*$"me=e-12 keepend contains=manSectionHeading,@cppCode,manCFuncDefinition
      syntax region manSynopsis start="^EXAMPLE"hs=s+7 end="^       [^ ]"he=s-1 keepend contains=manSectionHeading,@cppCode,manCFuncDefinition

      hi def link manTitle           Title
      hi def link manSectionHeading  Statement
      hi def link manOptionDesc      Constant
      hi def link manLongOptionDesc  Constant
      hi def link manReference       PreProc
      hi def link manSubHeading      Function
      hi def link manCFuncDefinition Function
      ]]

      vim.keymap.set('n', 'K', function() cppman(vim.fn.expand('<cword>')) end, { buffer = buf })
      vim.keymap.set('v', 'K', function()
        -- https://github.com/nvim-telescope/telescope.nvim/issues/1923#issuecomment-1122642431
        vim.cmd 'noau normal! "vy"'
        local text = vim.fn.getreg 'v'
        vim.fn.setreg('v', {})
        text = string.gsub(text, '\n', '')
        cppman(text)
      end, { buffer = buf })
    end))
  end))
end

return cppman
