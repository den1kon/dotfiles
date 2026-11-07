# templater

Renders plain-text templates containing `{{name}}` placeholders. It knows
nothing about notes, Markdown, or any other module: callers supply a context and
their own variables, and users add more through `setup()`.

## Syntax

- `{{name}}` is replaced by the result of the variable function `name`.
- `{{name:argument}}` passes the text after the first colon to the function.
- `{{lua:code}}` evaluates Lua; see [Lua code](#lua-code).
- Whitespace around the name is ignored: `{{ title }}`.
- A function that returns `nil` inserts nothing; its line stays in place.
- A name with no variable, or text that is not a valid placeholder such as
  `{{some words}}`, is left exactly as written so typos stay visible.
- A value may contain newlines to insert several lines.
- A placeholder ends at the first `}}`, so code inside it cannot contain `}}`.

## Predefined variables

| Variable          | Value                                                       |
| ----------------- | ----------------------------------------------------------- |
| `{{title}}`       | `context.title`, whatever the caller passed                 |
| `{{id}}`          | Unix timestamp                                              |
| `{{date}}`        | Local date, `2026-10-04`; `{{date:%A}}` takes an os.date format |
| `{{time}}`        | Local time, `11:17`; `{{time:%H:%M:%S}}` takes a format     |
| `{{utc}}`         | ISO 8601 UTC, `2026-10-04T11:17:34Z`; `{{utc:%H}}` takes a format |
| `{{lua:…}}`       | Result of the Lua code                                      |

Every date and time uses `context.now`, which defaults to the current time, so
one render is internally consistent.

Text and number fields of the context are variables too. `:InsertTemplate`
supplies `{{title}}` (the buffer's file name without extension), `{{filename}}`,
`{{directory}}` and `{{path}}`. A predefined or caller variable of the same name
wins over a context field.

## Lua code

`{{lua:os.date("%y/%m/%d %H/%M")}}` evaluates the code as an expression. If the
code is not an expression it is run as a chunk, so
`{{lua:local n = 2; return n * 3}}` also works. The code sees `context` and the
usual globals, including `vim`.

If the code fails, the placeholder stays in the output and a warning is shown;
the rest of the template still renders. Templates run with full access, so only
use templates you trust. Disable the feature with
`setup({ variables = { lua = false } })`.

## Variables of your own

A variable is a function `fun(context, argument?): string|number|nil`. Callers
pass theirs as the third argument of `render()`/`build()`; users add theirs in
`setup()`:

```lua
require("templater").setup({
	variables = {
		weekday = function(context)
			return os.date("%A", context.now)
		end,
		-- A value of false removes a variable, even a predefined one.
		lua = false,
	},
})
```

When names collide, `setup()` variables win over the caller's, which win over
the predefined ones. Raising an error inside a variable keeps its placeholder
and shows a warning.

## Inserting a template

```vim
:InsertTemplate [{template} [{position}]]
```

`{template}` is any file; its extension does not matter, only its content.
Give a path (`~/notes/templates/frontmatter.md`, `./x`) or a name that is looked
up in the template directories, as `<name>` first and then `<name>.md`. Both
arguments complete with `<Tab>`.

| Position       | Where the text goes                                  | Cursor after          |
| -------------- | ---------------------------------------------------- | --------------------- |
| `cursor`       | Inline, before the character under the cursor (default) | First inserted character |
| `after-cursor` | Inline, after the character under the cursor         | First inserted character |
| `above`        | New lines above the current line                     | First inserted line   |
| `below`        | New lines below the current line                     | First inserted line   |
| `start`        | Beginning of the buffer                              | Stays on its text     |
| `end`          | End of the buffer                                    | Stays on its text     |
| `replace`      | In place of the whole buffer                         | First line            |

In a new buffer with a single empty line, `start` and `end` replace that line
instead of keeping it. `replace` discards the buffer's current text; like every
position it is one undo step, so `u` brings the text back. A bad template name or position shows an error and leaves
the buffer unchanged.

### Choosing from a list

`:InsertTemplate` with no arguments asks for the template and then the position
with `vim.ui.select()`, so whichever picker you have installed (mini.pick,
snacks, the built-in menu) shows them. Templates are listed without their
extension (`daily`, not `daily.md`); two files that differ only by extension keep
it. Only the display changes, never the files. The positions are listed with a
short explanation. Cancelling either prompt inserts nothing, and the text goes to the
window the command was started in even if the picker moved focus. With no
templates in any directory it shows a warning instead.

templater only calls the standard `vim.ui.select()`, so it needs no picker
plugin. To add a preview or another picker, build one in your configuration from
`list()`, `find()` and `insert()`.

### Example bindings

```lua
vim.keymap.set("n", "<leader>if", "<cmd>InsertTemplate frontmatter start<CR>", { desc = "Insert frontmatter" })
vim.keymap.set("n", "<leader>pt", "<cmd>InsertTemplate<CR>", { desc = "Pick template" })
```

## Template files

`build(name, context, variables)` reads a template, renders it, and returns its
lines. The `directories` given to `setup()` are searched in order and the first
match wins, so list the directory whose templates should take precedence first.
`~` is expanded and a relative path resolves against the working directory.
templater ships no templates of its own.

`find(name)` returns the path or raises an error naming the missing template.
`list()` returns the file names found in all directories, which is what
completion offers.

`is_template(path)` reports whether a path is inside any of those directories.
Other tools use it to leave template files alone, for example to skip refreshing
`updated_at` in a template.

## API

```lua
local templater = require("templater")

templater.setup({ directories = "~/notes/templates", variables = {} }) -- also registers :InsertTemplate
templater.render(text, context, variables)        -- string -> string
templater.build(name, context, variables)         -- template -> lines
templater.insert(name, position)                  -- render and insert into the current buffer
-- :InsertTemplate with no arguments asks for both with vim.ui.select()
templater.find(name)                              -- template -> path
templater.list()                                  -- template file names
templater.is_template(path)                       -- boolean
```

`context` is a table that variables can read; `now` defaults to `os.time()`.

## Files

- `init.lua` holds the options, lookup, and rendering.
- `variables.lua` defines the predefined variables.
- `insert.lua` puts lines into the buffer at a position.
- `command.lua` defines `:InsertTemplate`, its completion, and the chooser.

Tests are in `tests/templater/`; see [the testing guide](../../docs/testing.md).
