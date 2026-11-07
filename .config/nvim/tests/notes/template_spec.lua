local template_ok, template = pcall(require, "notes.template")
local variables_ok, variables = pcall(require, "notes.variables")

assert(template_ok, "notes.template should load")
assert(variables_ok, "notes.variables should load")

local context = { title = "2026-W40", directory = "/unused", now = 1791112654 }
local resolvers = variables.resolvers()

local function render(text, extra)
	return template.render(text, context, extra and variables.resolvers(extra) or resolvers)
end

assert(render("# {{title}}") == "# 2026-W40", "title should come from the context")
assert(render("id: {{id}}") == "id: 1791112654", "id should be the timestamp")
assert(render('"{{created_at}}"') == '"2026-10-04T11:17:34Z"', "created_at should be UTC")
assert(render('"{{updated_at}}"') == '"2026-10-04T11:17:34Z"', "updated_at should be UTC")
assert(render("{{ title }}") == "2026-W40", "whitespace inside braces should be ignored")
assert(render("{{title}} and {{title}}") == "2026-W40 and 2026-W40", "every placeholder should be replaced")

assert(render("{{date}}") == os.date("%Y-%m-%d", 1791112654), "date should default to an ISO date")
assert(render("{{date:%Y}}") == os.date("%Y", 1791112654), "date should accept an os.date format")
assert(render("{{date:%H:%M}}") == os.date("%H:%M", 1791112654), "argument should keep later colons")

assert(render("{{missing}}") == "{{missing}}", "unmapped variables should stay as written")
assert(render("{{variable not mapped}}") == "{{variable not mapped}}", "invalid placeholders should stay as written")
assert(render("{{missing:argument}}") == "{{missing:argument}}", "unmapped variables with arguments should stay")
assert(render("{{}}") == "{{}}", "empty placeholders should stay as written")
assert(render("keep % signs {{title}}") == "keep % signs 2026-W40", "percent signs should pass through")

assert(render("a{{none}}b", { none = function() end }) == "ab", "nil values should render as nothing")
assert(render("a\n{{none}}\nb", { none = function() end }) == "a\n\nb", "nil values should keep their line")
assert(render("{{lines}}", {
	lines = function()
		return "one\ntwo"
	end,
}) == "one\ntwo", "values may span lines")
assert(render("{{title}}", {
	title = function()
		return "override"
	end,
}) == "override", "extra variables should win")
assert(render("{{echo:hello}}", {
	echo = function(_, argument)
		return argument
	end,
}) == "hello", "variables should receive their argument")

local calls = 0
render("no placeholders here", {
	counted = function()
		calls = calls + 1
	end,
})
assert(calls == 0, "unused variables should not be evaluated")

-- Template lookup and building. A temporary runtime directory plays the part of
-- the bundled templates so the real runtimepath search is exercised.
local config = require("notes.config")

local runtime_dir = vim.fn.tempname()
vim.fn.mkdir(runtime_dir .. "/lua/notes/templates", "p")
vim.fn.writefile({ "bundled {{title}}", "", "{{extra}}" }, runtime_dir .. "/lua/notes/templates/sample.md")
vim.opt.runtimepath:append(runtime_dir)

local custom_dir = vim.fn.tempname()
vim.fn.mkdir(custom_dir, "p")

local bundled_path = template.find("sample")
assert(vim.endswith(bundled_path, "lua/notes/templates/sample.md"), "templates should be found on the runtimepath")
assert(
	vim.deep_equal(template.build("sample", context), { "bundled 2026-W40", "", "{{extra}}" }),
	"build should split the rendered text into lines and keep unmapped placeholders"
)

local ok_missing, missing_error = pcall(template.find, "does-not-exist")
assert(not ok_missing and missing_error:find("does%-not%-exist.md"), "a missing template should name the file")

config.setup({ templates_dir = custom_dir })
assert(template.find("sample") == bundled_path, "bundled template should be used when templates_dir lacks the file")

vim.fn.writefile({ "custom {{title}}" }, custom_dir .. "/sample.md")
assert(template.find("sample") == custom_dir .. "/sample.md", "templates_dir should take precedence")
assert(vim.deep_equal(template.build("sample", context), { "custom 2026-W40" }), "build should render the custom file")

local original_directory = vim.fn.getcwd()
vim.cmd.cd(vim.fn.fnameescape(vim.fs.dirname(custom_dir)))
config.setup({ templates_dir = vim.fs.basename(custom_dir) })
assert(
	vim.fn.resolve(template.find("sample")) == vim.fn.resolve(custom_dir .. "/sample.md"),
	"a relative templates_dir should resolve against the working directory"
)
vim.cmd.cd(vim.fn.fnameescape(original_directory))

vim.fn.writefile({ "{{title}} {{shared}}" }, custom_dir .. "/layers.md")
config.setup({
	templates_dir = custom_dir,
	variables = {
		shared = function()
			return "user"
		end,
	},
})
assert(
	vim.deep_equal(
		template.build("layers", context, {
			shared = function()
				return "note type"
			end,
		}),
		{ "2026-W40 user" }
	),
	"user variables should override note-type variables"
)
assert(
	vim.deep_equal(
		template.build("layers", context, {
			title = function()
				return "note type"
			end,
		}),
		{ "note type user" }
	),
	"note-type variables should override built-ins"
)

config.setup()
vim.fn.delete(runtime_dir, "rf")
vim.fn.delete(custom_dir, "rf")

print("notes.template: tests passed")
