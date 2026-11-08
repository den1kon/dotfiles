local M = {}

local function frontmatter_tags(lines)
	if lines[1] ~= "---" then
		return {}
	end

	local tags = {}
	local in_tags = false
	for index = 2, #lines do
		local line = lines[index]
		if line == "---" then
			break
		end

		if line:match("^tags:%s*$") then
			in_tags = true
		elseif in_tags then
			local tag = line:match("^%s+%-%s+['\"]?([^'\"]-)['\"]?%s*$")
			if tag then
				tags[#tags + 1] = tag
			elseif not line:match("^%s*$") then
				in_tags = false
			end
		end
	end

	return tags
end

function M.items(directory)
	local paths = vim.fn.globpath(directory, "*.md", false, true)
	table.sort(paths)

	local items = {}
	for _, path in ipairs(paths) do
		local lines = vim.fn.readfile(path)
		for _, tag in ipairs(frontmatter_tags(lines)) do
			items[#items + 1] = {
				path = path,
				tag = tag,
				text = tag .. "  " .. vim.fn.fnamemodify(path, ":t"),
			}
		end
	end
	return items
end

function M.pick(directory)
	local items = M.items(directory)
	if #items == 0 then
		vim.notify("PickTags: no tagged Markdown files found", vim.log.levels.WARN)
		return
	end

	MiniPick.start({
		source = {
			name = "Pick Tags",
			items = items,
			show = function(buf_id, shown_items)
				local tag_width = 0
				for _, item in ipairs(shown_items) do
					tag_width = math.max(tag_width, #item.tag)
				end
				local lines = vim.tbl_map(function(item)
					return ("%-" .. tag_width .. "s  │  %s"):format(item.tag, vim.fn.fnamemodify(item.path, ":t"))
				end, shown_items)
				vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
			end,
			match = function(stritems, inds, query)
				local needle = table.concat(query)
				if vim.o.ignorecase then
					needle = needle:lower()
				end
				local matches = {}
				for _, index in ipairs(inds) do
					local tag = stritems[index]:match("^(.-)  ") or stritems[index]
					if vim.o.ignorecase then
						tag = tag:lower()
					end
					if tag:find(vim.pesc(needle), 1) then
						matches[#matches + 1] = index
					end
				end
				return matches
			end,
			choose = function(item)
				local target = MiniPick.get_picker_state().windows.target
				vim.api.nvim_win_call(target, function()
					vim.cmd("edit " .. vim.fn.fnameescape(item.path))
				end)
			end,
		},
	})
end

return M
