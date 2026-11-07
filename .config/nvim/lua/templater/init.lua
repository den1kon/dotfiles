-- Plain-text templates with {{name}} placeholders. The module knows nothing
-- about notes: callers supply a context and their own variables, and users add
-- more through setup().
local insert = require("templater.insert")
local variables = require("templater.variables")

local M = {}

local user = {
	---@type string[]
	directories = {},
	---@type table<string, TemplaterVariable|false>
	variables = {},
}

---@class TemplaterOptions
---@field directories? string|string[] Directories searched in order for a template; `~` is expanded
---@field variables? table<string, TemplaterVariable|false> Added variables; `false` disables one

---@param options? TemplaterOptions
function M.setup(options)
	options = options or {}
	local directories = options.directories or {}
	user.directories = type(directories) == "string" and { directories } or directories
	user.variables = options.variables or {}
	require("templater.command").register()
end

---@return string[] directories In search order
local function search_directories()
	local directories = {}
	for _, directory in ipairs(user.directories) do
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
		-- A text or number field of the context is a variable too, unless the
		-- name was explicitly disabled with `false`.
		if resolver == nil and name and (type(context[name]) == "string" or type(context[name]) == "number") then
			resolver = function()
				return context[name]
			end
		end
		if not resolver then
			return nil
		end

		local ok, value = pcall(resolver, context, argument)
		if not ok then
			vim.notify(("templater: {{%s}} failed: %s"):format(placeholder, value), vim.log.levels.WARN)
			return nil
		end
		-- nil and false mean "nothing to give": keep the placeholder as written.
		-- An empty string is a real value and renders as nothing.
		if value == nil or value == false then
			return nil
		end
		return tostring(value)
	end)
	return rendered
end

---A template is any file; its extension does not matter. `name` is either a
---path (it contains `/` or starts with `~`) or a name looked up as
---`<directory>/<name>` and then `<directory>/<name>.md` in each directory.
---@param name string
---@return string path
function M.find(name)
	if name:find("/", 1, true) or vim.startswith(name, "~") then
		local path = vim.fn.fnamemodify(vim.fn.expand(name), ":p")
		if vim.fn.filereadable(path) == 1 then
			return path
		end
		error("templater: no template file " .. name, 0)
	end

	for _, directory in ipairs(search_directories()) do
		for _, filename in ipairs({ name, name .. ".md" }) do
			local path = vim.fs.joinpath(directory, filename)
			if vim.fn.filereadable(path) == 1 then
				return path
			end
		end
	end
	error("templater: no template named " .. name, 0)
end

---File names of the templates in every directory, without duplicates.
---@return string[]
function M.list()
	local names, seen = {}, {}
	for _, directory in ipairs(search_directories()) do
		for name, kind in vim.fs.dir(directory) do
			if kind == "file" and not seen[name] then
				seen[name] = true
				table.insert(names, name)
			end
		end
	end
	table.sort(names)
	return names
end

---@param name string
---@param context? table
---@param extra_variables? table<string, TemplaterVariable|false>
---@return string[] lines
function M.build(name, context, extra_variables)
	local text = table.concat(vim.fn.readfile(M.find(name)), "\n")
	return vim.split(M.render(text, context, extra_variables), "\n", { plain = true })
end

---Renders a template and inserts it into the current buffer. The context holds
---`title` (file name without extension), `filename`, `directory` and `path` of
---the buffer, for variables to read.
---@param name string Template path or name, see find()
---@param position? TemplaterPosition Where to insert; defaults to "cursor"
function M.insert(name, position)
	local path = vim.api.nvim_buf_get_name(0)
	local lines = M.build(name, {
		title = vim.fn.fnamemodify(path, ":t:r"),
		filename = vim.fn.fnamemodify(path, ":t"),
		directory = vim.fn.fnamemodify(path, ":p:h"),
		path = path,
	})
	insert.insert(lines, position or "cursor")
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
