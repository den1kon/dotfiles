# frontmatter

YAML frontmatter helpers for Markdown buffers. It does two things and nothing
else: insert a frontmatter block, and refresh `updated_at` before a buffer is
saved. It does not know where notes or templates live; callers decide which
files to skip.

## Behavior

- `:InsertFrontmatter` inserts a block at the top of the buffer, or warns and
  does nothing when the first line is already `---`:

  ```yaml
  ---
  id: 1791112654
  created_at: "2026-10-04T11:17:34Z"
  updated_at: "2026-10-04T11:17:34Z"
  tags:
    - fleeting-note
  ---
  ```

- Before every save of a Markdown buffer, the `updated_at:` line inside the
  frontmatter becomes the current UTC time. Only that one line is replaced, so
  the cursor and marks do not move. Nothing changes when the buffer is not
  Markdown, has no closed frontmatter block, or the block has no `updated_at`.
  A line named `updated_at:` in the body is never touched.

## Options

```lua
require("frontmatter").setup({
	tag = "fleeting-note",          -- tag in the generated block
	generate = function()           -- replaces the generated block entirely
		return { "---", "tags: []", "---", "" }
	end,
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

frontmatter.setup(options)                -- command and save hook
frontmatter.build(tag, now)               -- default block as lines
frontmatter.insert(buffer)                -- boolean: inserted
frontmatter.refresh_updated_at(buffer, now) -- boolean: updated
```

`setup()` may be called again; the save hook is never registered twice. It
registers no keymaps.

Tests are in `tests/frontmatter/`; see [the testing guide](../../docs/testing.md).
