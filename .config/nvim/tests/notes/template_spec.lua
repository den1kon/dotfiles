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

print("notes.template: tests passed")
