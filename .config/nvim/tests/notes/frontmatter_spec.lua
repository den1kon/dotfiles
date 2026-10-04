local ok, frontmatter = pcall(require, "notes.frontmatter")

assert(ok, "notes.frontmatter should load")

local lines = frontmatter.build({
	tag = "weekly-note",
	now = 1791112654,
})
local expected = {
	"---",
	"id: 1791112654",
	'created_at: "2026-10-04T11:17:34Z"',
	'updated_at: "2026-10-04T11:17:34Z"',
	"tags:",
	"  - weekly-note",
	"---",
	"",
}

assert(vim.deep_equal(lines, expected), "frontmatter should use the requested tag and UTC timestamp")

print("notes.frontmatter: tests passed")
