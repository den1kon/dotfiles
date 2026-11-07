-- A per-window stack of visited Markdown buffers, so "back" returns to where a
-- followed link came from even after several jumps.
local M = {}

local VARIABLE = "markdown_navigation_history"
local MAX_ENTRIES = 1000

---@param buffer integer
function M.push(buffer)
	local stack = vim.w[VARIABLE] or {}
	-- Entering the same buffer again (for example while switching tabs) must
	-- not add a duplicate.
	if #stack > 0 and stack[#stack] == buffer then
		table.remove(stack)
	end
	if #stack > MAX_ENTRIES then
		table.remove(stack, 1)
	end
	table.insert(stack, buffer)
	vim.w[VARIABLE] = stack
end

---Drops the current buffer and returns the latest earlier one that is still listed.
---@return integer|nil buffer
function M.pop_previous()
	local stack = vim.w[VARIABLE] or {}
	if #stack <= 1 then
		return nil
	end

	table.remove(stack)
	local previous
	while #stack > 0 and not previous do
		local candidate = table.remove(stack)
		-- bdelete leaves a buffer valid but unlisted; treat it as gone.
		if vim.api.nvim_buf_is_valid(candidate) and vim.bo[candidate].buflisted then
			previous = candidate
		end
	end
	vim.w[VARIABLE] = stack
	return previous
end

return M
