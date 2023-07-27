local M = {}

local index_path = vim.fn.stdpath('data') .. '/cppreference.json'
local job = nil
local index = nil

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

M.setup = function()
  local setup = function()
    index = vim.json.decode(vim.fn.join(vim.fn.readfile(index_path), '\n'))
  end
  if vim.fn.filereadable(index_path) == 0 then
    job = M.update_index(vim.schedule_wrap(setup))
  else
    setup()
  end
end

M.fuzzy_search = function()
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
        if vim.fn.executable('xdg-open') == 0 then
          error('Requires `xdg-open` to open the page in the default browser')
        else
          vim.system {
            'xdg-open',
            'https://en' .. '.cppreference.com/w/' .. selection.value,
          }
        end
      end)
      return true
    end,
  }):find()
end

return M
