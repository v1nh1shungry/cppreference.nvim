local M = {}
local search = require('cppreference.search')

local index_path = vim.fn.stdpath('data') .. '/cppreference.json'
local job = nil
local index = nil

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
  require('cppreference.config').setup(opts)
  local setup = function()
    index = vim.json.decode(vim.fn.join(vim.fn.readfile(index_path), '\n'))
  end
  if vim.fn.filereadable(index_path) == 0 then
    M.update_index(vim.schedule_wrap(setup))
  else
    setup()
  end
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
    require('cppreference.view')({ name = entries[1].name, link = entries[1].link })
  else
    search(entries)
  end
end

M.fuzzy_search = function()
  if is_updating() then
    return
  end
  search(index)
end

return M
