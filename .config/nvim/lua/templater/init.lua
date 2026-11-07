-- Plain-text templates with {{name}} placeholders. The module knows nothing
-- about notes: callers supply a context and their own variables, and users add
-- more through setup().
local variables = require("templater.variables")

local M = {}

local user = {
	---@type string[]
	directories = {},
	---@type table<string, TemplaterVariable|false>
	variables = {},
}

-- Directories that other modules register as defaults; searched after the
-- user's own so a user template always wins.
---@type string[]
local fallback_directories = {}

---@class TemplaterOptions
---@field directories? string|string[] Directories searched first for `<name>.md`; `~` is expanded
---@field variables? table<string, TemplaterVariable|false> Added variables; `false` disables one

---@param options? TemplaterOptions
function M.setup(options)
	options = options or {}
	local directories = options.directories or {}
	user.directories = type(directories) == "string" and { directories } or directories
	user.variables = options.variables or {}
end

---Registers a default directory for templates, below the user's directories.
---@param directory string
function M.add_directory(directory)
	if not vim.tbl_contains(fallback_directories, directory) then
		table.insert(fallback_directories, directory)
	end
end

---@return string[] directories In search order
local function search_directories()
	local directories = {}
	for _, directory in ipairs(vim.list_extend(vim.list_extend({}, user.directories), fallback_directories)) do
		table.insert(directories, vim.fn.fnamemodify(vim.fn.expand(directory), ":p"))
	end
	return directories
end

---Replaces every {{name}} or {{name:argument}} with its variable's value.
---Placeholders without a variable are kept as written, so typos stay visible.
---@param text string
---@param context? table Fields for variables to read; `now` defaults to the current time
---@param extra_variables? table<string, TemplaterVariable|false> Caller variables; setup() variables override them
---@return string
function M.render(text, context, extra_variables)
	context = vim.tbl_extend("keep", context or {}, { now = os.time() })
	local resolvers = variables.resolvers(extra_variables or {}, user.variables)

	local rendered = text:gsub("{{(.-)}}", function(placeholder)
		local name, argument = placeholder:match("^%s*([%w_]+)%s*:(.*)$")
		name = name or placeholder:match("^%s*([%w_]+)%s*$")

		local resolver = name and resolvers[name]
		if not resolver then
			return nil
		end

		local ok, value = pcall(resolver, context, argument)
		if not ok then
			vim.notify(("templater: {{%s}} failed: %s"):format(placeholder, value), vim.log.levels.WARN)
			return nil
		end
		return value ~= nil and tostring(value) or ""
	end)
	return rendered
end

---@param name string Template name, resolved to `<directory>/<name>.md`
---@return string path
function M.find(name)
	local filename = name .. ".md"
	for _, directory in ipairs(search_directories()) do
		local path = vim.fs.joinpath(directory, filename)
		if vim.fn.filereadable(path) == 1 then
			return path
		end
	end
	error("templater: no template named " .. filename)
end

---@param name string
---@param context? table
---@param extra_variables? table<string, TemplaterVariable|false>
---@return string[] lines
function M.build(name, context, extra_variables)
	local text = table.concat(vim.fn.readfile(M.find(name)), "\n")
	return vim.split(M.render(text, context, extra_variables), "\n", { plain = true })
end

---@param path string
---@return string
local function real_path(path)
	return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

-- Template files hold placeholders instead of real values, so tools that
-- rewrite metadata on save must leave them alone.
---@param path string
---@return boolean
function M.is_template(path)
	local absolute = vim.fn.fnamemodify(path, ":p")
	-- The file may not exist yet, so resolve its directory rather than itself.
	local file_directory = real_path(vim.fs.dirname(absolute)) .. "/"

	for _, directory in ipairs(search_directories()) do
		if vim.startswith(file_directory, real_path(directory) .. "/") then
			return true
		end
	end
	return false
end

return M
