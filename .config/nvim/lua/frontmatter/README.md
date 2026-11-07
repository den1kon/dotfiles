# frontmatter

Keeps `updated_at` in a Markdown note's YAML frontmatter fresh. That is all it
does: before a buffer is saved, the `updated_at:` line inside its frontmatter
becomes the current UTC time.

Creating frontmatter is not its job. Insert a block from a template instead,
for example with `:InsertTemplate frontmatter start`
(see [templater](../templater/README.md)).

## Behavior

- The refresh runs before every save of a Markdown buffer. Only that one line is
  replaced, so the cursor and marks do not move.
- Nothing changes when the buffer is not Markdown, has no closed frontmatter
  block, or the block has no `updated_at`. A line named `updated_at:` in the body
  is never touched.

## Options

```lua
require("frontmatter").setup({
	update_on_save = true,          -- false turns the save hook off
	exclude = function(path)        -- true leaves that file's updated_at alone
		return vim.startswith(path, vim.fn.expand("~/notes/templates/"))
	end,
})
```

`exclude` receives the buffer's absolute path. It is how another module keeps
this one away from files that hold placeholders, for example
`exclude = require("templater").is_template`.

## API

```lua
local frontmatter = require("frontmatter")

frontmatter.setup(options)                  -- registers the save hook
frontmatter.refresh_updated_at(buffer, now) -- boolean: updated
```

`setup()` may be called again; the save hook is never registered twice. It
registers no commands and no keymaps.

Tests are in `tests/frontmatter/`; see [the testing guide](../../docs/testing.md).
