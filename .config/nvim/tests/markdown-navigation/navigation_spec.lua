local ok, navigation = pcall(require, "markdown-navigation")
assert(ok, "markdown-navigation should load")

vim.o.swapfile = false
vim.cmd("filetype on")

local warnings = {}
local original_notify = vim.notify
vim.notify = function(message, level)
	table.insert(warnings, { message = message, level = level })
end

local directory = vim.fn.tempname()
vim.fn.mkdir(directory, "p")
local function path(name)
	return vim.fn.resolve(directory .. "/" .. name)
end

vim.fn.writefile({ "[[b]] and [c](c.md)", "no link here", "[bad?](bad?.md)" }, directory .. "/a.md")
vim.fn.writefile({ "this is b", "[[a|back to a]]" }, directory .. "/b.md")
vim.fn.writefile({ "this is c" }, directory .. "/c.md")

navigation.setup()
for _, command in ipairs({ "FollowLink", "FollowLinkInNewTab", "FollowBack" }) do
	assert(vim.fn.exists(":" .. command) == 2, "setup should register :" .. command)
end
assert(vim.fn.maparg("<leader>fl", "n") == "", "setup should not register keymaps")

local function current_file()
	return vim.fn.resolve(vim.api.nvim_buf_get_name(0))
end
local function open(name)
	vim.cmd.edit(vim.fn.fnameescape(directory .. "/" .. name))
end
local function place_cursor(line, column)
	vim.api.nvim_win_set_cursor(0, { line, column })
end

-- Following a wikilink and a markdown link, then going back through both.
open("a.md")
assert(vim.bo.filetype == "markdown", "the test files should be detected as markdown")
place_cursor(1, 1)
vim.cmd("FollowLink")
assert(current_file() == path("b.md"), "a wikilink should open its .md file")

place_cursor(2, 3)
vim.cmd("FollowLink")
assert(current_file() == path("a.md"), "a wikilink with an alias should open its target")

vim.cmd("FollowBack")
assert(current_file() == path("b.md"), "back should return to the previous buffer")
vim.cmd("FollowBack")
assert(current_file() == path("a.md"), "back should keep going through the history")

place_cursor(1, 13)
vim.cmd("FollowLink")
assert(current_file() == path("c.md"), "a markdown link should open its file")

-- A new tab.
open("a.md")
place_cursor(1, 1)
local tabs_before = vim.fn.tabpagenr("$")
vim.cmd("FollowLinkInNewTab")
assert(vim.fn.tabpagenr("$") == tabs_before + 1, "FollowLinkInNewTab should open a tab")
assert(current_file() == path("b.md"), "the new tab should show the target")
vim.cmd("tabclose")

-- Failures warn and leave everything as it was.
open("a.md")
local function expect_warning(message_part, action)
	local count = #warnings
	local file = current_file()
	action()
	assert(#warnings == count + 1, "exactly one warning should be shown for: " .. message_part)
	local warning = warnings[#warnings]
	assert(warning.level == vim.log.levels.WARN, "failures should be warnings")
	assert(warning.message:find(message_part, 1, true), "the warning should mention: " .. message_part)
	assert(current_file() == file, "a failed jump should not change the buffer")
end

place_cursor(2, 0)
expect_warning("No links found on this line.", function()
	vim.cmd("FollowLink")
end)

place_cursor(1, 7)
expect_warning("No link found at the cursor.", function()
	vim.cmd("FollowLink")
end)

place_cursor(3, 2)
expect_warning("forbidden characters", function()
	vim.cmd("FollowLink")
end)

vim.cmd("enew!")
vim.w.markdown_navigation_history = nil
expect_warning("Buffer history is empty", function()
	vim.cmd("FollowBack")
end)

-- History skips buffers that no longer exist: a -> b -> a -> c, then b is deleted.
vim.cmd("silent! only")
open("a.md")
place_cursor(1, 1)
vim.cmd("FollowLink")
local b_buffer = vim.api.nvim_get_current_buf()
assert(current_file() == path("b.md"), "the chain should start with a jump to b")
place_cursor(2, 1)
vim.cmd("FollowLink")
place_cursor(1, 13)
vim.cmd("FollowLink")
assert(current_file() == path("c.md"), "the chain should end in c")

vim.cmd("bdelete " .. b_buffer)
vim.cmd("FollowBack")
assert(current_file() == path("a.md"), "back from c should land on a")
vim.cmd("FollowBack")
assert(current_file() == path("a.md"), "back should skip the deleted buffer instead of failing")

vim.cmd("enew!")
vim.fn.delete(directory, "rf")
vim.notify = original_notify

print("markdown-navigation: tests passed")
