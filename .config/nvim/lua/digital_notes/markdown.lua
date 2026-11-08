local M = {}

local notes_directory = vim.fs.normalize(vim.fn.expand("~/gitLair/digital-notes"))

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("digital_notes_markdown", { clear = true }),
		pattern = "markdown",
		callback = function(event)
			local filename = vim.api.nvim_buf_get_name(event.buf)
			if filename == "" then
				return
			end

			local relative_path = vim.fs.relpath(notes_directory, filename)

			if relative_path and relative_path ~= ".." and not relative_path:match("^%.%./") then
				vim.bo[event.buf].textwidth = 100
			end
		end,
	})
end

return M
