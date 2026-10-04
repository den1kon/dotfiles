local ok, daily = pcall(require, "notes.daily")

assert(ok, "notes.daily should load")

local with_previous = daily.build_template({
	date = "2026-10-04",
	previous_note = "2026-10-02.md",
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

local without_previous = daily.build_template({
	date = "2026-10-04",
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
	"## TODOs",
	"",
}
assert(
	vim.deep_equal(without_previous, expected_without_previous),
	"first daily note should omit the previous-note link"
)

print("notes.daily: tests passed")
