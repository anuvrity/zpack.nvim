local M = {}

---@type boolean
M.is_setup = false

M.lazy_group = vim.api.nvim_create_augroup('LazyPack', { clear = true })
M.startup_group = vim.api.nvim_create_augroup('StartupPack', { clear = true })
M.lazy_build_group = vim.api.nvim_create_augroup('LazyBuildPack', { clear = true })

---@type { [string]: zpack.RegistryEntry }
M.spec_registry = {}

---@type number
M.import_order = 0

---@type { [string]: { [string]: true } }
M.dependency_graph = {}

---@type { [string]: { [string]: true } }
M.reverse_dependency_graph = {}

---@type { [string]: vim.pack.Spec }
M.src_to_pack_spec = {}

---@type { [string]: boolean }
M.lazy_parent_cache = {}

---@type { [string]: boolean }
M.resolve_main_not_found = {}

---@type { [string]: boolean }
M.src_with_pending_build = {}

---@type vim.pack.Spec[]
M.registered_plugins = {}
---@type string[]
M.registered_plugin_names = { 'zpack.nvim' }
---@type string[]
M.plugin_names_with_build = {}
---@type { [string]: boolean }
M.unloaded_plugin_names = {}

return M
