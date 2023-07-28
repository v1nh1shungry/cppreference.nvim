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

local is_updating = function()
  if job and not job:is_closing() then
    info('Fetching the latest index, please wait until it finishes')
    return true
  end
  return false
end

M.update_index = function(on_exit)
  if is_updating() then
    return
  end
  if vim.fn.executable('curl') == 0 then
    error('Requires `curl` to fetch the index')
    return
  end
  info('Fetching the latest index...')
  job = vim.system({
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
    M.update_index(vim.schedule_wrap(setup))
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

local function cppman(keyword)
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
    bufset('bufhidden', 'wipe')
    bufset('ft', 'man')
    bufset('readonly', false)
    bufset('modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.api.nvim_buf_set_name(buf, 'man://cppman/' .. keyword)
    bufset('readonly', true)
    bufset('modifiable', false)
    vim.fn.setbufvar(buf, 'cppman', true)

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
      vim.cmd.split()
    end
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
end

local display = function(entry)
  if options.view == 'browser' then
    open_browser('https://en.cppreference.com/w/' .. entry.link)
  else
    cppman(entry.name)
  end
end

local telescope = function(entries)
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
      results = entries,
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
        display({ name = selection.display, link = selection.value })
      end)
      return true
    end,
  }):find()
end

M.open = function(keyword)
  if is_updating() then
    return
  end
  keyword = keyword or ''
  local entries = {}
  for _, entry in ipairs(index) do
    if string.find(entry.name, keyword) then
      entries[#entries + 1] = entry
    end
  end
  if #entries == 0 then
    error("No manual for '" .. keyword .. "'")
    return
  elseif #entries == 1 then
    display({ name = entries[1].name, link = entries[1].link })
  else
    telescope(entries)
  end
end

M.fuzzy_search = function()
  if is_updating() then
    return
  end
  telescope(index)
end

return M
