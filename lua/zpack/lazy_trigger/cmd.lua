local util = require('zpack.utils')
local state = require('zpack.state')
local loader = require('zpack.plugin_loader')

local M = {}

---@param registered_pack_specs vim.pack.Spec[]
M.setup = function(registered_pack_specs)
  local cmd_to_pack_specs = {}
  for _, pack_spec in ipairs(registered_pack_specs) do
    local registry_entry = state.spec_registry[pack_spec.src]
    local spec = registry_entry.merged_spec --[[@as zpack.Spec]]
    local plugin = registry_entry.plugin

    local cmd = util.resolve_field(spec.cmd, plugin)
    if cmd then
      local commands = util.normalize_string_list(cmd) --[[@as string[] ]]
      for _, c in ipairs(commands) do
        if not cmd_to_pack_specs[c] then
          cmd_to_pack_specs[c] = {}
        end
        table.insert(cmd_to_pack_specs[c], pack_spec)
      end
    end
  end

  -- Create user commands
  for cmd, pack_specs in pairs(cmd_to_pack_specs) do
    vim.api.nvim_create_user_command(cmd, function(cmd_args)
      pcall(vim.api.nvim_del_user_command, cmd)

      for _, pack_spec in ipairs(pack_specs) do
        loader.process_spec(pack_spec)
      end

      pcall(vim.api.nvim_cmd, {
        cmd = cmd,
        args = cmd_args.fargs,
      }, {})
    end, { nargs = '*' })
  end
end

return M
