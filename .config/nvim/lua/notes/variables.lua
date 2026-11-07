-- Variables available to every note template as {{name}} or {{name:argument}}.
-- A variable is a function, so values are computed only when a template uses
-- them.
local M = {}

---@class NotesContext
---@field title string Period key of the note, such as 2026-10-04 or 2026-W40
---@field directory string Directory that holds the notes
---@field now integer Unix timestamp used for generated dates

---Returns the text to insert, or nil to insert nothing. The argument is the
---text after the colon in {{name:argument}}.
---@alias NotesVariable fun(context: NotesContext, argument?: string): string|number|nil

---@param context NotesContext
---@return string
local function utc_timestamp(context)
	return os.date("!%Y-%m-%dT%H:%M:%SZ", context.now)
end

---@type table<string, NotesVariable>
M.builtin = {
	title = function(context)
		return context.title
	end,
	id = function(context)
		return context.now
	end,
	created_at = utc_timestamp,
	updated_at = utc_timestamp,
	-- Local date; the argument is an os.date format, e.g. {{date:%A}}.
	date = function(context, format)
		return os.date(format or "%Y-%m-%d", context.now)
	end,
}

---Later tables win, so a note type can refine a built-in variable.
---@param ... table<string, NotesVariable>
---@return table<string, NotesVariable>
function M.resolvers(...)
	return vim.tbl_extend("force", M.builtin, {}, ...)
end

return M
