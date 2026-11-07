-- Checks the wiring between modules, not the modules themselves.
local ok, err = pcall(require, "digital_notes")
assert(ok, "digital_notes should load: " .. tostring(err))

for _, command in ipairs({
	"DailyNote",
	"WeeklyNote",
	"InsertFrontmatter",
	"FollowLink",
	"FollowLinkInNewTab",
	"FollowBack",
}) do
	assert(vim.fn.exists(":" .. command) == 2, "the workflow should provide :" .. command)
end
assert(vim.fn.maparg("<leader>dn", "n") ~= "", "the workflow should map <leader>dn")
assert(vim.fn.maparg("<leader>wn", "n") ~= "", "the workflow should map <leader>wn")

local templates = vim.fn.expand("~/gitLair/digital-notes/templates")
local templater = require("templater")
assert(templater.is_template(templates .. "/weekly.md"), "the digital-notes templates should be configured")

-- A template buffer keeps its placeholder; any other note gets a timestamp.
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

print("digital_notes: tests passed")
