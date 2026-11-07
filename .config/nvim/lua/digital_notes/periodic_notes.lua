-- Daily and weekly notes: a file named after the day or week in the working
-- directory, filled from a template when it is new. The note types are data, so
-- another kind, such as a monthly note, is one more entry below.
local previous_note = require("digital_notes.previous_note")
local templater = require("templater")

local M = {}

---@class PeriodicNoteType
---@field command string User command that opens a note of this type
---@field description string
---@field pattern string Lua pattern that captures the period from a file name
---@field label string Text of the link to the previous note
---@field current fun(): string The period that contains today

-- Keyed by the template name, which is also the name in {{last_<name>_note}}.
---@type table<string, PeriodicNoteType>
local NOTE_TYPES = {
	daily = {
		command = "DailyNote",
		description = "Open a daily note, filled from the daily template when new",
		pattern = "^(%d%d%d%d%-%d%d%-%d%d)%.md$",
		label = "Last daily note",
		current = function()
			return os.date("%Y-%m-%d")
		end,
	},
	weekly = {
		command = "WeeklyNote",
		description = "Open a weekly note, filled from the weekly template when new",
		pattern = "^(%d%d%d%d%-W%d%d)%.md$",
		label = "Last weekly note",
		current = function()
			-- %G-W%V is the ISO week date; January days can belong to the last ISO
			-- week of the previous year, which a plain %Y would get wrong.
			return os.date("%G-W%V")
		end,
	},
}

---@param first string
---@param second string
---@return boolean
local function same_file(first, second)
	return (vim.uv.fs_realpath(first) or first) == (vim.uv.fs_realpath(second) or second)
end

-- Opens `<name>.md` in the working directory and, when that gives a new empty
-- buffer, fills it from `template`. A note that already has content is left as
-- it is, and nothing is ever saved.
---@param name string
---@param template string
local function open_note(name, template)
	local path = vim.fs.joinpath(vim.fn.getcwd(), name .. ".md")
	-- Editing the file the buffer already shows would fail with E37 when it has
	-- unsaved changes, so only switch when it is a different file.
	if not same_file(vim.api.nvim_buf_get_name(0), path) then
		vim.cmd.edit({ args = { path } })
	end

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	if #lines ~= 1 or lines[1] ~= "" then
		return
	end

	local ok, err = pcall(templater.insert, template, "start")
	if not ok then
		vim.notify(tostring(err), vim.log.levels.ERROR)
		return
	end
	vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0), 0 })
end

-- {{last_daily_note}}, {{last_weekly_note}}: a link to the newest earlier note of
-- the same type in the note's directory. The first note has none, so the
-- variable returns nil and its placeholder stays visible in the note.
---@return table<string, TemplaterVariable>
function M.variables()
	local variables = {}
	for name, note_type in pairs(NOTE_TYPES) do
		variables["last_" .. name .. "_note"] = function(context)
			local previous = previous_note.find(context.directory, note_type.pattern, context.title)
			return previous and ("- [[" .. previous .. ".md|" .. note_type.label .. "]]") or nil
		end
	end
	return variables
end

-- :DailyNote and :WeeklyNote take an optional period; without one they open
-- today's note.
function M.register_commands()
	for name, note_type in pairs(NOTE_TYPES) do
		vim.api.nvim_create_user_command(note_type.command, function(arguments)
			open_note(arguments.args ~= "" and arguments.args or note_type.current(), name)
		end, { nargs = "?", desc = note_type.description })
	end
end

return M
