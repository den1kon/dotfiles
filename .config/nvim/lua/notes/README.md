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
- `daily.lua` determines the daily filename, finds the previous daily note,
  and assembles the daily-specific body.
- `weekly.lua` determines the ISO week filename, finds the previous weekly
  note, and assembles the weekly-specific body.
- `frontmatter.lua` builds the shared YAML frontmatter. A note type supplies
  only its tag; IDs and UTC timestamps are generated consistently.
- `note.lua` owns behavior shared by every note type: locating a previous note,
  opening the target buffer safely, and populating only an empty buffer.

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
   matching daily note and calls `daily.build_template()`.
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
returns `nil`, and the template omits the “Last daily note” or “Last weekly
note” line.

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
2. Its body template and frontmatter tag.
3. An `open()` function that delegates buffer handling to `note.open()`.

Register its command and keymap in `init.lua`. Reuse `frontmatter.build()` and
`note.find_previous()` rather than copying them. Add tests for its template,
its first-note case, and its registered entry points.
