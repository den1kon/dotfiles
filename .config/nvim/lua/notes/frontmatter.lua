-- Builds the portable YAML block shared by every generated note type.
local M = {}

---@class NotesFrontmatterOptions
---@field tag string
---@field now? integer Unix timestamp

---@param options NotesFrontmatterOptions
---@return string[]
function M.build(options)
	local now = options.now or os.time()
	local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", now)

	return {
		"---",
		"id: " .. now,
		'created_at: "' .. timestamp .. '"',
		'updated_at: "' .. timestamp .. '"',
		"tags:",
		"  - " .. options.tag,
		"---",
		"",
	}
end

return M
