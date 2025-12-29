-- inspired by https://www.reddit.com/r/neovim/comments/1mx71rc/how_i_vastly_improved_my_lazy_loading_experience/
local state = require('zpack.state')
local utils = require('zpack.utils')
local event_handler = require('zpack.lazy_trigger.event')
local ft_handler = require('zpack.lazy_trigger.ft')
local cmd_handler = require('zpack.lazy_trigger.cmd')
local keys_handler = require('zpack.lazy_trigger.keys')

local M = {}

---@param spec zpack.Spec
---@param plugin zpack.Plugin?
---@return boolean
M.is_lazy = function(spec, plugin)
  if spec.lazy ~= nil then
    return spec.lazy
  end

  local event = utils.resolve_field(spec.event, plugin)
  local cmd = utils.resolve_field(spec.cmd, plugin)
  local ft = utils.resolve_field(spec.ft, plugin)
  local keys = utils.resolve_field(spec.keys, plugin)

  return (event ~= nil) or (cmd ~= nil) or (keys ~= nil and #keys > 0) or (ft ~= nil)
end

---@param ctx zpack.ProcessContext
M.process_all = function(ctx)
  if next(state.src_with_pending_build) ~= nil then
    return
  end

  for _, pack_spec in ipairs(ctx.registered_lazy_packs) do
    local registry_entry = state.spec_registry[pack_spec.src]
    local spec = registry_entry.spec
    local plugin = registry_entry.plugin

    local event = utils.resolve_field(spec.event, plugin)
    local ft = utils.resolve_field(spec.ft, plugin)

    if event then
      event_handler.setup(pack_spec, spec, event)
    end
    if ft then
      ft_handler.setup(pack_spec, ft)
    end
  end
  cmd_handler.setup(ctx.registered_lazy_packs)
  keys_handler.setup(ctx.registered_lazy_packs)
end

return M
