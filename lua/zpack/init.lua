---@module 'zpack'

local M = {}

---@class zpack.ProcessContext
---@field vim_packs vim.pack.Spec[]
---@field src_with_init string[]
---@field registered_startup_packs vim.pack.Spec[]
---@field registered_lazy_packs vim.pack.Spec[]
---@field load boolean?
---@field confirm boolean?
---@field defaults zpack.Config.Defaults
---@field is_dependency? boolean Internal: Whether currently importing as dependency

---@return zpack.ProcessContext
local function create_context(opts)
  opts = opts or {}
  return {
    vim_packs = {},
    src_with_init = {},
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

---@param ctx zpack.ProcessContext
local process_all = function(ctx)
  local hooks = require('zpack.hooks')
  local state = require('zpack.state')

  vim.api.nvim_clear_autocmds({ group = state.lazy_build_group })
  require('zpack.merge').resolve_all()
  hooks.setup_build_tracking()
  require('zpack.registration').register_all(ctx)
  require('zpack.startup').process_all(ctx)
  require('zpack.lazy').process_all(ctx)
  hooks.run_pending_builds_on_startup(ctx)
  vim.api.nvim_clear_autocmds({ group = state.startup_group })
  hooks.setup_lazy_build_tracking()
end

---@class zpack.Config.Defaults
---@field cond? boolean|(fun(plugin: zpack.Plugin):boolean)
---@field confirm? boolean

---@class zpack.Config.Performance
---@field vim_loader? boolean

---@class zpack.Config
---@field spec? zpack.Spec[]
---@field cmd_prefix? string
---@field defaults? zpack.Config.Defaults
---@field performance? zpack.Config.Performance
---@field plugins_dir? string @deprecated Use { import = 'dir' } in spec instead
---@field confirm? boolean @deprecated Use defaults.confirm instead
---@field disable_vim_loader? boolean @deprecated Use performance.vim_loader instead

local config = {
  cmd_prefix = 'Z',
  defaults = { confirm = true },
  performance = { vim_loader = true },
}

---@param opts? zpack.Config
M.setup = function(opts)
  if not check_version() then return end

  local state = require('zpack.state')
  if state.is_setup then
    require('zpack.utils').schedule_notify('zpack.setup() has already been called', vim.log.levels.WARN)
    return
  end
  state.is_setup = true

  opts = opts or {}
  local deprecation = require('zpack.deprecation')

  if opts.cmd_prefix ~= nil then
    config.cmd_prefix = opts.cmd_prefix
  end

  if opts.defaults ~= nil then
    config.defaults = vim.tbl_extend('force', config.defaults, opts.defaults)
  end

  if opts.performance ~= nil then
    config.performance = vim.tbl_extend('force', config.performance, opts.performance)
  end

  -- Handle deprecated opts.confirm
  if opts.confirm ~= nil then
    deprecation.notify_deprecated('confirm')
    config.defaults.confirm = opts.confirm
  end

  -- Handle deprecated opts.disable_vim_loader
  if opts.disable_vim_loader ~= nil then
    deprecation.notify_deprecated('disable_vim_loader')
    config.performance.vim_loader = not opts.disable_vim_loader
  end

  if config.performance.vim_loader then
    vim.loader.enable()
  end

  if opts.auto_import ~= nil then
    deprecation.notify_removed('auto_import')
  end

  local ctx = create_context({ confirm = config.defaults.confirm, defaults = config.defaults })
  local import = require('zpack.import')

  local spec = opts.spec or (opts[1] and opts) or nil
  if spec then
    import.import_specs(spec, ctx)
  end

  if opts.plugins_dir ~= nil then
    deprecation.notify_deprecated('plugins_dir')
    import.import_specs({ import = opts.plugins_dir }, ctx)
  elseif not spec then
    import.import_specs({ import = 'plugins' }, ctx)
  end

  process_all(ctx)
  require('zpack.commands').setup(config.cmd_prefix)
end

---@deprecated Use setup({ spec = { ... } }) instead
M.add = function()
  require('zpack.deprecation').notify_removed('add')
end

return M
