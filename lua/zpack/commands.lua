local state = require('zpack.state')
local util = require('zpack.util')

local M = {}

M.clean_unused = function()
  local installed_packs = vim.pack.get()
  local specs_by_src = state.src_spec
  local to_delete = {}

  for _, pack in ipairs(installed_packs) do
    local src = pack.spec.src
    -- do not delete zpacks
    if not specs_by_src[src] and not string.find(src, 'zpack') then
      table.insert(to_delete, pack.spec)
    end
  end

  if #to_delete == 0 then
    util.schedule_notify("No unused plugins to clean", vim.log.levels.INFO)
    return
  end

  util.schedule_notify(("Deleting %d unused plugin(s)..."):format(#to_delete), vim.log.levels.INFO)

  local names_to_delete = {}
  for _, spec in ipairs(to_delete) do
    table.insert(names_to_delete, spec.name)
  end

  vim.pack.del(names_to_delete)

  for _, spec in ipairs(to_delete) do
    util.schedule_notify(("Deleted: %s"):format(spec.name or spec.src), vim.log.levels.INFO)
  end
end

M.setup = function()
  vim.api.nvim_create_user_command('ZUpdate', function()
    vim.pack.update()
  end, {
    desc = 'Update all plugins',
  })

  vim.api.nvim_create_user_command('ZClean', function()
    M.clean_unused()
  end, {
    desc = 'Remove unused plugins',
  })
end

return M
