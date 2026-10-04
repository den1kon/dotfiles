local frontmatter = require("notes.frontmatter")
local note = require("notes.note")

-- Weekly-note naming and body structure mirror daily notes while remaining
-- independently changeable as the weekly workflow evolves.
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
---@field previous_note? string
---@field now? integer Unix timestamp

---@param options WeeklyTemplateOptions
---@return string[]
function M.build_template(options)
	local lines = frontmatter.build({ tag = "weekly-note", now = options.now })
	vim.list_extend(lines, { "# " .. options.week, "" })

	if options.previous_note then
		vim.list_extend(lines, {
			"- [[" .. options.previous_note .. "|Last weekly note]]",
			"",
		})
	end

	vim.list_extend(lines, {
		"## TODOs",
		"",
		"## Daily notes",
		"",
	})
	return lines
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
			return M.build_template({
				week = week,
				previous_note = note.find_previous(directory, week, weekly_pattern),
				now = now,
			})
		end,
	})
end

return M
