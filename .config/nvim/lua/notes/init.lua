local daily = require("notes.daily")
local weekly = require("notes.weekly")

local M = {}

-- Commands accept an explicit period for navigation or testing; mappings use
-- the current day or ISO week through the modules' defaults.
function M.setup()
	vim.api.nvim_create_user_command("DailyNote", function(arguments)
		daily.open({ date = arguments.args ~= "" and arguments.args or nil })
	end, {
		nargs = "?",
		desc = "Open a daily note and populate it when new",
	})

	vim.api.nvim_create_user_command("WeeklyNote", function(arguments)
		weekly.open({ week = arguments.args ~= "" and arguments.args or nil })
	end, {
		nargs = "?",
		desc = "Open a weekly note and populate it when new",
	})

	vim.keymap.set("n", "<leader>dn", daily.open, { desc = "Open today's daily note" })
	vim.keymap.set("n", "<leader>wn", weekly.open, { desc = "Open this week's weekly note" })
end

return M
