local state = require('zpack.state')

local M = {}

M.schedule_notify = function(msg, level)
  vim.schedule(function()
    vim.notify(msg, level)
  end)
end

---Get priority for a plugin source (default: 50)
---@param src string
---@return number
M.get_priority = function(src)
  local entry = state.spec_registry[src]
  if not entry then
    return 50
  end
  return entry.spec.priority or 50
end

---Comparison function for sorting items by priority (descending)
---Works with both source strings and vim.pack.Spec objects
---@param a string|vim.pack.Spec
---@param b string|vim.pack.Spec
---@return boolean
M.compare_priority = function(a, b)
  local src_a = type(a) == "string" and a or a.src
  local src_b = type(b) == "string" and b or b.src
  return M.get_priority(src_a) > M.get_priority(src_b)
end

---Normalize keys to a consistent format
---@param keys zpack.KeySpec|zpack.KeySpec[]|string|string[]
---@return zpack.KeySpec[]
M.normalize_keys = function(keys)
  -- Normalize to always be an array
  local key_list = (type(keys) == "string" or (keys[1] and type(keys[1]) == "string"))
      and { keys }
      or keys --[[@as string[]|KeySpec[] ]]

  local result = {}
  for _, key in ipairs(key_list) do
    if type(key) == "string" then
      table.insert(result, { key })
    else
      table.insert(result, key)
    end
  end
  return result
end

---@param val string|string[]
---@return string[]
M.normalize_string_list = function(val)
  return type(val) == "string" and { val } or val --[[@as string[] ]]
end

---Create an autocmd with callback
---@param event string|string[]
---@param callback function
---@param opts? table Optional opts (group, once, pattern, buffer, etc.)
---@return number Autocmd ID
M.autocmd = function(event, callback, opts)
  opts = opts or {}
  return vim.api.nvim_create_autocmd(event, vim.tbl_extend('force', {
    callback = callback,
  }, opts))
end

---Resolve a field that may be a function
---@param field any
---@param plugin zpack.Plugin?
---@return any
M.resolve_field = function(field, plugin)
  if type(field) == "function" then
    return field(plugin)
  end
  return field
end

---Check if spec.cond passes (with optional default fallback)
---@param spec zpack.Spec
---@param plugin zpack.Plugin?
---@param default_cond? boolean|(fun(plugin: zpack.Plugin):boolean)
---@return boolean
M.check_cond = function(spec, plugin, default_cond)
  local cond = spec.cond
  if cond == nil then
    cond = default_cond
  end

  if cond == false or (type(cond) == "function" and not cond(plugin)) then
    return false
  end
  return true
end

---Normalize a plugin name for module matching
---Inspired by lazy.nvim's Util.normname()
---@param name string
---@return string
M.normalize_name = function(name)
  return name:lower():gsub("^n?vim%-", ""):gsub("%.n?vim$", ""):gsub("[%.%-]lua", ""):gsub("[^a-z]+", "")
end

---Get the main module for a plugin (for auto-setup)
---Inspired by lazy.nvim's loader.get_main()
---Results are cached in spec_registry entry._main
---@param src string Plugin source in spec_registry
---@return string? main_module The main module name, or nil if not found
M.get_main = function(src)
  local entry = state.spec_registry[src]
  if not entry or not entry.plugin then
    return nil
  end

  if entry._main ~= nil then
    return entry._main or nil
  end

  local spec = entry.spec
  local path = entry.plugin.path

  if spec.main then
    entry._main = spec.main
    return spec.main
  end

  local name = entry.plugin.spec.name
  if not name then
    entry._main = false
    return nil
  end

  if name:match("^mini%.") and name ~= "mini.nvim" then
    entry._main = name
    return name
  end

  local norm_name = M.normalize_name(name)
  local lua_dir = path .. "/lua"

  local lua_files = vim.fn.glob(lua_dir .. "/**/*.lua", false, true)
  for _, file in ipairs(lua_files) do
    local rel_path = file:match("lua/(.+)%.lua$")
    if rel_path then
      local mod = rel_path:gsub("/", "."):gsub("%.init$", "")
      if M.normalize_name(mod) == norm_name then
        entry._main = mod
        return mod
      end
    end
  end

  entry._main = false
  return nil
end

return M
