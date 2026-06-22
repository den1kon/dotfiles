require('nvim-treesitter').setup {
  -- Directory to install parsers and queries to (prepended to `runtimepath` to have priority)
  install_dir = vim.fn.stdpath('data') .. '/site'
}

local tsinstall = {
	"rust",
	"markdown",
	"markdown_inline",
	"lua",
	"php",
	"phpdoc",
	"nix",
	"toml",
	"typescript",
	"tsx",
	"json",
	"css",
	"html",
	"typst",
	"cpp",
	"bash",
	"ini",
	"yaml",
	"javascript",
	"vue",
}
local filetypes = {
	"rust",
	"markdown",
	"markdown_inline",
	"lua",
	"php",
	"phpdoc",
	"nix",
	"toml",
	"typescript",
	"javascript",
	"tsx",
	"typescriptreact",
	"javascriptreact",
	"json",
	"css",
	"html",
	"typst",
	"cpp",
	"bash",
	"sh",
	"ini",
	"yaml",
	"vue",
}

-- Map .env files to ini filetype
vim.filetype.add({
	pattern = { ["%.env.*"] = "ini" },
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = filetypes,
	callback = function()
		-- syntax highlighting, provided by Neovim
		vim.treesitter.language.register("typescript", { "tsx", "javascript", "jsx", "typescriptreact" })
		vim.treesitter.language.register("ini", { "env" }) -- Map env to ini parser
		vim.treesitter.start()
		-- folds, provided by Neovim
		-- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		-- vim.wo.foldmethod = "expr"
		-- indentation, provided by nvim-treesitter
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})

require('nvim-treesitter').install(tsinstall)
