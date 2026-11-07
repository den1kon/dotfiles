local ok, links = pcall(require, "markdown-navigation.links")
assert(ok, "markdown-navigation.links should load")

-- Finding links.
local line = "see [text](a.md) and [[b|alias]] or [[c]]"
local found = links.find(line)
assert(#found == 3, "all three links should be found")
assert(found[1].kind == "markdown" and found[1].target == "a.md", "a markdown link should give its path")
assert(found[2].kind == "wikilink" and found[2].target == "b", "a wikilink should give its target without the alias")
assert(found[3].kind == "wikilink" and found[3].target == "c", "a plain wikilink should give its target")
assert(line:sub(found[1].start, found[1].finish) == "[text](a.md)", "positions should span the whole link")
assert(line:sub(found[2].start, found[2].finish) == "[[b|alias]]", "wikilink positions should include the brackets")
assert(found[1].start < found[2].start and found[2].start < found[3].start, "links should be in order of appearance")

assert(#links.find("no links, [just brackets] and (parens)") == 0, "plain text has no links")
assert(links.find("[[2026-W39.md|Last weekly note]]")[1].target == "2026-W39.md", "generated note links should parse")
assert(links.find("[x]()")[1].target == "", "an empty target is still a link")

-- Finding the link at a column.
assert(links.at_column(line, found[1].start).target == "a.md", "the first column of a link is inside it")
assert(links.at_column(line, found[1].finish).target == "a.md", "the last column of a link is inside it")
assert(links.at_column(line, found[2].start + 3).target == "b", "a column inside the alias belongs to the wikilink")

local none, none_err = links.at_column(line, 1)
assert(none == nil and none_err == "No link found at the cursor.", "text outside links has no link")
local empty, empty_err = links.at_column("plain", 2)
assert(empty == nil and empty_err == "No links found on this line.", "a line without links says so")

-- Resolving links against the containing file.
local function resolve(target, kind, file)
	return links.resolve({ start = 1, finish = 1, target = target, kind = kind }, file or "/notes/dir/current.md")
end

assert(resolve("other", "wikilink") == "/notes/dir/other.md", "a wikilink without extension gets .md")
assert(resolve("other.md", "wikilink") == "/notes/dir/other.md", "a wikilink with an extension is kept")
assert(resolve("data.txt", "wikilink") == "/notes/dir/data.txt", "other extensions are kept")
assert(resolve("other", "markdown") == "/notes/dir/other", "a markdown link is not given an extension")
assert(resolve("sub/x.md", "markdown") == "/notes/dir/sub/x.md", "relative paths use the file's directory")
assert(resolve("../up.md", "markdown") == "/notes/up.md", "parent references are collapsed")
assert(resolve("/abs/path.md", "markdown") == "/abs/path.md", "absolute paths are kept")
assert(resolve("with space.md", "markdown") == "/notes/dir/with space.md", "spaces are allowed")
assert(
	resolve("x.md", "markdown", "relative/file.md") == vim.fs.normalize(vim.fn.getcwd() .. "/relative/x.md"),
	"a relative current file resolves against the working directory"
)

for _, case in ipairs({
	{ "", "Link target is empty." },
	{ "dir/", "Link has no filename." },
	{ "bad?.md", "Filename contains forbidden characters." },
	{ "a:b.md", "Filename contains forbidden characters." },
	{ "trailing.", "Filename cannot end with a space or dot." },
	{ "trailing ", "Filename cannot end with a space or dot." },
}) do
	local path, err = resolve(case[1], "markdown")
	assert(
		path == nil and err == case[2],
		("%q should be rejected with %q, got %s"):format(case[1], case[2], tostring(err))
	)
end

-- Searching for flat wikilinks in nearby directories.
local root = vim.fn.resolve(vim.fn.tempname())
local function touch(relative)
	vim.fn.mkdir(vim.fs.dirname(root .. "/" .. relative), "p")
	vim.fn.writefile({}, root .. "/" .. relative)
end

for _, file in ipairs({
	"root_level.md",
	"folder_a/top.md",
	"folder_a/both.md",
	"folder_a/folder_b/file.md",
	"folder_a/folder_b/same.md",
	"folder_a/folder_b/dup.md",
	"folder_a/folder_b/child/dup.md",
	"folder_a/folder_b/child/deeper.md",
	"folder_a/folder_b/child/both.md",
	"folder_a/folder_b/child/grand/deepest.md",
	"folder_a/folder_b/a_dir/ordered.md",
	"folder_a/folder_b/b_dir/ordered.md",
	"folder_a/folder_b/.hidden/secret.md",
	"folder_a/folder_c/sibling.md",
	"folder_a/folder_b/image.png",
}) do
	touch(file)
end

local current = root .. "/folder_a/folder_b/file.md"
local function find(target, search)
	local path, err = links.resolve({ start = 1, finish = 1, target = target, kind = "wikilink" }, current, search)
	assert(path, err)
	return path:sub(#root + 2)
end

assert(find("same") == "folder_a/folder_b/same.md", "the file's own directory is searched first")
assert(find("dup") == "folder_a/folder_b/dup.md", "the own directory beats a subdirectory")
assert(find("both") == "folder_a/folder_b/child/both.md", "a subdirectory beats a parent directory")
assert(find("deeper") == "folder_a/folder_b/child/deeper.md", "one level down is searched by default")
assert(find("top") == "folder_a/top.md", "one level up is searched by default")
assert(find("ordered") == "folder_a/folder_b/a_dir/ordered.md", "directories at one level are tried in name order")
assert(find("deepest.md") == "folder_a/folder_b/deepest.md", "two levels down is not searched by default")
assert(find("root_level") == "folder_a/folder_b/root_level.md", "two levels up is not searched by default")
assert(find("sibling") == "folder_a/folder_b/sibling.md", "sibling directories are not searched")
assert(find("secret") == "folder_a/folder_b/secret.md", "hidden directories are not searched")
assert(find("missing") == "folder_a/folder_b/missing.md", "an unknown link points to a new note next to the file")
assert(find("image.png") == "folder_a/folder_b/image.png", "an explicit extension is kept")
assert(find("child/deeper") == "folder_a/folder_b/child/deeper.md", "a path inside a wikilink works")

assert(find("deepest", { down = 2, up = 1 }) == "folder_a/folder_b/child/grand/deepest.md", "down is configurable")
assert(find("root_level", { down = 1, up = 2 }) == "root_level.md", "up is configurable")
assert(find("deeper", { down = 0, up = 1 }) == "folder_a/folder_b/deeper.md", "down = 0 searches no subdirectories")
assert(find("top", { down = 1, up = 0 }) == "folder_a/folder_b/top.md", "up = 0 searches no parent directories")
assert(find("same", { down = 0, up = 0 }) == "folder_a/folder_b/same.md", "the own directory is always searched")

-- Markdown links never search: they are relative or absolute.
local plain = links.resolve({ start = 1, finish = 1, target = "deeper.md", kind = "markdown" }, current)
assert(plain == root .. "/folder_a/folder_b/deeper.md", "markdown links are not searched")
local absolute =
	links.resolve({ start = 1, finish = 1, target = root .. "/folder_a/top.md", kind = "wikilink" }, current)
assert(absolute == root .. "/folder_a/top.md", "an absolute wikilink is used as written")

vim.fn.delete(root, "rf")

print("markdown-navigation links: tests passed")
