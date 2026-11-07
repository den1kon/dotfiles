-- Renders {{name}} placeholders in note templates. Templates stay plain text:
-- all dynamic behavior lives in variable functions (see variables.lua).
local config = require("notes.config")
local variables = require("notes.variables")

local M = {}

---@param text string
---@param context NotesContext
---@param resolvers table<string, NotesVariable>
---@return string
function M.render(text, context, resolvers)
	local rendered = text:gsub("{{(.-)}}", function(placeholder)
		local name, argument = placeholder:match("^%s*([%w_]+)%s*:(.*)$")
		name = name or placeholder:match("^%s*([%w_]+)%s*$")

		local resolver = name and resolvers[name]
		if not resolver then
			-- Returning nil keeps the placeholder, which makes typos visible.
			return nil
		end

		local value = resolver(context, argument)
		return value ~= nil and tostring(value) or ""
	end)
	return rendered
end

-- A template in the user's templates_dir replaces the bundled one of the same
-- name, so templates can live next to the notes they generate.
---@param name string Note type, such as "weekly"
---@return string path
function M.find(name)
	local filename = name .. ".md"

	if config.templates_dir then
		local directory = vim.fn.fnamemodify(vim.fn.expand(config.templates_dir), ":p")
		local custom = vim.fs.joinpath(directory, filename)
		if vim.fn.filereadable(custom) == 1 then
			return custom
		end
	end

	local bundled = vim.api.nvim_get_runtime_file("lua/notes/templates/" .. filename, false)[1]
	if not bundled then
		error("notes: no template named " .. filename)
	end
	return bundled
end

---@param name string Note type, such as "weekly"
---@param context NotesContext
---@param note_variables? table<string, NotesVariable> Variables specific to this note type
---@return string[] lines
function M.build(name, context, note_variables)
	local text = table.concat(vim.fn.readfile(M.find(name)), "\n")
	-- Precedence: built-ins, then the note type, then the user's own variables.
	local resolvers = variables.resolvers(note_variables or {}, config.variables)
	return vim.split(M.render(text, context, resolvers), "\n", { plain = true })
end

return M
