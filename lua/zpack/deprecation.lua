local utils = require('zpack.utils')

local M = {}

M.removed = {
  add = {
    message = "zpack.add() has been removed. Pass specs directly to setup():",
    replacement = [[
require('zpack').setup({ { 'user/plugin' } })
require('zpack').setup({ spec = { { 'user/plugin' } } }) -- or via the spec field
]]
  },
  auto_import = {
    message = "auto_import option has been removed. Pass specs directly to setup():",
    replacement = [[
require('zpack').setup({ { 'user/plugin' } })
require('zpack').setup({ spec = { { 'user/plugin' } } }) -- or via the spec field
]]
  },
}

M.notify_removed = function(key)
  local entry = M.removed[key]
  if not entry then return end
  utils.schedule_notify(
    ("[zpack] REMOVED: %s\n\n%s"):format(entry.message, entry.replacement),
    vim.log.levels.WARN
  )
end

return M
