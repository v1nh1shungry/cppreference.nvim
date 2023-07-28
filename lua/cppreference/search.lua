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
        require('cppreference.view')({ name = selection.display, link = selection.value })
      end)
      return true
    end,
  }):find()
end

return telescope
