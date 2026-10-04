local ok, note = pcall(require, "notes.note")

assert(ok, "notes.note should load")

local notes_dir = vim.fn.tempname()
vim.fn.mkdir(notes_dir, "p")
vim.fn.writefile({}, notes_dir .. "/2026-09-30.md")
vim.fn.writefile({}, notes_dir .. "/2026-10-02.md")
vim.fn.writefile({}, notes_dir .. "/2026-10-05.md")

local previous = note.find_previous(notes_dir, "2026-10-04", "^(%d%d%d%d%-%d%d%-%d%d)%.md$")
assert(previous == "2026-10-02.md", "previous note should be the latest existing earlier note")

local missing = note.find_previous(notes_dir, "2026-09-01", "^(%d%d%d%d%-%d%d%-%d%d)%.md$")
assert(missing == nil, "previous note should be nil when none exists")

vim.o.swapfile = false
local window = vim.api.nvim_get_current_win()
local new_note = {
	directory = notes_dir,
	filename = "2026-10-04.md",
	build = function()
		return { "new content" }
	end,
}
note.open(new_note)
assert(vim.api.nvim_get_current_win() == window, "note should open in the current window")
assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "new content" }), "new note should be populated")

local reopened, populated = pcall(note.open, new_note)
assert(reopened, "reopening the current unsaved note should not raise an error")
assert(populated == false, "reopening the current note should not insert the template twice")
assert(vim.bo.modified, "the generated note should remain modified until the user saves it")
assert(vim.fn.filereadable(notes_dir .. "/2026-10-04.md") == 0, "generating a note should not save it to disk")

vim.cmd("enew!")
vim.fn.writefile({ "existing content" }, notes_dir .. "/2026-10-03.md")
note.open({
	directory = notes_dir,
	filename = "2026-10-03.md",
	build = function()
		return { "replacement" }
	end,
})
assert(
	vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "existing content" }),
	"existing note should never be overwritten"
)

vim.cmd("enew!")
vim.fn.delete(notes_dir, "rf")

print("notes.note: tests passed")
