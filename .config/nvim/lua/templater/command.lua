-- The :InsertTemplate command, its completion, and the interactive form that
-- asks for the template and the position through vim.ui.select.
local insert = require("templater.insert")

local M = {}

---Completes the template (argument 1) or the position (argument 2).
---@param argument_lead string
---@param command_line string
---@param cursor_position integer
---@return string[]
local function complete(argument_lead, command_line, cursor_position)
	local typed = command_line:sub(1, cursor_position)
	local words = vim.split(typed, "%s+", { trimempty = true })
	local index = #words - 1 + (typed:match("%s$") and 1 or 0)

	if index == 2 then
		return vim.tbl_filter(function(position)
			return vim.startswith(position, argument_lead)
		end, insert.positions)
	elseif index ~= 1 then
		return {}
	end

	if argument_lead:find("/", 1, true) or vim.startswith(argument_lead, "~") then
		return vim.fn.getcompletion(argument_lead, "file")
	end
	return vim.tbl_filter(function(name)
		return vim.startswith(name, argument_lead)
	end, require("templater").list())
end

-- Shows "daily.md" as "daily". Two files that differ only by extension keep
-- theirs, so every entry stays distinguishable. Only the display changes; the
-- file that gets inserted is the one chosen.
---@param names string[]
---@return fun(name: string): string
local function display_names(names)
	local count = {}
	for _, name in ipairs(names) do
		local stem = vim.fn.fnamemodify(name, ":r")
		count[stem] = (count[stem] or 0) + 1
	end

	return function(name)
		local stem = vim.fn.fnamemodify(name, ":r")
		return count[stem] == 1 and stem or name
	end
end

---@param name string
---@param position? string
local function run(name, position)
	local ok, err = pcall(require("templater").insert, name, position)
	if not ok then
		vim.notify(tostring(err), vim.log.levels.ERROR)
	end
end

-- vim.ui.select is the standard interface, so whichever picker is installed
-- (mini.pick, snacks, the built-in menu) shows the choices. The prompts are
-- asynchronous, so the window the command started in is restored before
-- inserting.
local function choose_and_run()
	local names = require("templater").list()
	if #names == 0 then
		vim.notify("InsertTemplate: no templates found", vim.log.levels.WARN)
		return
	end

	local window = vim.api.nvim_get_current_win()
	vim.ui.select(names, { prompt = "Template", format_item = display_names(names) }, function(name)
		if not name then
			return
		end

		vim.ui.select(insert.positions, {
			prompt = "Position",
			format_item = function(position)
				return ("%s (%s)"):format(position, insert.descriptions[position])
			end,
		}, function(position)
			if not position then
				return
			end
			if vim.api.nvim_win_is_valid(window) then
				vim.api.nvim_set_current_win(window)
			end
			run(name, position)
		end)
	end)
end

function M.register()
	vim.api.nvim_create_user_command("InsertTemplate", function(arguments)
		if #arguments.fargs > 2 then
			vim.notify("InsertTemplate: expected [{template} [{position}]]", vim.log.levels.ERROR)
		elseif #arguments.fargs == 0 then
			choose_and_run()
		else
			run(arguments.fargs[1], arguments.fargs[2])
		end
	end, {
		nargs = "*",
		complete = complete,
		desc = "Insert a rendered template: [{template} [{position}]], or choose from a list",
	})
end

return M
