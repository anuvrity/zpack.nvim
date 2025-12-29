local state = require('zpack.state')
local hooks = require('zpack.hooks')
local keymap = require('zpack.keymap')
local utils = require('zpack.utils')

local M = {}

---@param pack_spec vim.pack.Spec
M.process_spec = function(pack_spec, opts)
  opts = opts or {}
  local registry_entry = state.spec_registry[pack_spec.src]

  if registry_entry.loaded then
    return
  end

  local spec = registry_entry.spec
  local plugin = registry_entry.plugin

  vim.cmd.packadd({ pack_spec.name, bang = opts.bang })

  if spec.config then
    hooks.try_call_hook(pack_spec.src, 'config')
  end

  local keys = utils.resolve_field(spec.keys, plugin)
  if keys then
    keymap.apply_keys(keys)
  end

  registry_entry.loaded = true
  state.unloaded_plugin_names[pack_spec.name] = nil
end

return M
