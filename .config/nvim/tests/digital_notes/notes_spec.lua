-- Daily and weekly notes: a file named after the day or week, filled from a template.
vim.o.swapfile = false

local templates = vim.fn.tempname()
local notes = vim.fn.tempname()
vim.fn.mkdir(templates, "p")
vim.fn.mkdir(notes, "p")
vim.fn.writefile({ "# {{title}}", "", "{{last_daily_note}}", "", "## TODOs", "" }, templates .. "/daily.md")
vim.fn.writefile({ "# {{title}}", "{{last_weekly_note}}", "on {{date:%A}}" }, templates .. "/weekly.md")

local digital_notes = require("digital_notes")
digital_notes.setup({ templates = templates })

local original_directory = vim.fn.getcwd()
vim.cmd.lcd(vim.fn.fnameescape(notes))

local function lines()
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function note_name()
	return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
end

-- Wiping the buffers forgets earlier generated notes, which stay loaded when hidden.
local function fresh_window()
	vim.cmd("silent! %bwipeout!")
end

-- A first daily note: filled from the template, empty link line, unsaved.
vim.cmd("DailyNote 2026-10-04")
assert(note_name() == "2026-10-04.md", "the note should be named after its date")
assert(
	vim.deep_equal(lines(), { "# 2026-10-04", "", "", "", "## TODOs", "" }),
	"the first note has no previous link: " .. vim.inspect(lines())
)
assert(vim.api.nvim_win_get_cursor(0)[1] == 6, "the cursor should end on the last line")
assert(vim.bo.modified, "the generated note should stay unsaved")
assert(vim.fn.filereadable(notes .. "/2026-10-04.md") == 0, "generating a note must not write it")

-- Repeating the command on the unsaved note changes nothing and does not error.
local before = lines()
assert(pcall(vim.cmd, "DailyNote 2026-10-04"), "repeating the command should not raise E37")
assert(vim.deep_equal(lines(), before), "the template must not be inserted twice")
assert(vim.bo.modified, "the note should still be unsaved")

-- A note with content is never changed.
fresh_window()
vim.fn.writefile({ "existing content" }, notes .. "/2026-10-03.md")
vim.cmd("DailyNote 2026-10-03")
assert(vim.deep_equal(lines(), { "existing content" }), "an existing note must not be overwritten")
assert(not vim.bo.modified, "opening an existing note must not modify it")

-- Links go to the newest earlier note of the same kind only.
fresh_window()
for _, name in ipairs({ "2026-09-30", "2026-10-02", "2026-10-05", "2026-W39" }) do
	vim.fn.writefile({}, notes .. "/" .. name .. ".md")
end
vim.cmd("DailyNote 2026-10-04")
assert(
	lines()[3] == "- [[2026-10-03.md|Last daily note]]",
	"the daily link should be the latest earlier day, ignoring later days and weeks: " .. vim.inspect(lines())
)

fresh_window()
vim.cmd("DailyNote 2026-09-01")
assert(lines()[3] == "", "a day with no earlier note should have no link")

-- Weekly notes use ISO weeks and their own pattern.
fresh_window()
vim.fn.writefile({}, notes .. "/2026-W41.md")
vim.cmd("WeeklyNote 2026-W40")
assert(note_name() == "2026-W40.md", "the weekly note should be named after its week")
assert(
	vim.deep_equal(lines(), { "# 2026-W40", "- [[2026-W39.md|Last weekly note]]", "on " .. os.date("%A") }),
	"the weekly note should link the previous week: " .. vim.inspect(lines())
)

-- Without an argument the note is today's day or this ISO week.
fresh_window()
vim.cmd("DailyNote")
assert(note_name() == os.date("%Y-%m-%d") .. ".md", "the default daily note should be today's")
fresh_window()
vim.cmd("WeeklyNote")
assert(note_name() == os.date("%G-W%V") .. ".md", "the default weekly note should be this ISO week")

-- A missing template is reported and leaves the new buffer empty.
local errors = {}
local original_notify = vim.notify
vim.notify = function(message, level)
	table.insert(errors, { message = message, level = level })
end
local empty_templates = vim.fn.tempname()
vim.fn.mkdir(empty_templates, "p")
digital_notes.setup({ templates = empty_templates })

fresh_window()
vim.cmd("DailyNote 2030-01-01")
assert(#errors == 1 and errors[1].level == vim.log.levels.ERROR, "a missing template should be reported once")
assert(errors[1].message:find("daily", 1, true), "the error should name the template")
assert(vim.deep_equal(lines(), { "" }), "the buffer should stay empty")
vim.notify = original_notify

fresh_window()
vim.cmd.lcd(vim.fn.fnameescape(original_directory))
vim.fn.delete(templates, "rf")
vim.fn.delete(notes, "rf")
vim.fn.delete(empty_templates, "rf")

print("digital_notes notes: tests passed")
