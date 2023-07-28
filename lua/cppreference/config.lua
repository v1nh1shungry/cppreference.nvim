local M = {}

M.options = {
  view = 'browser',
  cppman = {
    position = 'split',
  },
}

M.setup = function(opts)
  M.options = vim.tbl_deep_extend('force', M.options, opts)
end

return M
