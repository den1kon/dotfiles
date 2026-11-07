-- Predefined template variables. A variable is a function, so a value is
-- computed only when a template uses it. Anything note-specific belongs in
-- the caller's own variables, not here.
local M = {}

---@class TemplaterContext
---@field now integer Unix timestamp that every date and time variable uses
---@field title? string
---@field [string] any Extra fields supplied by the caller, readable by variables

---Returns the value to insert; anything but nil is converted with tostring, so
---an empty string inserts nothing and false inserts "false". Returning nil
---means the variable had nothing to give: the placeholder stays in the output
---exactly as written, so it is visible that nothing happened. Raising an error
---does the same and also shows a warning. The argument is the text after the
---first colon in {{name:argument}}.
---@alias TemplaterVariable fun(context: TemplaterContext, argument?: string): string|number|boolean|nil

local ISO_8601_UTC = "!%Y-%m-%dT%H:%M:%SZ"

-- Runs `code` as an expression first, so {{lua:os.date("%d")}} needs no
-- `return`; statements are accepted when it is not a valid expression.
---@type TemplaterVariable
local function run_lua(context, code)
	local environment = setmetatable({ context = context }, { __index = _G })

	local chunk = load("return " .. code, "=template", "t", environment)
	if not chunk then
		local compile_error
		chunk, compile_error = load(code, "=template", "t", environment)
		if not chunk then
			error(compile_error, 0)
		end
	end
	return chunk()
end

---@type table<string, TemplaterVariable>
M.builtin = {
	-- Whatever the caller passed as context.title, such as a note's name.
	title = function(context)
		return context.title
	end,
	-- Unix timestamp, usable as a unique identifier.
	id = function(context)
		return context.now
	end,
	-- Local date and time; the argument is an os.date format, e.g. {{date:%A}}.
	date = function(context, format)
		return os.date(format or "%Y-%m-%d", context.now)
	end,
	time = function(context, format)
		return os.date(format or "%H:%M", context.now)
	end,
	-- ISO 8601 UTC timestamp, or UTC formatted with the argument.
	utc = function(context, format)
		return os.date(format and ("!" .. format) or ISO_8601_UTC, context.now)
	end,
	-- Lua code evaluated with `context` and the usual globals in scope.
	lua = run_lua,
}

---Later tables win, and a `false` entry removes a variable entirely.
---@param ... table<string, TemplaterVariable|false>
---@return table<string, TemplaterVariable|false>
function M.resolvers(...)
	return vim.tbl_extend("force", M.builtin, {}, ...)
end

return M
