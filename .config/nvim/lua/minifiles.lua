local M = {}
-- Set focused directory as current working directory
local set_cwd = function()
	local path = (MiniFiles.get_fs_entry() or {}).path
	if path == nil then
		return vim.notify("Cursor is not on valid entry")
	end
	vim.fn.chdir(vim.fs.dirname(path))
  vim.notify("Cwd is now '" .. vim.fn.getcwd() .. "'")
end

-- Yank in register full path of entry under cursor
local yank_path = function()
	local path = (MiniFiles.get_fs_entry() or {}).path
	if path == nil then
		return vim.notify("Cursor is not on valid entry")
	end
	vim.fn.setreg(vim.v.register, path)
end

function M.setup()
vim.api.nvim_create_autocmd("User", {
	pattern = "MiniFilesBufferCreate",
	callback = function(args)
		local b = args.data.buf_id
		vim.keymap.set("n", "~", set_cwd, { buffer = b, desc = "Set cwd" })
		vim.keymap.set("n", "gy", yank_path, { buffer = b, desc = "Yank path" })
	end,
})
end


return M
