vim.g.mapleader = " "
vim.o.swapfile = false
vim.o.report = 9999

local ok, wrap = pcall(require, "visual_wrap")
assert(ok, "visual_wrap should load")

-- The module only provides wrap(); bind the keys the way the configuration does.
for key, marker in pairs({ b = "**", i = "*", c = "`" }) do
	vim.keymap.set("x", "<leader>" .. key, function()
		wrap.wrap(marker)
	end)
end

local function keys(value)
	vim.api.nvim_feedkeys(vim.keycode(value), "xt", false)
end

local function check(name, lines, selection, mapping, expected, options)
	vim.cmd("enew!")
	vim.o.selection = (options or {}).selection or "inclusive"
	vim.o.virtualedit = (options or {}).virtualedit or ""
	vim.bo.tabstop = 4
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.fn.setreg('"', "keep this")
	vim.fn.setreg("0", "keep yank")
	local unnamed, yank = vim.fn.getreg('"'), vim.fn.getreg("0")
	keys(selection)
	keys(mapping)
	local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	assert(vim.deep_equal(actual, expected), name .. ": unexpected text " .. vim.inspect(actual))
	assert(vim.fn.mode() == "n", name .. ": should return to normal mode")
	assert(vim.fn.getreg('"') == unnamed, name .. ": changed unnamed register")
	assert(vim.fn.getreg("0") == yank, name .. ": changed yank register")
	keys("u")
	assert(
		vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), lines),
		name .. ": undo should restore selection"
	)
end

check("bold", { "hello world" }, "gg0ve", " b", { "**hello** world" })
check("italic backwards", { "hello world" }, "gg04lv0", " i", { "*hello* world" })
check("code Unicode", { "aé🙂z" }, "gg0lvl", " c", { "a`é🙂`z" })
check("multiline", { "one two", "three four" }, "gg0wvj2l", " b", { "one **two", "three f**our" })
check("linewise", { "one", "two" }, "ggVj", " i", { "*one", "two*" })
check("block", { "abc def", "ghi jkl" }, "gg0l<C-v>j2l", " b", { "a**bc **def", "g**hi **jkl" })
check("block backwards", { "abc", "def" }, "gg0j2l<C-v>k0", " c", { "`abc`", "`def`" })
check("exclusive", { "hello!" }, "gg0v5l", " i", { "*hello*!" }, { selection = "exclusive" })
check("block short line", { "abcdef", "a", "abcdef" }, "gg02l<C-v>2j2l", " c", { "ab`cde`f", "a `   `", "ab`cde`f" })
check("block partial tab", { "abcd", "\tx" }, "gg0l<C-v>j", " i", { "a*b*cd", " * *  x" }, { virtualedit = "block" })

check("remove bold including markers", { "**hello** world" }, "gg0v8l", " b", { "hello world" })
check("remove bold inside markers", { "**hello** world" }, "gg02lve", " b", { "hello world" })
check("remove italic including markers", { "*hello*" }, "gg0v$", " i", { "hello" })
check("remove italic inside markers backwards", { "*hello*" }, "gg05lv4h", " i", { "hello" })
check("remove code including markers", { "`hello`" }, "gg0v$", " c", { "hello" })
check("remove code inside markers Unicode", { "`é🙂`" }, "gg0lvl", " c", { "é🙂" })
check("remove multiline bold", { "**one", "two**" }, "gg0vj$", " b", { "one", "two" })
check("remove multiline code inside", { "`one", "two`" }, "gg0lvjl", " c", { "one", "two" })
check("remove linewise italic", { "*one", "two*" }, "ggVj", " i", { "one", "two" })
check("remove block code including markers", { "`abc`", "`def`" }, "gg0<C-v>j4l", " c", { "abc", "def" })
check("remove block bold inside markers", { "**abc**", "**def**" }, "gg02l<C-v>j2l", " b", { "abc", "def" })
check("mixed block toggles each row", { "*abc*", "defgh" }, "gg0<C-v>j4l", " i", { "abc", "*defgh*" })
check("italic preserves bold markers", { "**hello**" }, "gg0v$", " i", { "***hello***" })
check("italic inside bold preserves bold markers", { "**hello**" }, "gg02lve", " i", { "***hello***" })
check("remove italic from combined formatting", { "***hello***" }, "gg0v$", " i", { "**hello**" })
check("remove bold from combined formatting", { "***hello***" }, "gg03lve", " b", { "*hello*" })
check("code preserves longer backtick delimiter", { "``hello``" }, "gg02lve", " c", { "```hello```" })
check("remove exclusive bold", { "**hello**!" }, "gg02lv5l", " b", { "hello!" }, { selection = "exclusive" })

vim.cmd("enew!")
print("visual_wrap: tests passed")
