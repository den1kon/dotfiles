local M = {}

function M.setup()
	-- Lua
	require("lsp.lua_ls").setup()
	-- Nix
	require("lsp.nil_ls").setup()
	-- PHP
	require("lsp.phpactor").setup()
	-- TypeScript / JavaScript
	require("lsp.ts_ls").setup()
	-- Typst (tinymist)
	require("lsp.tinymist").setup()
	-- C/Cpp (clangd)
	require("lsp.clangd").setup()

	vim.lsp.enable({ "clangd", "lua_ls", "nil_ls", "phpactor", "ts_ls", "tinymist" })
end

return M
