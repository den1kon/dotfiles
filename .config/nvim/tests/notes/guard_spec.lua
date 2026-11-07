-- slipnote.nvim is not loaded in isolated tests, so a stand-in module records
-- when its updated_at refresh runs.
local refreshed = {}
package.loaded["slipnote.frontmatter"] = {
	update_frontmatter_updated_at = function(buffer)
		table.insert(refreshed, vim.api.nvim_buf_get_name(buffer))
	end,
}

local ok, guard = pcall(require, "notes.guard")
assert(ok, "notes.guard should load")

local templates_dir = vim.fn.tempname()
local notes_dir = vim.fn.tempname()
vim.fn.mkdir(templates_dir, "p")
vim.fn.mkdir(notes_dir, "p")
require("templater").setup({ directories = templates_dir })

guard.setup()
guard.setup()

local frontmatter = package.loaded["slipnote.frontmatter"]
local template_buffer = vim.fn.bufadd(templates_dir .. "/weekly.md")
local note_buffer = vim.fn.bufadd(notes_dir .. "/2026-W40.md")

frontmatter.update_frontmatter_updated_at(template_buffer)
assert(#refreshed == 0, "saving a template should not refresh updated_at")

frontmatter.update_frontmatter_updated_at(note_buffer)
assert(#refreshed == 1, "saving a normal note should still refresh updated_at exactly once")
assert(vim.endswith(refreshed[1], "/2026-W40.md"), "the refresh should receive the saved buffer")

vim.fn.delete(templates_dir, "rf")
vim.fn.delete(notes_dir, "rf")

print("notes.guard: tests passed")
