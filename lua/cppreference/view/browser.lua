return function(url)
  if vim.fn.executable('xdg-open') == 0 then
    error('Requires `xdg-open` to open the page in the default browser')
  else
    vim.system { 'xdg-open', url }
  end
end
