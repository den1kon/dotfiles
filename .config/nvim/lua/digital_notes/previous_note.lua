-- Finding the note that comes right before another, among files named after
-- their period (a day, a week). It only reads file names.
local M = {}

---@param directory string
---@param pattern string Lua pattern that captures the period from a file name
---@param current string Period of the note that needs a predecessor
---@return string|nil period The greatest period below `current`, if any
function M.find(directory, pattern, current)
	local previous
	for name, kind in vim.fs.dir(directory) do
		local period = name:match(pattern)
		-- Periods are zero-padded, so plain string order is time order.
		if kind == "file" and period and period < current and (not previous or period > previous) then
			previous = period
		end
	end
	return previous
end

return M
