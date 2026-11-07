-- The :InsertTemplate command and its completion.
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

function M.register()
	vim.api.nvim_create_user_command("InsertTemplate", function(arguments)
		if #arguments.fargs > 2 then
			vim.notify("InsertTemplate: expected {template} [{position}]", vim.log.levels.ERROR)
			return
		end

		local ok, err = pcall(require("templater").insert, arguments.fargs[1], arguments.fargs[2])
		if not ok then
			vim.notify(tostring(err), vim.log.levels.ERROR)
		end
	end, {
		nargs = "+",
		complete = complete,
		desc = "Insert a rendered template: {template} [{position}]",
	})
end

return M
