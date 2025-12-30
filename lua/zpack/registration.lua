local state = require('zpack.state')
local lazy = require('zpack.lazy')
local utils = require('zpack.utils')

local M = {}

---@param ctx zpack.ProcessContext
M.register_all = function(ctx)
  vim.pack.add(ctx.vim_packs, {
    confirm = ctx.confirm,
    load = function(plugin)
      local pack_spec = plugin.spec
      local registry_entry = state.spec_registry[pack_spec.src]

      if not registry_entry or not registry_entry.merged_spec then
        return
      end

      local spec = registry_entry.merged_spec --[[@as zpack.Spec]]
      registry_entry.plugin = plugin
      state.src_to_pack_spec[pack_spec.src] = pack_spec

      if not utils.check_cond(spec, plugin, ctx.defaults.cond) then
        return
      end

      table.insert(state.registered_plugin_names, pack_spec.name)
      state.unloaded_plugin_names[pack_spec.name] = true

      if spec.build then
        table.insert(state.plugin_names_with_build, pack_spec.name)
      end

      if spec.init then
        table.insert(ctx.src_with_init, pack_spec.src)
      end

      if lazy.is_lazy(spec, plugin, pack_spec.src) then
        table.insert(ctx.registered_lazy_packs, pack_spec)
      else
        table.insert(ctx.registered_startup_packs, pack_spec)
      end
    end
  })

  table.sort(ctx.registered_startup_packs, utils.compare_priority)
  table.sort(ctx.registered_lazy_packs, utils.compare_priority)
  table.sort(state.registered_plugin_names, function(a, b) return a:lower() < b:lower() end)
  table.sort(state.plugin_names_with_build, function(a, b) return a:lower() < b:lower() end)

  vim.list_extend(state.registered_plugins, ctx.registered_startup_packs)
  vim.list_extend(state.registered_plugins, ctx.registered_lazy_packs)
end

return M
