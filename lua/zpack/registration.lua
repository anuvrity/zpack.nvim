local state = require('zpack.state')
local lazy = require('zpack.lazy')
local util = require('zpack.utils')

local M = {}

M.register_all = function()
  vim.pack.add(state.vim_packs, {
    load = function(plugin)
      local pack_spec = plugin.spec
      local spec = state.spec_registry[pack_spec.src].spec
      if lazy.is_lazy(spec) then
        table.insert(state.registered_lazy_packs, pack_spec)
      else
        table.insert(state.registered_startup_packs, pack_spec)
      end
    end
  })

  table.sort(state.registered_startup_packs, util.compare_priority)
  table.sort(state.registered_lazy_packs, util.compare_priority)
end

return M
