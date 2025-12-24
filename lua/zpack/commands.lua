local state = require('zpack.state')
local util = require('zpack.utils')
local hooks = require('zpack.hooks')

local M = {}

local filter_completions = function(list, prefix)
  if prefix == '' then return list end
  local lower_prefix = prefix:lower()
  return vim.tbl_filter(function(name)
    return name:lower():find(lower_prefix, 1, true) == 1
  end, list)
end

local get_plugin_or_notify = function(plugin_name)
  local ok, result = pcall(vim.pack.get, { plugin_name })
  if not ok or not result or not result[1] then
    util.schedule_notify(('Plugin "%s" not found'):format(plugin_name), vim.log.levels.ERROR)
    return nil
  end
  return result[1]
end

local remove_from_state = function(plugin_name, src)
  state.spec_registry[src] = nil
  state.src_with_pending_build[src] = nil

  state.registered_plugins = vim.tbl_filter(function(spec)
    return spec.name ~= plugin_name
  end, state.registered_plugins)

  state.registered_plugin_names = vim.tbl_filter(function(name)
    return name ~= plugin_name
  end, state.registered_plugin_names)

  state.plugin_names_with_build = vim.tbl_filter(function(name)
    return name ~= plugin_name
  end, state.plugin_names_with_build)
end

local clear_all_state = function()
  state.spec_registry = {}
  state.src_with_pending_build = {}
  state.registered_plugins = {}
  state.registered_plugin_names = {}
  state.plugin_names_with_build = {}
end

M.clean_unused = function()
  local to_delete = {}

  for _, spec in ipairs(state.registered_plugins) do
    if not state.spec_registry[spec.src] and not string.find(spec.src, 'zpack') then
      table.insert(to_delete, spec.name)
    end
  end

  if #to_delete == 0 then
    util.schedule_notify("No unused plugins to clean", vim.log.levels.INFO)
    return
  end

  util.schedule_notify(("Deleting %d unused plugin(s)..."):format(#to_delete), vim.log.levels.INFO)

  vim.pack.del(to_delete)
end

M.setup = function()
  vim.api.nvim_create_user_command('ZUpdate', function(opts)
    local plugin_name = opts.args
    if plugin_name == '' then
      vim.pack.update()
    else
      if not get_plugin_or_notify(plugin_name) then
        return
      end
      vim.pack.update({ plugin_name })
    end
  end, {
    nargs = '?',
    desc = 'Update all plugins or a specific plugin',
    complete = function(prefix) return filter_completions(state.registered_plugin_names, prefix) end,
  })

  vim.api.nvim_create_user_command('ZClean', function()
    M.clean_unused()
  end, {
    desc = 'Remove unused plugins',
  })

  vim.api.nvim_create_user_command('ZBuild', function(opts)
    local plugin_name = opts.args
    if plugin_name == '' then
      if not opts.bang then
        util.schedule_notify('Use :ZBuild! to run build hooks for all plugins', vim.log.levels.WARN)
        return
      end
      hooks.run_all_builds()
      return
    end

    local pack = get_plugin_or_notify(plugin_name)
    if not pack then
      return
    end

    local registry_entry = state.spec_registry[pack.spec.src]
    if not registry_entry or not registry_entry.spec.build then
      util.schedule_notify(('Plugin "%s" has no build hook'):format(plugin_name), vim.log.levels.WARN)
      return
    end

    hooks.load_all_unloaded_plugins()
    hooks.execute_build(registry_entry.spec.build)
    util.schedule_notify(('Running build hook for %s'):format(plugin_name), vim.log.levels.INFO)
  end, {
    nargs = '?',
    bang = true,
    desc = 'Run build hook for a specific plugin or all plugins',
    complete = function(prefix) return filter_completions(state.plugin_names_with_build, prefix) end,
  })

  vim.api.nvim_create_user_command('ZDelete', function(opts)
    local plugin_name = opts.args
    if plugin_name == '' then
      if not opts.bang then
        util.schedule_notify(
          'Use :ZDelete! to confirm deletion of all installed plugin(s)',
          vim.log.levels.WARN
        )
        return
      end
      local names = {}
      for i = #state.registered_plugins, 1, -1 do
        table.insert(names, state.registered_plugins[i].name)
      end

      util.schedule_notify(("Deleting all %d installed plugin(s)..."):format(#names), vim.log.levels.INFO)
      vim.pack.del(names)
      clear_all_state()
      util.schedule_notify(
        "All plugins deleted. This can result in errors in your current session. Restart Neovim to re-install them or remove them from your spec.",
        vim.log.levels.WARN)
      return
    end

    local pack = get_plugin_or_notify(plugin_name)
    if not pack then
      return
    end

    vim.pack.del({ plugin_name })
    remove_from_state(plugin_name, pack.spec.src)
    util.schedule_notify(
      ('%s deleted. This can result in errors in your current session. Restart Neovim to re-install it or remove it from your spec.')
        :format(plugin_name),
      vim.log.levels.WARN
    )
  end, {
    nargs = '?',
    bang = true,
    desc = 'Delete all plugins or a specific plugin',
    complete = function(prefix) return filter_completions(state.registered_plugin_names, prefix) end,
  })
end

return M
