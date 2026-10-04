local M = {}

-- New notes do not exist yet, so resolve their parent directory instead of
-- relying on fs_realpath() for the complete path.
---@param path string
---@return string
local function canonical_path(path)
	local absolute = vim.fn.fnamemodify(path, ":p")
	local parent = vim.fs.dirname(absolute)
	local resolved_parent = vim.uv.fs_realpath(parent) or vim.fs.normalize(parent)
	return vim.fs.joinpath(resolved_parent, vim.fs.basename(absolute))
end

---@param directory string
---@param current string Sortable date or period key
---@param pattern string Lua pattern that captures the key from a filename
---@return string|nil
function M.find_previous(directory, current, pattern)
	local previous

	-- Daily and weekly names are chronologically sortable as plain strings.
	for name, kind in vim.fs.dir(directory, { depth = 1 }) do
		local candidate = name:match(pattern)
		if kind == "file" and candidate and candidate < current and (not previous or candidate > previous) then
			previous = candidate
		end
	end

	return previous and (previous .. ".md") or nil
end

---@class NotesOpenOptions
---@field directory string
---@field filename string
---@field build fun(): string[]

---@param options NotesOpenOptions
---@return boolean populated
function M.open(options)
	local path = vim.fs.joinpath(options.directory, options.filename)
	local current_path = vim.api.nvim_buf_get_name(0)
	-- Re-editing this same modified buffer would raise E37 and risk suggesting
	-- that the user must save or discard their work.
	if canonical_path(current_path) ~= canonical_path(path) then
		vim.cmd.edit(vim.fn.fnameescape(path))
	end

	local buffer = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
	if #lines ~= 1 or lines[1] ~= "" then
		return false
	end

	-- Build lazily, only after proving that no existing content can be replaced.
	local template = options.build()
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, template)
	vim.api.nvim_win_set_cursor(0, { #template, 0 })
	return true
end

return M
