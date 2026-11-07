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

## Template files

`build(name, context, variables)` reads `<directory>/<name>.md`, renders it, and
returns its lines. Directories are searched in this order:

1. The `directories` given to `setup()`, in order. `~` is expanded and a
   relative path resolves against the working directory.
2. Directories that modules register with `add_directory()` as defaults. A
   module uses this to ship its own bundled templates; a user template of the
   same name always wins.

`find(name)` returns the path or raises an error naming the missing file.

`is_template(path)` reports whether a path is inside any of those directories.
Other tools use it to leave template files alone, for example to skip refreshing
`updated_at` in a template.

## API

```lua
local templater = require("templater")

templater.setup({ directories = "~/notes/templates", variables = {} })
templater.add_directory(path)                     -- default directory
templater.render(text, context, variables)        -- string -> string
templater.build(name, context, variables)         -- template name -> lines
templater.find(name)                              -- template name -> path
templater.is_template(path)                       -- boolean
```

`context` is a table that variables can read; `now` defaults to `os.time()`.

## Files

- `init.lua` holds the options, lookup, and rendering.
- `variables.lua` defines the predefined variables.

Tests are in `tests/templater/`; see [the testing guide](../../docs/testing.md).
