# digital_notes

The entry point of the notes setup: it configures the independent modules
([templater](../templater/README.md), [frontmatter](../frontmatter/README.md),
[markdown-navigation](../markdown-navigation/README.md)) and connects them for
the digital-notes vault. It is not a module of its own; the modules never require
it or each other. `init.lua` at the configuration root calls
`require("digital_notes").setup()`.

The behavior, commands, templates and variables are described in
[the notes workflow](../../docs/notes-workflow.md).

## Files

- `init.lua`: `setup()`. Points templater at the templates directory and adds the
  previous-note variables, tells frontmatter to skip template files, starts
  link navigation, configures Markdown text width for vault files, and registers
  the note commands. Read it top to bottom to see what is connected to what.
- `markdown.lua`: gives Markdown files under `~/gitLair/digital-notes` a local
  `textwidth` of 100, matching the vault's rumdl formatter configuration.
- `periodic_notes.lua`: the note types (daily, weekly) as data, the function that
  opens a note and fills it from its template, and the `:DailyNote` and
  `:WeeklyNote` commands and `{{last_*_note}}` variables built from the types.
- `previous_note.lua`: finds the newest note before a given period from file
  names alone.
- `tags.lua`: lists top-level Markdown notes by tags in YAML frontmatter and
  opens the selected note through MiniPick.

Tests are in `tests/digital_notes/`; see [the testing guide](../../docs/testing.md).
