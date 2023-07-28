local M = {}

local index_path = vim.fn.stdpath('data') .. '/cppreference.json'
local job = nil
local index = nil
local options = {
  view = 'browser',
}

local log = function(msg, level)
  vim.notify(msg, level, { title = 'cppreference.nvim' })
end
local info = function(msg) log(msg, vim.log.levels.INFO) end
local error = function(msg) log(msg, vim.log.levels.ERROR) end

M.update_index = function(on_exit)
  if vim.fn.executable('curl') == 0 then
    error('Requires `curl` to fetch the index')
    return
  end
  info('Fetching the latest index...')
  return vim.system({
    'curl',
    'https://cdn.jsdelivr.net/npm/@gytx/cppreference-index/dist/generated.json',
    '--output',
    index_path,
  }, {}, function(res)
    if res.code == 0 then
      info('Successfully fetch the latest index')
      if type(on_exit) == 'function' then
        on_exit()
      end
    else
      error("Can't fetch the index:\n" .. res.stderr)
    end
  end)
end

M.setup = function(opts)
  options = vim.tbl_extend('force', options, opts or {})
  local setup = function()
    index = vim.json.decode(vim.fn.join(vim.fn.readfile(index_path), '\n'))
  end
  if vim.fn.filereadable(index_path) == 0 then
    job = M.update_index(vim.schedule_wrap(setup))
  else
    setup()
  end
end

local open_browser = function(url)
  if vim.fn.executable('xdg-open') == 0 then
    error('Requires `xdg-open` to open the page in the default browser')
  else
    vim.system { 'xdg-open', url }
  end
end

local cppman = function(keyword)
  if vim.fn.executable('cppman') == 0 then
    error('`cppman` is not available in $PATH')
    return
  end

  vim.system({
    'cppman',
    '--force-columns=' .. vim.fn.winwidth(0) - 2,
    keyword
  }, {}, vim.schedule_wrap(function(res)
    if string.find(res.stdout, 'No manual entry') then
      error("`cppman` can't locate this keyword, please use browser instead")
      return
    end
    local content = vim.split(res.stdout, '\n')

    local buf = vim.api.nvim_create_buf(false, true)
    local bufset = function(name, value) vim.api.nvim_set_option_value(name, value, { buf = buf }) end
    bufset('buftype', 'nofile')
    bufset('swapfile', false)
    bufset('bufhidden', 'delete')
    bufset('ft', 'man')
    bufset('readonly', false)
    bufset('modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.api.nvim_buf_set_name(buf, 'man://cppman/' .. keyword)
    bufset('readonly', true)
    bufset('modifiable', false)

    vim.cmd.split()
    local win = vim.api.nvim_get_current_win()
    local winset = function(name, value)
      vim.api.nvim_set_option_value(name, value, { win = win })
    end
    vim.api.nvim_win_set_buf(win, buf)
    winset('number', false)
    winset('relativenumber', false)
    winset('signcolumn', 'no')
    winset('colorcolumn', '0')
    vim.cmd 'normal! gg'

    -- set up highlight
    -- https://github.com/skywind3000/vim-cppman/blob/master/plugin/cppman.vim
    vim.cmd [[
  syntax clear
  syntax case ignore
  syntax match manReference       "[a-z_:+-\*][a-z_:+-~!\*<>]\+([1-9][a-z]\=)"
  syntax match manTitle           "^\w.\+([0-9]\+[a-z]\=).*"
  syntax match manSectionHeading  "^[a-z][a-z_ \-:]*[a-z]$"
  syntax match manSubHeading      "^\s\{3\}[a-z][a-z ]*[a-z]$"
  syntax match manOptionDesc      "^\s*[+-][a-z0-9]\S*"
  syntax match manLongOptionDesc  "^\s*--[a-z0-9-]\S*"
  syntax include @cppCode runtime! syntax/cpp.vim
  syntax match manCFuncDefinition  display "\<\h\w*\>\s*("me=e-1 contained
  syntax region manSynopsis start="^SYNOPSIS"hs=s+8 end="^\u\+\s*$"me=e-12 keepend contains=manSectionHeading,@cppCode,manCFuncDefinition
  syntax region manSynopsis start="^EXAMPLE"hs=s+7 end="^       [^ ]"he=s-1 keepend contains=manSectionHeading,@cppCode,manCFuncDefinition
  hi def link manTitle    Title
  hi def link manSectionHeading  Statement
  hi def link manOptionDesc    Constant
  hi def link manLongOptionDesc  Constant
  hi def link manReference    PreProc
  hi def link manSubHeading      Function
  hi def link manCFuncDefinition Function
  ]]
  end))
end

M.fuzzy_search = function(view)
  if job then
    if not job:is_closing() then
      info('Fetching the latest index, please wait until it finishes')
      return
    end
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local opts = require('telescope.themes').get_dropdown {}

  pickers.new(opts, {
    prompt_title = 'cppreference',
    sorter = conf.generic_sorter(opts),
    finder = finders.new_table {
      results = index,
      entry_maker = function(entry)
        return {
          value = entry.link,
          display = entry.name,
          ordinal = entry.name,
        }
      end,
    },
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        view = view or options.view
        if view == 'browser' then
          open_browser('https://en.cppreference.com/w/' .. selection.value)
        else
          cppman(selection.display)
        end
      end)
      return true
    end,
  }):find()
end

return M
