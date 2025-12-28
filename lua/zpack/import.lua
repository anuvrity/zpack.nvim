local utils = require('zpack.utils')
local state = require('zpack.state')

local M = {}

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
end

---@param spec_item_or_list zpack.Spec|zpack.Spec[]
---@param ctx ProcessContext
M.import_specs = function(spec_item_or_list, ctx)
  local specs = is_single_spec(spec_item_or_list)
      and { spec_item_or_list }
      or spec_item_or_list --[[@as zpack.Spec[] ]]

  for _, spec in ipairs(specs) do
    if not is_enabled(spec) then
      goto continue
    end

    local src = get_source_url(spec)
    -- already imported, skip
    if state.spec_registry[src] then
      goto continue
    end

    state.spec_registry[src] = { spec = spec, loaded = false }
    table.insert(ctx.vim_packs, { src = src, version = normalize_version(spec), name = spec.name })

    ::continue::
  end
end

return M
