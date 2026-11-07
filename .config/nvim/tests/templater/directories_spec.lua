local ok, templater = pcall(require, "templater")
assert(ok, "templater should load")

local context = { title = "T", now = 1791112654 }

local user_dir = vim.fn.tempname()
local default_dir = vim.fn.tempname()
vim.fn.mkdir(user_dir .. "/nested", "p")
vim.fn.mkdir(default_dir, "p")
vim.fn.writefile({ "default {{title}}", "", "{{missing}}" }, default_dir .. "/sample.md")

local missing_ok, missing_error = pcall(templater.find, "sample")
assert(
	not missing_ok and missing_error:find("no template named sample", 1, true),
	"a template should not be found before directories exist"
)

templater.setup({ directories = { default_dir } })
assert(
	templater.find("sample") == vim.fn.fnamemodify(default_dir, ":p") .. "sample.md",
	"a configured directory should be searched"
)
assert(
	vim.deep_equal(templater.build("sample", context), { "default T", "", "{{missing}}" }),
	"build should render the file into lines and keep unmapped placeholders"
)

-- Directories are searched in order; the first match wins.
local second_user_dir = vim.fn.tempname()
vim.fn.mkdir(second_user_dir, "p")
templater.setup({ directories = { user_dir, second_user_dir, default_dir } })
assert(
	templater.find("sample"):find(default_dir, 1, true),
	"later directories are used when earlier ones lack the file"
)

vim.fn.writefile({ "second {{title}}" }, second_user_dir .. "/sample.md")
assert(templater.find("sample"):find(second_user_dir, 1, true), "a directory should beat the ones after it")

vim.fn.writefile({ "first {{title}}" }, user_dir .. "/sample.md")
assert(templater.find("sample"):find(user_dir, 1, true), "the first directory should win")
assert(vim.deep_equal(templater.build("sample", context), { "first T" }), "build should use the winning file")

-- A single string is accepted, `~` is expanded, and relative paths use the working directory.
templater.setup({ directories = second_user_dir })
assert(vim.deep_equal(templater.build("sample", context), { "second T" }), "a single directory string should work")

local original_directory = vim.fn.getcwd()
vim.cmd.cd(vim.fn.fnameescape(vim.fs.dirname(user_dir)))
templater.setup({ directories = vim.fs.basename(user_dir) })
assert(
	vim.deep_equal(templater.build("sample", context), { "first T" }),
	"relative directories use the working directory"
)
vim.cmd.cd(vim.fn.fnameescape(original_directory))

local home_ok = pcall(templater.setup, { directories = "~/templater-directory-that-does-not-exist" })
assert(home_ok, "a directory with ~ should be accepted even when it is missing")

-- Any file is a template, found by exact name, by name plus .md, or by path.
templater.setup({ directories = user_dir })
vim.fn.writefile({ "yaml {{title}}" }, user_dir .. "/frontmatter.yaml")
vim.fn.writefile({ "plain {{title}}" }, user_dir .. "/plain")
vim.fn.writefile({ "exact {{title}}" }, user_dir .. "/both")
vim.fn.writefile({ "md {{title}}" }, user_dir .. "/both.md")
assert(
	vim.deep_equal(templater.build("frontmatter.yaml", context), { "yaml T" }),
	"a name with any extension should work"
)
assert(vim.deep_equal(templater.build("plain", context), { "plain T" }), "a name without extension should work")
assert(vim.deep_equal(templater.build("both", context), { "exact T" }), "the exact file name should beat name plus .md")
assert(
	vim.deep_equal(templater.build(user_dir .. "/frontmatter.yaml", context), { "yaml T" }),
	"an absolute path should work"
)
local path_ok, path_error = pcall(templater.find, user_dir .. "/missing")
assert(not path_ok and path_error:find("no template file", 1, true), "a missing path should be reported")

vim.uv.fs_symlink(user_dir .. "/plain", user_dir .. "/linked-file")
vim.uv.fs_symlink(user_dir .. "/nested", user_dir .. "/linked-directory")
local listed = templater.list()
assert(vim.tbl_contains(listed, "linked-file"), "a symlink to a file should be listed")
assert(not vim.tbl_contains(listed, "linked-directory"), "a symlink to a directory should not be listed")
assert(
	vim.tbl_contains(listed, "frontmatter.yaml") and vim.tbl_contains(listed, "plain"),
	"list should show file names as they are"
)
assert(vim.tbl_contains(listed, "sample.md"), "list should include every file in the directories")
assert(not vim.tbl_contains(listed, "nested"), "list should not include directories")
local sorted = vim.deepcopy(listed)
table.sort(sorted)
assert(vim.deep_equal(listed, sorted), "list should be sorted")

-- Template detection.
templater.setup({ directories = { user_dir, default_dir } })
assert(templater.is_template(user_dir .. "/weekly.md"), "files in a user directory are templates")
assert(templater.is_template(user_dir .. "/new-file.md"), "a template that does not exist yet is still a template")
assert(templater.is_template(user_dir .. "/nested/daily.md"), "subdirectories are templates")
assert(templater.is_template(default_dir .. "/sample.md"), "files in every configured directory are templates")
assert(not templater.is_template(vim.fn.tempname() .. ".md"), "other files are not templates")
assert(not templater.is_template(user_dir .. "-notes/2026-W40.md"), "directories sharing a prefix are not templates")
templater.setup()
assert(not templater.is_template(user_dir .. "/weekly.md"), "user directories count only while configured")

vim.fn.delete(user_dir, "rf")
vim.fn.delete(second_user_dir, "rf")
vim.fn.delete(default_dir, "rf")

print("templater directories: tests passed")
