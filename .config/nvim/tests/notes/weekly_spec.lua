local ok, weekly = pcall(require, "notes.weekly")

assert(ok, "notes.weekly should load")

assert(weekly.current_week(1791112654) == "2026-W40", "current week should use the ISO week date")

local notes_dir = vim.fn.tempname()
vim.fn.mkdir(notes_dir, "p")

local body = {
	"## TODOs",
	"",
	"**Work:**",
	"",
	"- [ ] put uni days in absence",
	"",
	"## Daily notes",
	"",
	"- Monday",
	"  - uni/work day",
	"- Tuesday",
	"  - uni/work day",
	"- Wednesday",
	"  - uni/work day",
	"- Thursday",
	"  - uni/work day",
	"- Friday",
	"  - uni/work day",
	"- Saturday",
	"  - uni/work day",
	"- Sunday",
	"  - uni/work day",
}

local function expected_note(link_lines)
	local lines = {
		"---",
		"id: 1791112654",
		'created_at: "2026-10-04T11:17:34Z"',
		'updated_at: "2026-10-04T11:17:34Z"',
		"tags:",
		"  - weekly-note",
		"---",
		"",
		"# 2026-W40",
		"",
	}
	vim.list_extend(lines, link_lines)
	vim.list_extend(lines, { "" })
	vim.list_extend(lines, body)
	return lines
end

-- With no earlier note the link variable renders as nothing, and its line stays.
local without_previous = weekly.build_template({
	week = "2026-W40",
	directory = notes_dir,
	now = 1791112654,
})
assert(
	vim.deep_equal(without_previous, expected_note({ "" })),
	"first weekly note should have an empty link line instead of a broken link"
)

vim.fn.writefile({}, notes_dir .. "/2026-W39.md")
vim.fn.writefile({}, notes_dir .. "/2026-W41.md")

local with_previous = weekly.build_template({
	week = "2026-W40",
	directory = notes_dir,
	now = 1791112654,
})
assert(
	vim.deep_equal(with_previous, expected_note({ "- [[2026-W39.md|Last weekly note]]" })),
	"weekly template should link the previous note"
)

vim.fn.delete(notes_dir, "rf")

print("notes.weekly: tests passed")
