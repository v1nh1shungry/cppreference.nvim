return function(url)
  local cmd = nil
  local error = require('cppreference.utils').error
  if vim.fn.has('wsl') then
    cmd = { '/mnt/c/Windows/System32/cmd.exe', '/c', 'start' }
  else
    if vim.fn.executable('xdg-open') == 0 then
      error 'Requires `xdg-open` to open the browser'
    end
    cmd = { 'xdg-open' }
  end
  vim.system(vim.fn.extend(cmd, { url }))
end
