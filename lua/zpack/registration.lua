local state = require('zpack.state')
local lazy = require('zpack.lazy')
local utils = require('zpack.utils')

local M = {}

---@param ctx ProcessContext
M.register_all = function(ctx)
  vim.pack.add(ctx.vim_packs, {
    confirm = ctx.confirm,
    load = function(plugin)
      local pack_spec = plugin.spec
      local registry_entry = state.spec_registry[pack_spec.src]
      local spec = registry_entry.spec

      registry_entry.plugin = plugin

      if not utils.check_cond(spec, plugin) then
        return
      end

      table.insert(state.registered_plugin_names, pack_spec.name)
      if spec.build then
        table.insert(state.plugin_names_with_build, pack_spec.name)
      end

      if lazy.is_lazy(spec, plugin) then
        table.insert(ctx.registered_lazy_packs, pack_spec)
        if spec.init then
          table.insert(ctx.src_with_startup_init, pack_spec.src)
        end
      else
        table.insert(ctx.registered_startup_packs, pack_spec)

        if spec.config then
          table.insert(ctx.src_with_startup_config, pack_spec.src)
        end

        if spec.init then
          table.insert(ctx.src_with_startup_init, pack_spec.src)
        end

        local keys = utils.resolve_field(spec.keys, plugin)
        if keys then
          for _, key in ipairs(utils.normalize_keys(keys)) do
            table.insert(ctx.startup_keys, key)
          end
        end
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
