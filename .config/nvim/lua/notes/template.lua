-- Renders {{name}} placeholders in note templates. Templates stay plain text:
-- all dynamic behavior lives in variable functions (see variables.lua).
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

return M
