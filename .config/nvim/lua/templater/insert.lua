-- Puts lines into the current buffer at a named position. Knows nothing about
-- templates: it only places text.
local M = {}

---@alias TemplaterPosition
---| "cursor"       Inline, before the character under the cursor
---| "after-cursor" Inline, after the character under the cursor
---| "above"        As new lines above the current line
---| "below"        As new lines below the current line
---| "start"        At the beginning of the buffer
---| "end"          At the end of the buffer

---@type TemplaterPosition[]
M.positions = { "cursor", "after-cursor", "above", "below", "start", "end" }

---Cursor placement: the inline and line-wise positions leave it on the first
---inserted character or line, like :put; `start` and `end` do not move it, so
---metadata can be added without losing your place.
---@param lines string[]
---@param position TemplaterPosition
function M.insert(lines, position)
	if position == "cursor" then
		vim.api.nvim_put(lines, "c", false, false)
	elseif position == "after-cursor" then
		vim.api.nvim_put(lines, "c", true, false)
	elseif position == "above" then
		vim.api.nvim_put(lines, "l", false, false)
	elseif position == "below" then
		vim.api.nvim_put(lines, "l", true, false)
	elseif position == "start" or position == "end" then
		local current = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		if #current == 1 and current[1] == "" then
			-- A new buffer's only line is empty filler, not content to keep.
			vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		elseif position == "start" then
			vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
		else
			vim.api.nvim_buf_set_lines(0, -1, -1, false, lines)
		end
	else
		error(
			("templater: unknown position %q, expected one of: %s"):format(position, table.concat(M.positions, ", ")),
			0
		)
	end
end

return M
