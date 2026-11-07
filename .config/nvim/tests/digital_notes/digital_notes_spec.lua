-- Checks the wiring between modules, not the modules themselves.
vim.o.swapfile = false

local templates = vim.fn.tempname()
vim.fn.mkdir(templates, "p")
vim.fn.writefile(
	{ "---", "id: {{id}}", 'updated_at: "{{utc}}"', "tags:", "  - fleeting-note", "---", "" },
	templates .. "/frontmatter.md"
)

local ok, digital_notes = pcall(require, "digital_notes")
assert(ok, "digital_notes should load: " .. tostring(digital_notes))
digital_notes.setup({ templates = templates })

for _, command in ipairs({
	"DailyNote",
	"WeeklyNote",
	"InsertTemplate",
	"FollowLink",
	"FollowLinkInNewTab",
	"FollowBack",
}) do
	assert(vim.fn.exists(":" .. command) == 2, "the workflow should provide :" .. command)
end
assert(vim.fn.exists(":InsertFrontmatter") == 0, "frontmatter is inserted through a template")

-- The configured directory supplies the frontmatter template.
vim.cmd("enew!")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# Heading" })
vim.cmd("InsertTemplate frontmatter start")
local inserted = vim.api.nvim_buf_get_lines(0, 0, -1, false)
assert(inserted[1] == "---" and inserted[#inserted] == "# Heading", "frontmatter should go above the existing text")
assert(vim.tbl_contains(inserted, "  - fleeting-note"), "the frontmatter template should tag a fleeting note")
assert(inserted[2]:match("^id: %d+$"), "the frontmatter template should fill in an id")
vim.cmd("enew!")

-- A template keeps its placeholder when saved; any other note gets a timestamp.
local frontmatter = require("frontmatter")
local function refresh(path)
	vim.cmd("enew!")
	vim.api.nvim_buf_set_name(0, path)
	vim.bo.filetype = "markdown"
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "---", 'updated_at: "{{updated_at}}"', "---" })
	local updated = frontmatter.refresh_updated_at(0)
	local line = vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]
	vim.cmd("enew!")
	return updated, line
end

local updated, line = refresh(templates .. "/weekly.md")
assert(updated == false and line == 'updated_at: "{{updated_at}}"', "saving a template must not refresh updated_at")

updated, line = refresh(vim.fn.tempname() .. "/2026-W40.md")
assert(updated == true and line ~= 'updated_at: "{{updated_at}}"', "saving a normal note should refresh updated_at")

vim.fn.delete(templates, "rf")

print("digital_notes: tests passed")
