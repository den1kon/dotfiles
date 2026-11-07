local note = require("notes.note")

-- Weekly-note naming and variables live here; the body is templates/weekly.md.
local M = {}
local weekly_pattern = "^(%d%d%d%d%-W%d%d)%.md$"

---@param now? integer Unix timestamp
---@return string week ISO week date, such as 2026-W40
function M.current_week(now)
	-- ISO week-years handle year boundaries correctly (for example, Jan 1 can
	-- still belong to the final ISO week of the previous year).
	return os.date("%G-W%V", now or os.time())
end

---@class WeeklyTemplateOptions
---@field week string YYYY-Www
---@field directory string
---@field now? integer Unix timestamp

---@param options WeeklyTemplateOptions
---@return string[]
function M.build_template(options)
	local context = {
		title = options.week,
		directory = options.directory,
		now = options.now or os.time(),
	}

	return note.build("weekly", context, {
		last_weekly_note = function()
			local previous = note.find_previous(context.directory, context.title, weekly_pattern)
			return previous and ("- [[" .. previous .. "|Last weekly note]]") or nil
		end,
	})
end

---@class WeeklyOpenOptions
---@field directory? string
---@field week? string YYYY-Www
---@field now? integer Unix timestamp

---@param options? WeeklyOpenOptions
function M.open(options)
	options = options or {}
	local directory = options.directory or vim.fn.getcwd()
	local now = options.now or os.time()
	local week = options.week or M.current_week(now)

	-- The template callback remains lazy for the same overwrite protection used
	-- by daily notes.
	note.open({
		directory = directory,
		filename = week .. ".md",
		build = function()
			return M.build_template({ week = week, directory = directory, now = now })
		end,
	})
end

return M
