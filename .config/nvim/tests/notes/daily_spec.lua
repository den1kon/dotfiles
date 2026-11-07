local ok, daily = pcall(require, "notes.daily")

assert(ok, "notes.daily should load")

local notes_dir = vim.fn.tempname()
vim.fn.mkdir(notes_dir, "p")

-- With no earlier note the link variable renders as nothing, and its line stays.
local without_previous = daily.build_template({
	date = "2026-10-04",
	directory = notes_dir,
	now = 1791112654,
})
local expected_without_previous = {
	"---",
	"id: 1791112654",
	'created_at: "2026-10-04T11:17:34Z"',
	'updated_at: "2026-10-04T11:17:34Z"',
	"tags:",
	"  - daily-note",
	"---",
	"",
	"# 2026-10-04",
	"",
	"",
	"",
	"## TODOs",
	"",
}
assert(
	vim.deep_equal(without_previous, expected_without_previous),
	"first daily note should have an empty link line instead of a broken link"
)

vim.fn.writefile({}, notes_dir .. "/2026-10-02.md")
vim.fn.writefile({}, notes_dir .. "/2026-10-05.md")

local with_previous = daily.build_template({
	date = "2026-10-04",
	directory = notes_dir,
	now = 1791112654,
})
local expected_with_previous = {
	"---",
	"id: 1791112654",
	'created_at: "2026-10-04T11:17:34Z"',
	'updated_at: "2026-10-04T11:17:34Z"',
	"tags:",
	"  - daily-note",
	"---",
	"",
	"# 2026-10-04",
	"",
	"- [[2026-10-02.md|Last daily note]]",
	"",
	"## TODOs",
	"",
}
assert(vim.deep_equal(with_previous, expected_with_previous), "daily template should link the previous note")

vim.fn.delete(notes_dir, "rf")

print("notes.daily: tests passed")
