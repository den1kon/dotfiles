require("settings")

vim.pack.add({
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		version = "4916d6592ede8c07973490d9322f187e07dfefac", -- latest commit before archive
	},
	{ src = "https://github.com/folke/tokyonight.nvim" },
	{ src = "https://github.com/nvim-mini/mini.nvim", version = "main" },
	{ src = "https://github.com/stevearc/conform.nvim", version = "master" },
	{ src = "https://github.com/den1kon/slipnote.nvim", version = "main" },
	{ src = "https://github.com/neovim/nvim-lspconfig", version = "master" },
	{ src = "https://github.com/mbbill/undotree", version = "master" },
})

require("treesitter")
require("fmt")

vim.cmd([[colorscheme tokyonight-night]])

-- MINI.NVIM ====================================================================================================

-- mini.files----------------------------------------------------------------------------------------------------
require("mini.files").setup()

--------------------------------------------------
require("mini.icons").setup()
require("mini.pick").setup()
require("mini.indentscope").setup()
require("mini.trailspace").setup()
require("mini.visits").setup()
require("mini.git").setup()
require("mini.diff").setup({
	view = {
		-- Visualization style. Possible values are 'sign' and 'number'.
		style = "sign",
	},
})
require("mini.statusline").setup()
require("mini.extra").setup()
require("mini.cmdline").setup()
require("mini.completion").setup()
require("mini.notify").setup()
require("miniclue")

-----------------------------------------------------------------------------------------------------------------

require("slipnote").setup()

require("keybinds")

require("lsp").setup()

vim.lsp.enable({ "clangd", "lua_ls", "nil_ls", "markdown_oxide", "phpactor", "ts_ls", "tinymist" })

require("marks")
