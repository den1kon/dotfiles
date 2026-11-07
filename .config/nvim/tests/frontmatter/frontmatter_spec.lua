local ok, frontmatter = pcall(require, "frontmatter")
assert(ok, "frontmatter should load")

vim.o.swapfile = false

local function buffer_lines()
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function reset_buffer(lines)
	vim.cmd("enew!")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

frontmatter.setup()
assert(vim.fn.exists(":InsertFrontmatter") == 0, "creating frontmatter is a template's job, not a command here")

-- Refreshing updated_at in a buffer.
frontmatter.setup()
local old = 'updated_at: "2000-01-01T00:00:00Z"'
local function with_markdown(lines)
	reset_buffer(lines)
	vim.bo.filetype = "markdown"
end

with_markdown({ "---", "id: 1", old, "---", "updated_at: keep me" })
assert(frontmatter.refresh_updated_at(0, 1791112654) == true, "a markdown buffer with the field should update")
assert(
	vim.deep_equal(
		buffer_lines(),
		{ "---", "id: 1", 'updated_at: "2026-10-04T11:17:34Z"', "---", "updated_at: keep me" }
	),
	"only the updated_at line inside the frontmatter should change"
)

with_markdown({ "---", "id: 1", "---", old })
assert(frontmatter.refresh_updated_at() == false, "frontmatter without the field should not update")
assert(buffer_lines()[4] == old, "a field in the body should never be touched")

with_markdown({ "no frontmatter", old })
assert(
	frontmatter.refresh_updated_at() == false and buffer_lines()[2] == old,
	"buffers without frontmatter are skipped"
)

with_markdown({ "---", old })
assert(frontmatter.refresh_updated_at() == false, "an unterminated block should be left alone")

reset_buffer({ "---", old, "---" })
vim.bo.filetype = "text"
assert(frontmatter.refresh_updated_at() == false and buffer_lines()[2] == old, "other filetypes are skipped")

with_markdown({ "---", old, "---", "a", "b" })
vim.api.nvim_win_set_cursor(0, { 5, 0 })
frontmatter.refresh_updated_at()
assert(vim.api.nvim_win_get_cursor(0)[1] == 5, "the cursor should stay where it was")

-- exclude decides per file.
local skipped_paths = {}
frontmatter.setup({
	exclude = function(path)
		table.insert(skipped_paths, path)
		return vim.endswith(path, "skip.md")
	end,
})

local directory = vim.fn.tempname()
vim.fn.mkdir(directory, "p")

-- Saving through the real BufWritePre hook.
local function write_note(name)
	vim.fn.writefile({ "---", "id: 1", old, "---", "body" }, directory .. "/" .. name)
	vim.cmd.edit(vim.fn.fnameescape(directory .. "/" .. name))
	vim.bo.filetype = "markdown"
	vim.cmd.write()
	return vim.fn.readfile(directory .. "/" .. name)
end

local saved = write_note("note.md")
assert(saved[3] ~= old, "saving should refresh updated_at")
assert(
	saved[3]:match('^updated_at: "%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ"$'),
	"the refreshed value should be an ISO 8601 UTC time"
)
assert(
	saved[1] == "---" and saved[2] == "id: 1" and saved[4] == "---" and saved[5] == "body",
	"saving should keep other lines"
)

local skipped = write_note("skip.md")
assert(skipped[3] == old, "excluded files should keep their updated_at")
assert(vim.endswith(skipped_paths[#skipped_paths], "skip.md"), "exclude should receive the buffer's path")

-- update_on_save = false and repeated setup.
frontmatter.setup({ update_on_save = false })
assert(write_note("manual.md")[3] == old, "update_on_save = false should leave updated_at alone")

frontmatter.setup()
frontmatter.setup()
local before = #vim.api.nvim_get_autocmds({ group = "FrontmatterUpdatedAt", event = "BufWritePre" })
assert(before == 1, "calling setup repeatedly should keep a single save hook")

vim.cmd("enew!")
vim.fn.delete(directory, "rf")
print("frontmatter: tests passed")
