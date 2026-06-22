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
	{ src = "https://github.com/kdheepak/lazygit.nvim", version = "main" },
})

require("treesitter")
require("fmt") -- conform.nvim
require("mininvim")

vim.cmd([[colorscheme tokyonight-night]])

require("slipnote").setup({
	conceal = {
		enable = true,
		wikilinks = true,
		cursor = "",
	},
	frontmatter = {
		enable = true,
	},
})

require("keybinds")

require("lsp").setup()

require("marks")
