# Periodic note automation

This directory contains the Neovim-side workflow for opening daily and weekly
notes. It generates an initial Markdown template in a buffer, but it never
writes that buffer to disk. Saving remains an explicit user action.

## User interface

- `<leader>dn` opens today's daily note.
- `:DailyNote` does the same; `:DailyNote 2026-10-04` opens a specific date.
- `<leader>wn` opens the current ISO week's note.
- `:WeeklyNote` does the same; `:WeeklyNote 2026-W40` opens a specific week.

All paths are relative to Neovim's current working directory. Commands reuse
the current window rather than creating a split or tab.

## Modules

- `init.lua` registers user commands and keymaps. It contains no template or
  buffer logic.
- `daily.lua` determines the daily filename and provides the
  `{{last_daily_note}}` variable for `templates/daily.md`.
- `weekly.lua` determines the ISO week filename and provides the
  `{{last_weekly_note}}` variable for `templates/weekly.md`.
- `templates/` holds the bundled templates: the daily and weekly note bodies, and
  `frontmatter.md`, the block for a fleeting note. `setup()` registers the
  directory with templater, so `:InsertTemplate frontmatter start` finds it.
- `note.lua` owns behavior shared by every note type: locating a previous note,
  opening the target buffer safely, populating only an empty buffer, and
  rendering a template through [templater](../templater/README.md).

This separation keeps note-type modules easy to review while avoiding copies
of the metadata and buffer-safety logic.

## Opening flow

For a daily note, the flow is:

1. `init.lua` calls `daily.open()` from either `:DailyNote` or `<leader>dn`.
2. `daily.lua` chooses an explicit date or today's local date and produces the
   `YYYY-MM-DD.md` filename.
3. `note.open()` opens that filename in the current window. If it is already
   the current buffer, it does not issue another `:edit`; this preserves an
   unsaved generated template without triggering `E37`.
4. If the buffer contains anything, processing stops. Existing notes are never
   changed or given another template.
5. For an empty buffer, the lazy template callback finds the newest earlier
   matching daily note through the `last_daily_note` variable while
   `daily.build_template()` renders `templates/daily.md`.
6. The template is inserted and the cursor is placed on its final blank line.
   The buffer is modified but remains unsaved.

Weekly notes follow the same flow through `weekly.lua`, using ISO week names
such as `2026-W40.md`.

## Previous-note lookup

`note.find_previous()` scans only the current working directory. Each note type
passes a filename pattern that captures its sortable period:

- Daily: `YYYY-MM-DD`
- Weekly: `YYYY-Www`

Both formats sort chronologically as strings. The function selects the greatest
matching value that is still less than the requested period. Other Markdown
files and later notes are ignored. If no earlier matching note exists, it
returns `nil`; the `last_daily_note`/`last_weekly_note` variable then inserts
nothing, so that line of the template stays empty. When a note exists, the
variable inserts `- [[YYYY-MM-DD.md|Last daily note]]` (or the weekly
equivalent).

## Templates

Note bodies are rendered by the [templater](../templater/README.md) module; see
its README for the `{{name}}` syntax, `{{lua:…}}` code, and predefined
variables. Besides those, templates can use:

- `{{title}}`: the note's period, such as `2026-10-04` or `2026-W40`.
- `{{created_at}}` and `{{updated_at}}`: UTC ISO 8601 time of creation.
- `{{last_daily_note}}` and `{{last_weekly_note}}`: a
  `- [[2026-W39.md|Last weekly note]]` line, or nothing for the first note.

The bundled `templates/daily.md` and `templates/weekly.md` are registered with
`templater.add_directory()` as defaults. To use your own, point templater at a
directory; a `daily.md` or `weekly.md` there replaces the bundled one:

```lua
require("templater").setup({
	directories = "~/notes/templates",
	variables = {
		-- Added to every template, including these notes.
		weekday = function(context)
			return os.date("%A", context.now)
		end,
	},
})
```

`setup()` in this module takes no options; everything configurable about
templates belongs to templater.

## Saving templates

Template files contain placeholders such as `updated_at: "{{updated_at}}"`. This
module does not refresh `updated_at` on save; the
[frontmatter](../frontmatter/README.md) module does, and
[`digital_notes.lua`](../digital_notes.lua) tells it to skip every file that
`templater.is_template()` accepts, so saving a template keeps its placeholder.

## Buffer and persistence guarantees

- Templates are inserted only into a buffer whose sole line is empty.
- Existing note content is never replaced.
- Repeating `dn` or `wn` for the current unsaved note is a no-op.
- Moving away from an unrelated modified buffer is allowed to produce Neovim's
  normal protection error; the workflow does not force, save, or discard it.
- No function in this directory calls `:write` or writes generated note content
  through a filesystem API.

Path comparison resolves the real parent directory and then appends the target
filename. Resolving only the parent matters because a new note does not yet
exist, so resolving the complete target path would fail.

## Tests

Tests are plain Lua scripts under `tests/notes/`. They use temporary directories
and real Neovim buffers without touching the personal knowledge base. See the
authoritative [testing guide](../../docs/testing.md) for the test model, exact
commands, extension instructions, and troubleshooting.

## Adding another note type

Add a focused module beside `daily.lua` and `weekly.lua` that defines:

1. Its sortable filename and matching pattern.
2. Its template file in `templates/`, including frontmatter and tag.
3. Any note-type variables, such as a link to its previous note.
4. An `open()` function that delegates buffer handling to `note.open()` and
   builds its lines with `note.build()`.

Register its command and keymap in `init.lua`. Reuse `note.find_previous()`
rather than copying it. Add tests for its rendered template, its first-note
case, and its registered entry points.
