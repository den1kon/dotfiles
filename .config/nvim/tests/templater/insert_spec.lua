local ok, templater = pcall(require, "templater")
assert(ok, "templater should load")

vim.o.swapfile = false

local directory = vim.fn.tempname()
vim.fn.mkdir(directory, "p")
vim.fn.writefile({ "A", "B" }, directory .. "/two-lines.txt")
vim.fn.writefile({ "X" }, directory .. "/one-line.md")
vim.fn.writefile({ "---", "title: {{title}}", "file: {{filename}}", "---", "" }, directory .. "/frontmatter")

templater.setup({ directories = directory })

local function buffer(lines, cursor)
	vim.cmd("enew!")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.api.nvim_win_set_cursor(0, cursor or { 1, 0 })
end

local function lines()
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function cursor()
	return vim.api.nvim_win_get_cursor(0)
end

local function check(position, template, start_lines, start_cursor, expected_lines, expected_cursor)
	buffer(start_lines, start_cursor)
	vim.cmd(("InsertTemplate %s %s"):format(template, position))
	assert(vim.deep_equal(lines(), expected_lines), position .. " inserted wrongly: " .. vim.inspect(lines()))
	assert(vim.deep_equal(cursor(), expected_cursor), position .. " left the cursor at " .. vim.inspect(cursor()))
end

-- Every position, with a one-line and a two-line template.
local text = { "hello world", "second" }
check("cursor", "one-line.md", text, { 1, 5 }, { "helloX world", "second" }, { 1, 5 })
check("after-cursor", "one-line.md", text, { 1, 5 }, { "hello Xworld", "second" }, { 1, 6 })
check("cursor", "two-lines.txt", text, { 1, 5 }, { "helloA", "B world", "second" }, { 1, 5 })
check("above", "two-lines.txt", text, { 2, 2 }, { "hello world", "A", "B", "second" }, { 2, 0 })
check("below", "two-lines.txt", text, { 1, 3 }, { "hello world", "A", "B", "second" }, { 2, 0 })
check("start", "two-lines.txt", text, { 2, 2 }, { "A", "B", "hello world", "second" }, { 4, 2 })
check("end", "two-lines.txt", text, { 1, 3 }, { "hello world", "second", "A", "B" }, { 1, 3 })

-- A new buffer's lone empty line is replaced rather than kept.
check("start", "two-lines.txt", { "" }, { 1, 0 }, { "A", "B" }, { 1, 0 })
check("end", "two-lines.txt", { "" }, { 1, 0 }, { "A", "B" }, { 1, 0 })

-- The position defaults to the cursor.
buffer({ "ab" }, { 1, 1 })
vim.cmd("InsertTemplate one-line.md")
assert(vim.deep_equal(lines(), { "aXb" }), "the default position should be the cursor")

-- Templates are rendered with the buffer's own details.
vim.cmd("enew!")
vim.api.nvim_buf_set_name(0, directory .. "/notes/my-note.md")
vim.cmd("InsertTemplate frontmatter start")
assert(
	vim.deep_equal(lines(), { "---", "title: my-note", "file: my-note.md", "---", "" }),
	"title and filename should come from the buffer: " .. vim.inspect(lines())
)

-- The template can be a path.
buffer({ "" })
vim.cmd("InsertTemplate " .. vim.fn.fnameescape(directory .. "/one-line.md") .. " start")
assert(vim.deep_equal(lines(), { "X" }), "a path should be accepted as the template")

-- Failures are reported, not thrown, and change nothing.
local errors = {}
local original_notify = vim.notify
vim.notify = function(message, level)
	table.insert(errors, { message = message, level = level })
end

buffer({ "keep" })
vim.cmd("InsertTemplate does-not-exist start")
assert(#errors == 1 and errors[1].level == vim.log.levels.ERROR, "a missing template should report one error")
assert(errors[1].message:find("does-not-exist", 1, true), "the error should name the template")

vim.cmd("InsertTemplate one-line.md sideways")
assert(#errors == 2 and errors[2].message:find("unknown position", 1, true), "an unknown position should be reported")
assert(errors[2].message:find("after-cursor", 1, true), "the error should list the valid positions")

vim.cmd("InsertTemplate one-line.md start extra")
assert(#errors == 3 and errors[3].message:find("expected", 1, true), "extra arguments should be reported")
assert(vim.deep_equal(lines(), { "keep" }), "failed commands should not change the buffer")
vim.notify = original_notify

-- Completion.
local function complete(command_line)
	return vim.fn.getcompletion(command_line, "cmdline")
end
local names = complete("InsertTemplate ")
assert(
	vim.tbl_contains(names, "one-line.md") and vim.tbl_contains(names, "frontmatter"),
	"templates should be completed"
)
assert(vim.deep_equal(complete("InsertTemplate one"), { "one-line.md" }), "template completion should filter by prefix")
assert(
	vim.deep_equal(complete("InsertTemplate frontmatter "), require("templater.insert").positions),
	"positions should be completed"
)
assert(
	vim.deep_equal(complete("InsertTemplate frontmatter a"), { "after-cursor", "above" }),
	"position completion should filter by prefix"
)
assert(vim.deep_equal(complete("InsertTemplate frontmatter start "), {}), "nothing follows the position")
local path_matches = complete("InsertTemplate " .. directory .. "/two")
assert(#path_matches == 1 and path_matches[1]:find("two-lines.txt", 1, true), "paths should be completed as files")

vim.cmd("enew!")
vim.fn.delete(directory, "rf")

print("templater insert: tests passed")
