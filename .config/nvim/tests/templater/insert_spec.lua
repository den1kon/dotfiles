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
check("replace", "two-lines.txt", text, { 2, 2 }, { "A", "B" }, { 1, 0 })
check("replace", "one-line.md", { "" }, { 1, 0 }, { "X" }, { 1, 0 })

-- Replacing is a single undo step that brings the old text back.
buffer(text, { 2, 2 })
-- Scripts run in one undo block, so end the setup's block like typing would.
vim.o.undolevels = vim.o.undolevels
vim.cmd("InsertTemplate two-lines.txt replace")
vim.cmd("silent undo")
assert(vim.deep_equal(lines(), text), "one undo should restore the replaced text: " .. vim.inspect(lines()))

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

-- Choosing interactively: with no arguments the template and position are asked for.
templater.setup({ directories = directory })
local original_select = vim.ui.select
local prompts = {}
local answers = {}
vim.ui.select = function(items, options, on_choice)
	table.insert(prompts, { items = items, options = options })
	on_choice(table.remove(answers, 1))
end

local function choose(chosen_answers)
	prompts, answers = {}, chosen_answers
	vim.cmd("InsertTemplate")
end

buffer({ "hello world", "second" }, { 1, 3 })
choose({ "two-lines.txt", "below" })
assert(#prompts == 2, "two prompts should be shown")
assert(vim.deep_equal(prompts[1].items, templater.list()), "the first prompt should list the templates")
assert(prompts[1].options.prompt == "Template", "the first prompt should say what it asks for")
assert(
	vim.deep_equal(prompts[2].items, require("templater.insert").positions),
	"the second prompt should list the positions"
)
assert(prompts[2].options.format_item("below"):find("below", 1, true), "positions should be shown with their meaning")
assert(prompts[2].options.format_item("below"):find("new lines below", 1, true), "positions should be described")
assert(
	vim.deep_equal(lines(), { "hello world", "A", "B", "second" }),
	"the chosen template should go to the chosen position"
)

buffer({ "keep" })
choose({})
assert(#prompts == 1 and vim.deep_equal(lines(), { "keep" }), "cancelling the template choice should stop there")
choose({ "one-line.md" })
assert(#prompts == 2 and vim.deep_equal(lines(), { "keep" }), "cancelling the position choice should insert nothing")

-- The insert goes to the window the command started in, even if the picker left another one current.
buffer({ "origin" })
local origin_window = vim.api.nvim_get_current_win()
local origin_buffer = vim.api.nvim_get_current_buf()
vim.ui.select = function(items, options, on_choice)
	vim.cmd("new")
	on_choice(table.remove(answers, 1))
end
answers = { "one-line.md", "end" }
vim.cmd("InsertTemplate")
assert(vim.api.nvim_get_current_win() == origin_window, "the original window should be current again")
assert(
	vim.deep_equal(vim.api.nvim_buf_get_lines(origin_buffer, 0, -1, false), { "origin", "X" }),
	"the text should land in the original buffer"
)
vim.cmd("only")

-- With no templates there is nothing to choose from.
vim.ui.select = function()
	error("no prompt expected")
end
local empty_directory = vim.fn.tempname()
vim.fn.mkdir(empty_directory, "p")
templater.setup({ directories = empty_directory })
local messages = {}
local notify = vim.notify
vim.notify = function(message, level)
	table.insert(messages, { message = message, level = level })
end
vim.cmd("InsertTemplate")
assert(#messages == 1 and messages[1].level == vim.log.levels.WARN, "no templates should be reported once")
vim.notify = notify
vim.ui.select = original_select
templater.setup({ directories = directory })
vim.fn.delete(empty_directory, "rf")

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
