-- Combines the independent note modules into the digital-notes workflow. Each
-- module stays unaware of the others; the wiring lives here.
local templater = require("templater")

-- Custom templates win over the ones bundled with lua/notes/templates.
templater.setup({
	directories = { "~/gitLair/digital-notes/templates" },
})

require("frontmatter").setup({
	-- Template files hold placeholders such as {{updated_at}}, not timestamps.
	exclude = templater.is_template,
})

require("markdown-navigation").setup()

require("notes").setup()
