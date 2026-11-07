local ok, previous_note = pcall(require, "digital_notes.previous_note")
assert(ok, "digital_notes.previous_note should load")

local directory = vim.fn.tempname()
vim.fn.mkdir(directory .. "/2026-10-01.md", "p")
for _, name in ipairs({
	"2026-09-30.md",
	"2026-10-02.md",
	"2026-10-05.md",
	"2026-W39.md",
	"2026-10-03.txt",
	"notes.md",
}) do
	vim.fn.writefile({}, directory .. "/" .. name)
end

local daily = "^(%d%d%d%d%-%d%d%-%d%d)%.md$"
local weekly = "^(%d%d%d%d%-W%d%d)%.md$"

assert(previous_note.find(directory, daily, "2026-10-04") == "2026-10-02", "the newest earlier day should win")
assert(previous_note.find(directory, daily, "2026-10-06") == "2026-10-05", "an earlier day may be the newest one")
assert(previous_note.find(directory, daily, "2026-10-02") == "2026-09-30", "the current period itself is not earlier")
assert(previous_note.find(directory, daily, "2026-09-30") == nil, "nothing precedes the first note")
assert(
	previous_note.find(directory, daily, "2026-10-04") ~= "2026-10-01",
	"a directory with a matching name is not a note"
)
assert(previous_note.find(directory, weekly, "2026-W40") == "2026-W39", "other note types use their own pattern")
assert(previous_note.find(directory, weekly, "2026-W39") == nil, "a type ignores files of the other type")

vim.fn.delete(directory, "rf")

print("digital_notes previous_note: tests passed")
