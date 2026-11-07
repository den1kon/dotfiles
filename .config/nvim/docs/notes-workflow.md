# Notes workflow

The note features are independent modules that do not know about each other:
[templater](../lua/templater/README.md),
[frontmatter](../lua/frontmatter/README.md) and
[markdown-navigation](../lua/markdown-navigation/README.md).
[`lua/digital_notes.lua`](../lua/digital_notes.lua) combines them for the
digital-notes vault and holds the little glue specific to it: daily and weekly
notes. There is no notes module; a daily or weekly note is just a file named
after the day or week, filled from a template.

`init.lua` calls `require("digital_notes").setup()`. That is the only entry
point; `lua/keybinds.lua` only binds keys to the commands it creates.

## Commands and keys

| Key           | Command                  | Opens                                   |
| ------------- | ------------------------ | --------------------------------------- |
| `<leader>dn`  | `:DailyNote [YYYY-MM-DD]`| Today's note, or the given day          |
| `<leader>wn`  | `:WeeklyNote [YYYY-Www]` | This ISO week's note, or the given week |
| `<leader>if`  | `:InsertTemplate frontmatter start` | Inserts frontmatter at the top |
| `<leader>pt`  | `:InsertTemplate`        | Asks which template and where to insert it |
| `<leader>fl`, `<leader>ft`, `<leader>gb` | `:FollowLink`, `:FollowLinkInNewTab`, `:FollowBack` | Link navigation |

Notes are opened in the current window and live in Neovim's working directory,
like any file you open there.

## Templates

`setup()` points templater at `~/gitLair/digital-notes/templates`
(`setup({ templates = "…" })` overrides it). That directory holds the templates:

- `daily.md` and `weekly.md` for the two note types,
- `frontmatter.md`, the block `<leader>if` inserts for a fleeting note.

Besides templater's [predefined variables](../lua/templater/README.md), the
workflow provides:

- `{{title}}`: the note's period, taken from its file name, such as `2026-10-04`
  or `2026-W40`.
- `{{last_daily_note}}` and `{{last_weekly_note}}`: a
  `- [[2026-W39.md|Last weekly note]]` line linking the newest earlier note of the
  same kind in the same directory. For the first note there is nothing to link, so
  the placeholder is left as written in the note, which shows it did not apply.

A minimal `weekly.md`:

```markdown
---
id: {{id}}
created_at: "{{utc}}"
updated_at: "{{utc}}"
tags:
  - weekly-note
---

# {{title}}

{{last_weekly_note}}

## TODOs
```

Template files keep their `{{updated_at}}` placeholders because frontmatter is
told to skip every file that `templater.is_template()` accepts.

## Opening flow

For `:DailyNote`:

1. The name is the given day or today's local date, `YYYY-MM-DD`; weekly notes
   use the ISO week date `%G-W%V`, which also handles January days that belong to
   the previous ISO year.
2. `<name>.md` in the working directory is opened in the current window. If that
   file is already the current buffer it is not edited again, so an unsaved
   generated note never causes `E37`.
3. If the buffer is anything but a single empty line, nothing else happens:
   existing notes are never changed.
4. Otherwise `templater.insert("daily", "start")` fills the buffer and the cursor
   goes to the last line. A missing template shows an error and leaves the
   buffer empty.

The buffer is never saved by this code; saving stays your action.

## Previous-note links

`{{last_daily_note}}` and `{{last_weekly_note}}` scan the note's directory for
files matching `YYYY-MM-DD.md` or `YYYY-Www.md`. Periods are zero-padded, so
string order is time order, and the greatest period below the current one wins.
Notes of the other kind and later periods are ignored.

## Adding another note type

For a monthly note: add `monthly.md` to the templates directory, add a command
in `register_commands()` that calls `open_note(name, "monthly")`, and, if it
should link its predecessor, add a `previous_note_link()` variable to the
`variables` in `setup()`. Bind a key in `lua/keybinds.lua`. If this glue grows,
move it into a module of its own.

## Tests

`tests/digital_notes/` covers the wiring and the two commands in temporary
directories, with temporary templates. See [the testing guide](testing.md).
