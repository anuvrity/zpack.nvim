---@module 'zpack'

local M = {}

---@class ProcessContext
---@field vim_packs vim.pack.Spec[]
---@field src_with_startup_init string[]
---@field src_with_startup_config string[]
---@field startup_keys zpack.KeySpec[]
---@field registered_startup_packs vim.pack.Spec[]
---@field registered_lazy_packs vim.pack.Spec[]
---@field load boolean?
---@field confirm boolean?
---@field defaults ZpackDefaults

---@return ProcessContext
local function create_context(opts)
  opts = opts or {}
  return {
    vim_packs = {},
    src_with_startup_init = {},
    src_with_startup_config = {},
    startup_keys = {},
    registered_startup_packs = {},
    registered_lazy_packs = {},
    load = opts.load,
    confirm = opts.confirm,
    defaults = opts.defaults or {},
  }
end

local function check_version()
  if vim.fn.has('nvim-0.12') ~= 1 then
    vim.schedule(function()
      vim.notify('zpack.nvim requires Neovim 0.12+', vim.log.levels.ERROR)
    end)
    return false
  end
  return true
end

---@param plugins_dir string
---@param ctx ProcessContext
local import_specs_from_dir = function(plugins_dir, ctx)
  local plugin_paths = vim.fn.glob(vim.fn.stdpath('config') .. '/lua/' .. plugins_dir .. '/*.lua', false, true)

  for _, plugin_path in ipairs(plugin_paths) do
    local plugin_name = vim.fn.fnamemodify(plugin_path, ":t:r")
    local success, spec_item_or_list = pcall(require, plugins_dir .. "." .. plugin_name)

    if not success then
      require('zpack.utils').schedule_notify(
        ("Failed to load plugin spec for %s: %s"):format(plugin_name, spec_item_or_list),
        vim.log.levels.ERROR
      )
    elseif type(spec_item_or_list) ~= "table" then
      require('zpack.utils').schedule_notify(
        ("Invalid spec for %s, not a table: %s"):format(plugin_name, spec_item_or_list),
        vim.log.levels.ERROR
      )
    else
      require('zpack.import').import_specs(spec_item_or_list, ctx)
    end
  end
end

---@param ctx ProcessContext
local process_all = function(ctx)
  local hooks = require('zpack.hooks')
  local state = require('zpack.state')

  vim.api.nvim_clear_autocmds({ group = state.lazy_build_group })
  hooks.setup_build_tracking()
  require('zpack.registration').register_all(ctx)
  require('zpack.startup').process_all(ctx)
  require('zpack.lazy').process_all(ctx)
  hooks.run_pending_builds_on_startup(ctx)
  vim.api.nvim_clear_autocmds({ group = state.startup_group })
  hooks.setup_lazy_build_tracking()
end

---@class ZpackDefaults
---@field cond? boolean|(fun(plugin: zpack.Plugin):boolean)

---@class ZpackConfig
---@field spec? zpack.Spec[]
---@field plugins_dir? string
---@field disable_vim_loader? boolean
---@field confirm? boolean
---@field cmd_prefix? string
---@field defaults? ZpackDefaults

local config = {
  confirm = true,
  cmd_prefix = 'Z',
  defaults = {},
}

---@param opts? ZpackConfig
M.setup = function(opts)
  if not check_version() then return end

  local state = require('zpack.state')
  if state.is_setup then
    require('zpack.utils').schedule_notify('zpack.setup() has already been called', vim.log.levels.WARN)
    return
  end
  state.is_setup = true

  opts = opts or {}

  if opts.confirm ~= nil then
    config.confirm = opts.confirm
  end

  if opts.cmd_prefix ~= nil then
    config.cmd_prefix = opts.cmd_prefix
  end

  if opts.defaults ~= nil then
    config.defaults = opts.defaults
  end

  if not opts.disable_vim_loader then
    vim.loader.enable()
  end

  if opts.auto_import ~= nil then
    require('zpack.deprecation').notify_removed('auto_import')
  end

  local ctx = create_context({ confirm = config.confirm, defaults = config.defaults })

  -- import_specs handles both single spec and list; ipairs ignores non-numeric keys like `confirm`
  local spec = opts.spec or (opts[1] and opts) or nil
  if spec then
    require('zpack.import').import_specs(spec, ctx)
  else
    local plugins_dir = opts.plugins_dir or 'plugins'
    import_specs_from_dir(plugins_dir, ctx)
  end

  process_all(ctx)
  require('zpack.commands').setup(config.cmd_prefix)
end

---@deprecated Use setup({ spec = { ... } }) instead
M.add = function()
  require('zpack.deprecation').notify_removed('add')
end

return M
