-- Combines the independent modules into the digital-notes workflow. It holds
-- the wiring and the little glue that is specific to this vault: daily and
-- weekly notes are a file named after the day or week, filled from a template.
local templater = require("templater")

local M = {}

---@class DigitalNotesOptions
---@field templates? string Directory with daily.md, weekly.md and frontmatter.md

local DAILY_PATTERN = "^(%d%d%d%d%-%d%d%-%d%d)%.md$"
local WEEKLY_PATTERN = "^(%d%d%d%d%-W%d%d)%.md$"

-- A {{last_daily_note}}-style variable: a link to the newest earlier note of the
-- same kind in the note's directory. For the first one it returns nil, which
-- leaves the placeholder visible in the note.
---@param pattern string Captures the period from a file name
---@param label string
---@return TemplaterVariable
local function previous_note_link(pattern, label)
	return function(context)
		local previous
		for name, kind in vim.fs.dir(context.directory) do
			local period = name:match(pattern)
			-- Periods are zero-padded, so plain string order is time order.
			if kind == "file" and period and period < context.title and (not previous or period > previous) then
				previous = period
			end
		end
		return previous and ("- [[" .. previous .. ".md|" .. label .. "]]") or nil
	end
end

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

local function register_commands()
	vim.api.nvim_create_user_command("DailyNote", function(arguments)
		open_note(arguments.args ~= "" and arguments.args or os.date("%Y-%m-%d"), "daily")
	end, {
		nargs = "?",
		desc = "Open a daily note, filled from the daily template when new",
	})

	vim.api.nvim_create_user_command("WeeklyNote", function(arguments)
		-- %G-W%V is the ISO week date; Jan 1 can belong to the last ISO week of the
		-- previous year, which a plain %Y would get wrong.
		open_note(arguments.args ~= "" and arguments.args or os.date("%G-W%V"), "weekly")
	end, {
		nargs = "?",
		desc = "Open a weekly note, filled from the weekly template when new",
	})
end

---@param options? DigitalNotesOptions
function M.setup(options)
	options = options or {}

	templater.setup({
		directories = { options.templates or "~/gitLair/digital-notes/templates" },
		variables = {
			last_daily_note = previous_note_link(DAILY_PATTERN, "Last daily note"),
			last_weekly_note = previous_note_link(WEEKLY_PATTERN, "Last weekly note"),
		},
	})

	require("frontmatter").setup({
		-- Template files hold placeholders such as {{updated_at}}, not timestamps.
		exclude = templater.is_template,
	})

	require("markdown-navigation").setup()

	register_commands()
end

return M
