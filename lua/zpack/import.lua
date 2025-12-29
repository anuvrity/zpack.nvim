local utils = require('zpack.utils')
local state = require('zpack.state')

local M = {}

local imported_modules = {}

---@param spec zpack.Spec
---@return boolean
local is_enabled = function(spec)
  if spec.enabled == false or (type(spec.enabled) == "function" and not spec.enabled()) then
    return false
  end
  return true
end

---Normalize plugin version using priority: version > sem_version > branch > tag > commit
---@param spec zpack.Spec
---@return string|vim.VersionRange|nil version
local normalize_version = function(spec)
  if spec.version ~= nil then
    return spec.version
  elseif spec.sem_version then
    return vim.version.range(spec.sem_version)
  elseif spec.branch then
    return spec.branch
  elseif spec.tag then
    return spec.tag
  elseif spec.commit then
    return spec.commit
  end
  return nil
end

---Normalize plugin source using priority: [1] > src > url > dir
---@param spec zpack.Spec
---@return string|nil source URL/path, or nil if invalid
---@return string|nil error message if validation fails
local normalize_source = function(spec)
  if spec[1] then
    return 'https://github.com/' .. spec[1]
  elseif spec.src then
    return spec.src
  elseif spec.url then
    return spec.url
  elseif spec.dir then
    return spec.dir
  else
    return nil, "spec must provide one of: [1], src, dir, or url"
  end
end

---@param spec zpack.Spec
---@return string
local get_source_url = function(spec)
  local src, err = normalize_source(spec)
  if not src then
    utils.schedule_notify(err, vim.log.levels.ERROR)
    error(err)
  end
  return src
end

---Check if value is a single spec (not a list of specs)
---@param value zpack.Spec|zpack.Spec[]
---@return boolean
local is_single_spec = function(value)
  return type(value[1]) == "string"
      or value.src ~= nil
      or value.dir ~= nil
      or value.url ~= nil
      or value.import ~= nil
end

---Check if spec is an import spec
---@param spec zpack.Spec
---@return boolean
local is_import_spec = function(spec)
  return spec.import ~= nil
end

---Load a spec module and import its specs
---@param full_module string Full module path (e.g., 'plugins.telescope')
---@param ctx zpack.ProcessContext
local load_spec_module = function(full_module, ctx)
  local success, spec_item_or_list = pcall(require, full_module)

  if not success then
    utils.schedule_notify(
      ("Failed to load plugin spec from %s: %s"):format(full_module, spec_item_or_list),
      vim.log.levels.ERROR
    )
  elseif type(spec_item_or_list) ~= "table" then
    utils.schedule_notify(
      ("Invalid spec from %s, not a table: %s"):format(full_module, spec_item_or_list),
      vim.log.levels.ERROR
    )
  else
    M.import_specs(spec_item_or_list, ctx)
  end
end

---Import specs from a module directory
---@param module_path string Module path (e.g., 'plugins' imports from lua/plugins/*.lua)
---@param ctx zpack.ProcessContext
local import_from_module = function(module_path, ctx)
  if imported_modules[module_path] then
    return
  end
  imported_modules[module_path] = true

  local lua_path = vim.fn.stdpath('config') .. '/lua/' .. module_path:gsub('%.', '/')

  for _, plugin_path in ipairs(vim.fn.glob(lua_path .. '/*.lua', false, true)) do
    local plugin_name = vim.fn.fnamemodify(plugin_path, ":t:r")
    load_spec_module(module_path .. "." .. plugin_name, ctx)
  end

  for _, init_path in ipairs(vim.fn.glob(lua_path .. '/*/init.lua', false, true)) do
    local dir_name = vim.fn.fnamemodify(init_path, ":h:t")
    load_spec_module(module_path .. "." .. dir_name, ctx)
  end
end

---@param spec_item_or_list zpack.Spec|zpack.Spec[]
---@param ctx zpack.ProcessContext
M.import_specs = function(spec_item_or_list, ctx)
  local specs = is_single_spec(spec_item_or_list)
      and { spec_item_or_list }
      or spec_item_or_list --[[@as zpack.Spec[] ]]

  for _, spec in ipairs(specs) do
    if not is_enabled(spec) then
      goto continue
    end

    if is_import_spec(spec) then
      import_from_module(spec.import, ctx)
      goto continue
    end

    local src = get_source_url(spec)
    if state.spec_registry[src] then
      goto continue
    end

    state.spec_registry[src] = { spec = spec, loaded = false }
    table.insert(ctx.vim_packs, { src = src, version = normalize_version(spec), name = spec.name })

    ::continue::
  end
end

M.reset_imported_modules = function()
  imported_modules = {}
end

return M
