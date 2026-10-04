local ok, notes = pcall(require, "notes")

assert(ok, "notes should load")

notes.setup()

assert(vim.fn.exists(":DailyNote") == 2, "setup should register :DailyNote")
assert(vim.fn.exists(":WeeklyNote") == 2, "setup should register :WeeklyNote")
assert(vim.fn.maparg("<leader>dn", "n") ~= "", "setup should register the daily-note keymap")
assert(vim.fn.maparg("<leader>wn", "n") ~= "", "setup should register the weekly-note keymap")

vim.o.swapfile = false
local notes_dir = vim.fn.tempname()
vim.fn.mkdir(notes_dir, "p")
local original_directory = vim.fn.getcwd()
vim.cmd.lcd(vim.fn.fnameescape(notes_dir))

vim.cmd("DailyNote 2026-10-04")
assert(
	vim.tbl_contains(vim.api.nvim_buf_get_lines(0, 0, -1, false), "  - daily-note"),
	":DailyNote should populate a daily note"
)

vim.cmd("enew!")
vim.cmd("WeeklyNote 2026-W40")
assert(
	vim.tbl_contains(vim.api.nvim_buf_get_lines(0, 0, -1, false), "  - weekly-note"),
	":WeeklyNote should populate a weekly note"
)

vim.cmd("enew!")
vim.cmd.lcd(vim.fn.fnameescape(original_directory))
vim.fn.delete(notes_dir, "rf")

print("notes: tests passed")
