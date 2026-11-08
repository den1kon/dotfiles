vim.o.swapfile = false

local directory = vim.fn.tempname()
vim.fn.mkdir(directory, "p")
vim.fn.writefile({
	"---",
	"id: 1",
	"tags:",
	"  - work/itemA",
	"  - fleeting-note",
	"---",
	"# A",
}, directory .. "/a.md")
vim.fn.writefile({ "---", "tags:", "  - work/itemB", "---", "# B" }, directory .. "/b.md")
vim.fn.writefile({ "# No frontmatter", "tags:", "  - work/itemA" }, directory .. "/ignored.md")
vim.fn.writefile({ "---", "title: x", "---" }, directory .. "/untagged.md")

local ok, tags = pcall(require, "digital_notes.tags")
assert(ok, "digital_notes.tags should load: " .. tostring(tags))
local items = tags.items(directory)
assert(#items == 3, "only YAML frontmatter list tags should be returned")
assert(items[1].tag == "work/itemA" and items[1].path == directory .. "/a.md")
assert(items[2].tag == "fleeting-note")
assert(items[3].tag == "work/itemB" and items[3].path == directory .. "/b.md")

vim.fn.delete(directory, "rf")
print("digital_notes tags: tests passed")
