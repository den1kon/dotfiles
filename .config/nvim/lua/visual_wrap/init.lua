-- Toggles Markdown emphasis markers around the Visual selection: wrap("**")
-- for bold, wrap("*") for italic, wrap("`") for inline code. It only provides
-- the function; binding keys to it is the configuration's job.
local M = {}

-- Region offsets are screen cells inside a tab or beyond the end of a line.
local function boundary(position, is_end)
	local row, column, offset = position[2], position[3] - 1, position[4]
	if not is_end then
		return column, string.rep(" ", offset)
	end
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
	local character = vim.fn.strcharpart(line:sub(column + 1), 0, 1)
	local padding = ""
	if offset > 0 and character ~= "" then
		local screen_column = vim.fn.virtcol({ row, column + 1 }, true)[1] - 1
		padding = string.rep(" ", vim.fn.strdisplaywidth(character, screen_column) - offset)
	end
	return column + #character, padding
end

local function matching_markers(opening, closing, marker)
	if marker == "*" then
		-- A pair of stars belongs to bold; an odd extra star can be italic.
		return #opening % 2 == 1 and #closing % 2 == 1
	elseif marker == "`" then
		return #opening == 1 and #closing == 1
	end
	return #opening >= #marker and #closing >= #marker
end

local function toggle_region(start_pos, end_pos, text, marker)
	local first, prefix = boundary(start_pos, false)
	local last, suffix = boundary(end_pos, true)
	local pattern = marker == "`" and "`+" or "%*+"
	local opening = text[1]:match("^" .. pattern) or ""
	local closing = text[#text]:match(pattern .. "$") or ""
	local contains_markers = (#text > 1 or #text[1] >= 2 * #marker) and matching_markers(opening, closing, marker)

	local first_line = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, start_pos[2], false)[1]
	local last_line = vim.api.nvim_buf_get_lines(0, end_pos[2] - 1, end_pos[2], false)[1]
	local before = first_line:sub(1, first)
	local after = last_line:sub(last + 1)
	local surrounding_markers = prefix == ""
		and suffix == ""
		and matching_markers(before:match(pattern .. "$") or "", after:match("^" .. pattern) or "", marker)

	if contains_markers then
		text[1] = text[1]:sub(#marker + 1)
		text[#text] = text[#text]:sub(1, -#marker - 1)
	elseif surrounding_markers then
		first = first - #marker
		last = last + #marker
	else
		text[1] = marker .. text[1]
		text[#text] = text[#text] .. marker
	end
	text[1] = prefix .. text[1]
	text[#text] = text[#text] .. suffix
	vim.api.nvim_buf_set_text(0, start_pos[2] - 1, first, end_pos[2] - 1, last, text)
end

---Toggles `marker` on the current Visual selection, then returns to Normal mode.
---Does nothing outside Visual mode.
---@param marker string
function M.wrap(marker)
	local mode = vim.fn.mode()
	if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
		return
	end
	local anchor, cursor = vim.fn.getpos("v"), vim.fn.getpos(".")
	local options = { type = mode, exclusive = vim.o.selection == "exclusive", eol = true }
	local regions = vim.fn.getregionpos(anchor, cursor, options)
	local text = vim.fn.getregion(anchor, cursor, { type = mode, exclusive = options.exclusive })
	vim.cmd.normal({ vim.keycode("<Esc>"), bang = true })

	if mode == "\22" then
		for index = #regions, 1, -1 do
			local start_pos, end_pos = regions[index][1], regions[index][2]
			if index < #regions then
				vim.cmd.undojoin()
			end
			toggle_region(start_pos, end_pos, { text[index] }, marker)
		end
	else
		local start_pos, end_pos = regions[1][1], regions[#regions][2]
		toggle_region(start_pos, end_pos, text, marker)
	end
end

return M
