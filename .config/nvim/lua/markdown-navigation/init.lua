-- Follow Markdown links and wikilinks under the cursor, and go back. It
-- registers three commands and no keymaps; callers bind keys to the commands
-- or to the functions below.
local history = require("markdown-navigation.history")
local links = require("markdown-navigation.links")

local M = {}

---@class MarkdownNavigationOptions
---@field wikilink_search? MarkdownLinkSearch Where a flat [[wikilink]] is looked for, default { down = 1, up = 1 }

---@type { wikilink_search: MarkdownLinkSearch }
local settings = { wikilink_search = vim.deepcopy(links.default_search) }

---@param message string
local function warn(message)
	vim.notify("markdown-navigation: " .. message, vim.log.levels.WARN)
end

---Opens the link under the cursor in the current window, or in a new tab.
---@param options? { tab?: boolean }
---@return boolean followed
function M.follow_link(options)
	local line = vim.api.nvim_get_current_line()
	local column = vim.api.nvim_win_get_cursor(0)[2] + 1

	local link, err = links.at_column(line, column)
	if not link then
		warn(err or "No link found.")
		return false
	end

	local path, resolve_err = links.resolve(link, vim.api.nvim_buf_get_name(0), settings.wikilink_search)
	if not path then
		warn(resolve_err or "Could not resolve the link.")
		return false
	end

	if options and options.tab then
		vim.cmd.tabnew({ args = { path } })
	else
		vim.cmd.edit({ args = { path } })
	end
	return true
end

---Returns to the Markdown buffer this window visited before the current one.
---@return boolean moved
function M.follow_back()
	local previous = history.pop_previous()
	if not previous then
		warn("Buffer history is empty")
		return false
	end

	vim.cmd.buffer(previous)
	return true
end

---@param user_options? MarkdownNavigationOptions
function M.setup(user_options)
	settings = vim.tbl_deep_extend("force", { wikilink_search = links.default_search }, user_options or {})
	for _, levels in pairs(settings.wikilink_search) do
		assert(
			type(levels) == "number" and levels >= 0 and levels % 1 == 0,
			"wikilink_search levels must be non-negative integers"
		)
	end

	vim.api.nvim_create_user_command("FollowLink", function()
		M.follow_link()
	end, { desc = "Follow link at cursor" })
	vim.api.nvim_create_user_command("FollowLinkInNewTab", function()
		M.follow_link({ tab = true })
	end, { desc = "Follow link at cursor in new tab" })
	vim.api.nvim_create_user_command("FollowBack", function()
		M.follow_back()
	end, { desc = "Go back to the previous Markdown buffer" })

	local group = vim.api.nvim_create_augroup("MarkdownNavigationHistory", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
		group = group,
		desc = "Record visited Markdown buffers",
		callback = function()
			if vim.bo.filetype == "markdown" then
				history.push(vim.api.nvim_get_current_buf())
			end
		end,
	})
end

return M
