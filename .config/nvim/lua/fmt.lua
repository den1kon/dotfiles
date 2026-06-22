require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		-- Conform will run multiple formatters sequentially
		-- python = { "isort", "black" },
		-- You can customize some of the format options for the filetype (:help conform.format)
		rust = { "rustfmt", lsp_format = "fallback" },
		-- Conform will run the first available formatter
		javascript = { "prettierd" },
		typescript = { "prettierd" },
		html = { "prettierd" },
		css = { "prettierd" },
		yaml = { "prettierd" },
		nix = { "nixfmt" },
		json = { "jq" },
		php = { "php-cs-fixer" },
		typst = { "typstyle" },
		cpp = { "astyle" },
		markdown = { "rumdl" },
	},
	-- Set default options
	default_format_opts = {
		lsp_format = "fallback",
	},
	formatters = {
		["php-cs-fixer"] = {
			command = "php-cs-fixer",
			args = {
				"fix",
				"--rules=@PSR12", -- Formatting preset. Other presets are available, see the php-cs-fixer docs.
				"$FILENAME",
			},
			stdin = false,
		},
		["rumdl"] = {
			command = "rumdl",
			args = {
				"fmt",
				"$FILENAME",
			},
			stdin = false,
		},
		-- ["typstyle"] = {
		-- 	command = "typstyle",
		-- 	args = {
		-- 		"-i",
		-- 		"$FILENAME",
		-- 	},
		-- },
	},
	notify_on_error = true,
})

local function format()
	require("conform").format({ async = true, lsp_format = "fallback" }, function(err)
		if not err then
			local mode = vim.api.nvim_get_mode().mode
			if vim.startswith(string.lower(mode), "v") then
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
			end
		end
	end)
end

vim.keymap.set("n", "<leader>fl", format)
