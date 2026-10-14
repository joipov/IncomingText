---@meta

--- Forever secret-value helpers. Ketho Core does not declare them.

---@type fun(value: any): boolean
issecretvalue = issecretvalue

---@type fun(value: any): boolean
canaccessvalue = canaccessvalue

---@param name string
---@return table
function CreateSettingsListSectionHeaderInitializer(name) end

---@param label string
---@param buttonText string
---@param onClick function
---@param tooltip string|nil
---@param addSearchTags boolean
---@return table
function CreateSettingsButtonInitializer(label, buttonText, onClick, tooltip, addSearchTags) end

-- Optional frames are read through `_G.<name>`. LuaLS
-- has the Lua builtins disabled, so `_G` has no index type and every such read
-- is an undefined-field. Type `_G` so those reads resolve.
---@type table<string, any>
_G = _G
