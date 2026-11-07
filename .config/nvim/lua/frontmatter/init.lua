-- Keeps `updated_at` in a Markdown buffer's YAML frontmatter fresh by
-- refreshing it before every save. It knows nothing about where notes or
-- templates live; callers decide which files to skip through `exclude`.
-- Creating frontmatter is a template's job (see the templater module).
local M = {}

---@class FrontmatterOptions
---@field update_on_save? boolean Refresh `updated_at` before saving (default true)
---@field exclude? fun(path: string): boolean Files whose `updated_at` must be left alone

---@type FrontmatterOptions
local options = { update_on_save = true }

local augroup = vim.api.nvim_create_augroup("FrontmatterUpdatedAt", { clear = true })

---@param now? integer Unix timestamp
---@return string
local function utc(now)
	return os.date("!%Y-%m-%dT%H:%M:%SZ", now)
end

---Sets `updated_at` inside the buffer's frontmatter to the current time.
---Only Markdown buffers with a closed frontmatter block that has the field
---change.
---@param buffer? integer
---@param now? integer Unix timestamp
---@return boolean updated
function M.refresh_updated_at(buffer, now)
	buffer = buffer or 0
	if vim.bo[buffer].filetype ~= "markdown" then
		return false
	end
	if options.exclude and options.exclude(vim.api.nvim_buf_get_name(buffer)) then
		return false
	end

	local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
	if lines[1] ~= "---" then
		return false
	end

	local closing = vim.fn.index(lines, "---", 1) + 1
	if closing == 0 then
		return false
	end

	for index = 2, closing - 1 do
		if lines[index]:match("^updated_at:") then
			-- Replace only this line so the rest of the buffer, its marks and
			-- the cursor stay untouched.
			vim.api.nvim_buf_set_lines(buffer, index - 1, index, false, { 'updated_at: "' .. utc(now) .. '"' })
			return true
		end
	end
	return false
end

---Registers the save hook unless it is disabled.
---@param user_options? FrontmatterOptions
function M.setup(user_options)
	options = vim.tbl_extend("force", { update_on_save = true }, user_options or {})

	vim.api.nvim_clear_autocmds({ group = augroup })
	if options.update_on_save then
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = augroup,
			desc = "Refresh frontmatter updated_at",
			callback = function(arguments)
				M.refresh_updated_at(arguments.buf)
			end,
		})
	end
end

return M
