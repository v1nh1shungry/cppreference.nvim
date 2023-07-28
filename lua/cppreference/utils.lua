local M = {}

local log = function(msg, level)
  vim.notify(msg, level, { title = 'cppreference.nvim' })
end

M.info = function(msg) log(msg, vim.log.levels.INFO) end

M.error = function(msg) log(msg, vim.log.levels.ERROR) end

return M
