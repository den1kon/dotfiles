local Formatter = require("fmt")

-- slipnote.nvim
vim.api.nvim_set_keymap("n", "<leader>if", ":InsertFrontmatter<CR>", { desc = "Insert YAML frontmatter" })
vim.api.nvim_set_keymap("n", "<leader>fl", ":FollowLink<CR>", { desc = "Follow link at cursor" })
vim.api.nvim_set_keymap("n", "<leader>ft", ":FollowLinkInNewTab<CR>", { desc = "Follow link at cursor in new tab" })

local minifiles_toggle = function()
	if not MiniFiles.close() then
		MiniFiles.open()
	end
end

local function minidiff_toggle()
	MiniDiff.toggle_overlay(vim.api.nvim_get_current_buf())
end

vim.api.nvim_create_user_command("MiniFiles", minifiles_toggle, { desc = "Toggle MiniFiles" })
vim.api.nvim_create_user_command("ToggleMiniDiff", minidiff_toggle, { desc = "Toggle MiniDiff" })

vim.api.nvim_set_keymap("n", "<leader>fe", ":MiniFiles<CR>", { desc = "File explorer" })

-- Pickers
vim.api.nvim_set_keymap("n", "<leader>pf", ":Pick files<CR>", { desc = "Pick files" })
vim.api.nvim_set_keymap("n", "<leader>pgl", ":Pick grep_live<CR>", { desc = "Pick grep_live" })
vim.api.nvim_set_keymap("n", "<leader>pvp", ":Pick visit_paths<CR>", { desc = "Pick visit_paths" })
vim.api.nvim_set_keymap("n", "<leader>pr", ":Pick registers<CR>", { desc = "Pick registers" })
vim.api.nvim_set_keymap("n", "<leader>pgf", ":Pick git_files<CR>", { desc = "Pick git_files" })
vim.api.nvim_set_keymap("n", "<leader>ph", ":Pick help<CR>", { desc = "Pick help" })

-- MiniDiff
vim.api.nvim_set_keymap("n", "<leader>to", ":ToggleMiniDiff<CR>", { desc = "Pick help" })

-- Misc
vim.keymap.set("n", "<leader>od", vim.diagnostic.open_float)

-- Paste linewise before/after current line
vim.keymap.set("n", "[p", '<Cmd>exe "iput! " . v:register<CR>', { desc = "Paste Above" })
vim.keymap.set("n", "]p", '<Cmd>exe "iput "  . v:register<CR>', { desc = "Paste Below" })

-- Keeping the cursor centered.
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll downwards" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll upwards" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next result" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous result" })
vim.keymap.set("n", "G", "Gzz", { desc = "Goto last line" })

-- Indent while remaining in visual mode.
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Switch between windows.
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to the left window", remap = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to the bottom window", remap = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to the top window", remap = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to the right window", remap = true })

-- Tab navigation.
vim.keymap.set("n", "<leader>tc", "<cmd>tabclose<cr>", { desc = "Close tab page" })
vim.keymap.set("n", "<leader>tn", "<cmd>tab split<cr>", { desc = "New tab page" })
vim.keymap.set("n", "<leader>to", "<cmd>tabonly<cr>", { desc = "Close other tab pages" })

-- Poweful <esc>.
vim.keymap.set({ "i", "s", "n" }, "<esc>", function()
	vim.cmd("noh")
	return "<esc>"
end, { desc = "Escape, clear hlsearch", expr = true })

-- Make U opposite to u.
vim.keymap.set("n", "U", "<C-r>", { desc = "Redo" })

-- Escape and save changes.
vim.keymap.set({ "s", "i", "n", "v" }, "<C-s>", "<esc>:w<cr>", { desc = "Exit insert mode and save changes" })

-- Undotree
vim.keymap.set("n", "<leader>ut", ":UndotreeToggle<CR>", { desc = "Toggle Undotree" })

-- Format
vim.keymap.set("n", "<leader>fb", Formatter.format_buffer, { desc = "Format buffer" })

-- LazyGit
vim.keymap.set("n", "<leader>lg", ":LazyGit<CR>", { desc = "Open LazyGit" })
