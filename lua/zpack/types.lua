---@class KeySpec
---@field [1] string
---@field [2]? fun()
---@field noremap? boolean
---@field desc? string
---@field mode? string|string[]
---@field nowait? boolean

---@class Spec
---@field [1]? string Plugin short name (e.g., "user/repo"). Required if src is not provided
---@field src? string Custom git URL. Required if [1] is not provided
---@field init? fun()
---@field build? string|fun()
---@field enabled? boolean|(fun():boolean)
---@field cond? boolean|(fun():boolean)
---@field lazy? boolean
---@field version? string
---@field keys? KeySpec|KeySpec[]
---@field config? fun()
---@field event? string|string[]
---@field pattern? string|string[]
---@field cmd? string|string[]

return {}
