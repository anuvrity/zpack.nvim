local state = require('zpack.state')
local hooks = require('zpack.hooks')
local keymap = require('zpack.keymap')
local util = require('zpack.utils')

local M = {}

M.process_all = function()
  table.sort(state.src_with_startup_init, util.compare_priority)
  table.sort(state.src_with_startup_config, util.compare_priority)

  for _, src in ipairs(state.src_with_startup_init) do
    hooks.try_call_hook(src, 'init')
  end

  for _, pack_spec in ipairs(state.registered_startup_packs) do
    vim.cmd.packadd({ pack_spec.name, bang = true })
  end

  for _, src in ipairs(state.src_with_startup_config) do
    hooks.try_call_hook(src, 'config')
  end

  keymap.apply_keys(state.startup_keys)

  for _, pack_spec in ipairs(state.registered_startup_packs) do
    state.spec_registry[pack_spec.src].loaded = true
  end
end

return M
