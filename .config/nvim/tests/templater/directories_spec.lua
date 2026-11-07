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
	not missing_ok and missing_error:find("sample.md", 1, true),
	"a template should not be found before directories exist"
)

templater.add_directory(default_dir)
templater.add_directory(default_dir)
assert(
	templater.find("sample") == vim.fn.fnamemodify(default_dir, ":p") .. "sample.md",
	"default directory should be searched"
)
assert(
	vim.deep_equal(templater.build("sample", context), { "default T", "", "{{missing}}" }),
	"build should render the file into lines and keep unmapped placeholders"
)

-- User directories beat defaults and are searched in order.
local second_user_dir = vim.fn.tempname()
vim.fn.mkdir(second_user_dir, "p")
templater.setup({ directories = { user_dir, second_user_dir } })
assert(templater.find("sample"):find(default_dir, 1, true), "defaults should be used when the user has no such file")

vim.fn.writefile({ "second {{title}}" }, second_user_dir .. "/sample.md")
assert(templater.find("sample"):find(second_user_dir, 1, true), "later user directories should beat defaults")

vim.fn.writefile({ "first {{title}}" }, user_dir .. "/sample.md")
assert(templater.find("sample"):find(user_dir, 1, true), "earlier user directories should win")
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

-- Template detection.
templater.setup({ directories = user_dir })
assert(templater.is_template(user_dir .. "/weekly.md"), "files in a user directory are templates")
assert(templater.is_template(user_dir .. "/new-file.md"), "a template that does not exist yet is still a template")
assert(templater.is_template(user_dir .. "/nested/daily.md"), "subdirectories are templates")
assert(templater.is_template(default_dir .. "/sample.md"), "files in default directories are templates")
assert(not templater.is_template(vim.fn.tempname() .. ".md"), "other files are not templates")
assert(not templater.is_template(user_dir .. "-notes/2026-W40.md"), "directories sharing a prefix are not templates")
templater.setup()
assert(not templater.is_template(user_dir .. "/weekly.md"), "user directories count only while configured")

vim.fn.delete(user_dir, "rf")
vim.fn.delete(second_user_dir, "rf")
vim.fn.delete(default_dir, "rf")

print("templater directories: tests passed")
