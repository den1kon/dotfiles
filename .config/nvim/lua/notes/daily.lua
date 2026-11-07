local note = require("notes.note")

-- Daily-note naming and variables live here; the body is templates/daily.md and
-- generic buffer safety stays in note.lua.
local M = {}
local daily_pattern = "^(%d%d%d%d%-%d%d%-%d%d)%.md$"

---@class DailyTemplateOptions
---@field date string YYYY-MM-DD
---@field directory string
---@field now? integer Unix timestamp

---@param options DailyTemplateOptions
---@return string[]
function M.build_template(options)
	local context = {
		title = options.date,
		directory = options.directory,
		now = options.now or os.time(),
	}

	return note.build("daily", context, {
		last_daily_note = function()
			local previous = note.find_previous(context.directory, context.title, daily_pattern)
			return previous and ("- [[" .. previous .. "|Last daily note]]") or nil
		end,
	})
end

---@class DailyOpenOptions
---@field directory? string
---@field date? string YYYY-MM-DD
---@field now? integer Unix timestamp

---@param options? DailyOpenOptions
function M.open(options)
	options = options or {}
	local directory = options.directory or vim.fn.getcwd()
	local now = options.now or os.time()
	local date = options.date or os.date("%Y-%m-%d", now)

	-- note.open calls build only for an empty buffer, so an existing note is
	-- opened as-is without scanning for links or generating content.
	note.open({
		directory = directory,
		filename = date .. ".md",
		build = function()
			return M.build_template({ date = date, directory = directory, now = now })
		end,
	})
end

return M
