local ok, weekly = pcall(require, "notes.weekly")

assert(ok, "notes.weekly should load")

assert(weekly.current_week(1791112654) == "2026-W40", "current week should use the ISO week date")

local with_previous = weekly.build_template({
	week = "2026-W40",
	previous_note = "2026-W39.md",
	now = 1791112654,
})
local expected_with_previous = {
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
	"- [[2026-W39.md|Last weekly note]]",
	"",
	"## TODOs",
	"",
	"## Daily notes",
	"",
}
assert(vim.deep_equal(with_previous, expected_with_previous), "weekly template should link the previous note")

local without_previous = weekly.build_template({
	week = "2026-W40",
	now = 1791112654,
})
local expected_without_previous = {
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
	"## TODOs",
	"",
	"## Daily notes",
	"",
}
assert(
	vim.deep_equal(without_previous, expected_without_previous),
	"first weekly note should omit the previous-note link"
)

print("notes.weekly: tests passed")
