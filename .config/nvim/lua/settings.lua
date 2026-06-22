-- Set global and local <leader> key.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Show line numbers relative to current.
vim.opt.number = true
vim.opt.relativenumber = true

-- Use an indentation of 2 spaces.
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.showtabline = 2
-- Convert tabs to spaces.
vim.opt.expandtab = true

-- Sync clipboard between the OS and Neovim.
vim.opt.clipboard = "unnamedplus"

-- Keep signcolumn on by default (e.g. for git signs).
vim.opt.signcolumn = "yes"

-- Show whitespace.
vim.opt.list = true
vim.opt.listchars = { lead = "·", leadmultispace = "· ", tab = "» ", trail = "·", nbsp = "␣" }

-- Do not wrap long lines.
vim.opt.wrap = false

-- Do not use swap files.
vim.opt.swapfile = false

-- Use rounder borders for floating windows.
vim.opt.winborder = "rounded"

-- Case insensitive searching UNLESS /C or the search has capitals.
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.smartindent = true -- Make indenting smart.

-- Enables 24-bit RGB colors.
vim.opt.termguicolors = true

-- Enable persistent undo.
vim.opt.undofile = true

-- Update times and timeouts.
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 10

-- Completion.
vim.opt.wildignore:append({ ".DS_Store" })

-- Highlight cursor line.
vim.opt.cursorline = true

-- Use already opened buffers when switching.
vim.opt.switchbuf = "usetab"

-- Make popup menu smaller.
vim.opt.pumheight = 10
-- Limit maximum width of popup menu.
vim.opt.pummaxwidth = 100
-- Use border in built-in completion menu
vim.opt.pumborder = "bold"

-- Enable experimental ui
require("vim._core.ui2").enable()

-- Copy indent from current line to next.
vim.opt.autoindent = true

-- Show search matches while typing.
vim.opt.incsearch = true

-- Define spelling dictionaries.
vim.opt.spelllang = "en,uk"
-- Treat camelCase word parts as separate words.
vim.opt.spelloptions = "camel"

-- Allow going past end of line in blockwise mode
vim.opt.virtualedit = "block"

-- Built-in completion.
vim.opt.complete = ".,w,b" -- Use less sources.
vim.opt.completeopt = "menuone,noselect,fuzzy,nosort" -- Use custom behavior

