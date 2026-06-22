local M = {}

---@type vim.lsp.Config
local config = {
	cmd = { "nil" },
	filetypes = { "nix" },
	root_markers = { "flake.nix", ".git" },
}

function M.setup()
	vim.lsp.config("nil_ls", config)
end

return M
