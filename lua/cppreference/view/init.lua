return function(entry)
  local config = require('cppreference.config')
  if config.options.view == 'cppman' then
    require('cppreference.view.cppman')(entry.name)
  else
    require('cppreference.view.browser')('https://en.cppreference.com/w/' .. entry.link)
  end
end
