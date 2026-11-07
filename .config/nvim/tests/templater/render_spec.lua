local ok, templater = pcall(require, "templater")
assert(ok, "templater should load")

local context = { title = "My title", now = 1791112654 }

local function render(text, variables, render_context)
	return templater.render(text, render_context or context, variables)
end

-- Predefined variables.
assert(render("# {{title}}") == "# My title", "title should come from the context")
assert(render("id: {{id}}") == "id: 1791112654", "id should be the timestamp")
assert(render("{{ title }}") == "My title", "whitespace inside braces should be ignored")
assert(render("{{title}} {{title}}") == "My title My title", "every placeholder should be replaced")
assert(render("{{date}}") == os.date("%Y-%m-%d", 1791112654), "date should default to an ISO date")
assert(render("{{date:%Y}}") == os.date("%Y", 1791112654), "date should accept an os.date format")
assert(render("{{time}}") == os.date("%H:%M", 1791112654), "time should default to hours and minutes")
assert(render("{{time:%H:%M:%S}}") == os.date("%H:%M:%S", 1791112654), "an argument keeps later colons")
assert(render("{{utc}}") == "2026-10-04T11:17:34Z", "utc should default to ISO 8601")
assert(render("{{utc:%H}}") == "11", "utc should accept a format")
assert(render("{{id}}", nil, { title = "x" }) ~= "", "now should default to the current time")

-- Unmapped or invalid placeholders stay exactly as written.
assert(render("{{missing}}") == "{{missing}}", "unmapped variables should stay")
assert(render("{{variable not mapped}}") == "{{variable not mapped}}", "invalid placeholders should stay")
assert(render("{{missing:argument}}") == "{{missing:argument}}", "unmapped variables with arguments should stay")
assert(render("{{}}") == "{{}}", "empty placeholders should stay")
assert(render("keep % signs {{title}}") == "keep % signs My title", "percent signs should pass through")

-- Caller variables.
local function nothing() end
assert(render("a{{none}}b", { none = nothing }) == "ab", "nil values render as nothing")
assert(render("a\n{{none}}\nb", { none = nothing }) == "a\n\nb", "nil values keep their line")
assert(render("{{lines}}", {
	lines = function()
		return "one\ntwo"
	end,
}) == "one\ntwo", "values may span lines")
assert(render("{{title}}", {
	title = function()
		return "override"
	end,
}) == "override", "caller variables should override predefined ones")
assert(render("{{echo:hello}}", {
	echo = function(_, argument)
		return argument
	end,
}) == "hello", "variables should receive their argument")
assert(render("{{shout}}", {
	shout = function(render_context)
		return render_context.word:upper()
	end,
}, { word = "hi", now = 1 }) == "HI", "variables should see extra context fields")

-- Text and number fields of the context are variables too.
assert(
	render("{{word}} {{count}}", nil, { word = "hi", count = 3, now = 1 }) == "hi 3",
	"context fields should be variables"
)
assert(render("{{flag}}", nil, { flag = true, now = 1 }) == "{{flag}}", "only text and number fields count")
assert(render("{{word}}", {
	word = function()
		return "fn"
	end,
}, { word = "ctx", now = 1 }) == "fn", "variables should beat context fields")
assert(
	render("{{word}}", { word = false }, { word = "ctx", now = 1 }) == "{{word}}",
	"false should disable a context field too"
)

local calls = 0
render("no placeholders here", {
	counted = function()
		calls = calls + 1
	end,
})
assert(calls == 0, "unused variables should not be evaluated")

-- setup() variables beat caller variables, and false removes a variable.
templater.setup({
	variables = {
		shared = function()
			return "user"
		end,
		date = false,
	},
})
assert(render("{{shared}}", {
	shared = function()
		return "caller"
	end,
}) == "user", "setup variables should override caller variables")
assert(render("{{date}}") == "{{date}}", "a variable set to false should be disabled")
templater.setup()

-- Lua code.
assert(render('{{lua:os.date("%Y", 0)}}') == os.date("%Y", 0), "lua should evaluate an expression")
assert(render('{{lua:os.date("%H:%M", 0)}}') == os.date("%H:%M", 0), "lua code may contain colons")
assert(render("{{lua:context.title .. '!'}}") == "My title!", "lua should see the context")
assert(render("{{lua:1 + 2}}") == "3", "lua may return numbers")
assert(render("{{lua:local n = 4; return n * 2}}") == "8", "lua may be a statement chunk")
assert(render("{{lua:nil}}") == "", "lua returning nil should insert nothing")
templater.setup({ variables = { lua = false } })
assert(render("{{lua:1 + 2}}") == "{{lua:1 + 2}}", "lua can be disabled")
templater.setup()

-- Failures keep the placeholder and warn instead of aborting.
local warnings = {}
local original_notify = vim.notify
vim.notify = function(message, level)
	table.insert(warnings, { message = message, level = level })
end

assert(render("{{lua:error('boom')}}") == "{{lua:error('boom')}}", "a failing lua placeholder should stay")
assert(#warnings == 1 and warnings[1].level == vim.log.levels.WARN, "a failure should produce one warning")
assert(warnings[1].message:find("boom"), "the warning should include the error")

assert(render("{{lua:1 +}}") == "{{lua:1 +}}", "a lua syntax error should keep the placeholder")
assert(#warnings == 2, "a syntax error should warn too")

assert(render("a {{bad}} b {{title}}", {
	bad = function()
		error("nope")
	end,
}) == "a {{bad}} b My title", "one failing variable should not stop the others")

vim.notify = original_notify

print("templater render: tests passed")
