-- The entry point of the notes setup. The modules do not know about each other;
-- this is where they are configured and connected for the digital-notes vault.
local periodic_notes = require("digital_notes.periodic_notes")
local templater = require("templater")

local M = {}

---@class DigitalNotesOptions
---@field templates? string Directory with daily.md, weekly.md and frontmatter.md

---@param options? DigitalNotesOptions
function M.setup(options)
	options = options or {}

	templater.setup({
		directories = { options.templates or "~/gitLair/digital-notes/templates" },
		variables = periodic_notes.variables(),
	})

	require("frontmatter").setup({
		-- Template files hold placeholders such as {{updated_at}}, not timestamps.
		exclude = templater.is_template,
	})

	require("markdown-navigation").setup()
	require("digital_notes.markdown").setup()

	periodic_notes.register_commands()
end

return M
