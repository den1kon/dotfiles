local frontmatter = require("notes.frontmatter")
local note = require("notes.note")

-- Daily-note naming and body structure live here; generic buffer safety and
-- frontmatter generation stay in their shared modules.
local M = {}
local daily_pattern = "^(%d%d%d%d%-%d%d%-%d%d)%.md$"

---@class DailyTemplateOptions
---@field date string YYYY-MM-DD
---@field previous_note? string
---@field now? integer Unix timestamp

---@param options DailyTemplateOptions
---@return string[]
function M.build_template(options)
	local lines = frontmatter.build({ tag = "daily-note", now = options.now })
	vim.list_extend(lines, { "# " .. options.date, "" })

	if options.previous_note then
		vim.list_extend(lines, {
			"- [[" .. options.previous_note .. "|Last daily note]]",
			"",
		})
	end

	vim.list_extend(lines, { "## TODOs", "" })
	return lines
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
			return M.build_template({
				date = date,
				previous_note = note.find_previous(directory, date, daily_pattern),
				now = now,
			})
		end,
	})
end

return M
