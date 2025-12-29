local state = require('zpack.state')
local keymap = require('zpack.keymap')
local utils = require('zpack.utils')

local M = {}

---Run auto-setup: require(main).setup(opts)
---@param src string
---@param main string
---@param resolved_opts table
---@return boolean success
local function run_auto_setup(src, main, resolved_opts)
  local ok, mod_or_err = pcall(require, main)
  if not ok then
    utils.schedule_notify(("Failed to require '%s' for %s: %s"):format(main, src, mod_or_err), vim.log.levels.ERROR)
    return false
  end
  if type(mod_or_err) ~= "table" or type(mod_or_err.setup) ~= "function" then
    utils.schedule_notify(("Module '%s' for %s has no setup() function"):format(main, src), vim.log.levels.WARN)
    return false
  end
  local mod = mod_or_err

  local success, err = pcall(mod.setup, resolved_opts)
  if not success then
    utils.schedule_notify(("Failed to run setup for %s: %s"):format(src, err), vim.log.levels.ERROR)
    return false
  end

  return true
end

---Run config/setup for a plugin
---@param src string
---@param plugin zpack.Plugin
---@param spec zpack.Spec
function M.run_config(src, plugin, spec)
  local resolved_opts = utils.resolve_field(spec.opts, plugin) or {}
  local main = utils.resolve_main(plugin, spec)

  if type(spec.config) == "function" then
    local config_fn = spec.config --[[@as fun(plugin: zpack.Plugin, opts: table)]]
    local ok, err = pcall(config_fn, plugin, resolved_opts)
    if not ok then
      utils.schedule_notify(("Failed to run config for %s: %s"):format(src, err), vim.log.levels.ERROR)
    end
  elseif spec.config == true or spec.opts ~= nil then
    if not main then
      utils.schedule_notify(
        ("Could not determine main module for %s. Please set `main` explicitly or use `config = function() ... end`.")
        :format(src),
        vim.log.levels.WARN
      )
    else
      run_auto_setup(src, main, resolved_opts)
    end
  end
end

---@param pack_spec vim.pack.Spec
M.process_spec = function(pack_spec, opts)
  opts = opts or {}
  local registry_entry = state.spec_registry[pack_spec.src]

  if registry_entry.loaded then
    return
  end

  local spec = registry_entry.spec
  local plugin = registry_entry.plugin --[[@as zpack.Plugin]]

  vim.cmd.packadd({ pack_spec.name, bang = opts.bang })

  if spec.config or spec.opts ~= nil then
    M.run_config(pack_spec.src, plugin, spec)
  end

  local keys = utils.resolve_field(spec.keys, plugin)
  if keys then
    keymap.apply_keys(keys)
  end

  registry_entry.loaded = true
  state.unloaded_plugin_names[pack_spec.name] = nil
end

return M
