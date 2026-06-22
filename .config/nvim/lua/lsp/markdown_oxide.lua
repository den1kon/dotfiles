local M = {}

---@param client vim.lsp.Client
---@param bufnr integer
---@param cmd string
local function command_factory(client, bufnr, cmd)
	return client:exec_cmd({
		title = ("Markdown-Oxide-%s"):format(cmd),
		command = "jump",
		arguments = { cmd },
	}, { bufnr = bufnr })
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true

local config = {
	root_markers = { ".git", ".obsidian", ".moxide.toml" },
	filetypes = { "markdown" },
	cmd = { "markdown-oxide" },
	capabilities = capabilities,
	on_attach = function(client, bufnr)
		for _, cmd in ipairs({ "today", "tomorrow", "yesterday" }) do
			vim.api.nvim_buf_create_user_command(
				bufnr,
				"Lsp" .. ("%s"):format(cmd:gsub("^%l", string.upper)),
				function()
					command_factory(client, bufnr, cmd)
				end,
				{
					desc = ("Open %s daily note"):format(cmd),
				}
			)
		end
	end,
}

function M.setup()
	vim.lsp.config("markdown_oxide", config)
end

return M
