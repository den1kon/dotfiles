-- User options passed to require("notes").setup(). Defaults apply until then.
local M = {
	---@type table<string, NotesVariable>
	variables = {},
	---@type string|nil
	templates_dir = nil,
}

---@class NotesConfig
---@field variables? table<string, NotesVariable> Extra or replacement template variables
---@field templates_dir? string Directory searched first for `<note type>.md` templates

---@param options? NotesConfig
function M.setup(options)
	options = options or {}
	M.variables = options.variables or {}
	M.templates_dir = options.templates_dir
end

return M
