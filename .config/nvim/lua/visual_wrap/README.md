# visual_wrap

Toggles Markdown emphasis markers around the Visual selection. It provides one
function and registers no keys, so the configuration decides how to call it.

```lua
require("visual_wrap").wrap("**") -- bold
require("visual_wrap").wrap("*")  -- italic
require("visual_wrap").wrap("`")  -- inline code
```

`lua/keybinds.lua` binds these in Visual mode (`v`, `V`, `Ctrl-v`), with Space as
the leader:

- `<leader>b`: bold (`**text**`).
- `<leader>i`: italic (`*text*`).
- `<leader>c`: inline code (backticks).

## Behavior

Matching markers are removed when they are inside the selection or immediately
around it; otherwise they are added. For example, `<leader>b` removes bold from a
selection of `**text**` and from just `text` inside those markers. Italic
toggling preserves bold markers, and code toggling recognizes single backticks.

Characterwise and linewise selections toggle once; block selections toggle
independently on each row, preserving the rectangle with spaces on short lines
and splitting partial tabs into spaces when needed. The function returns to
Normal mode, preserves registers, and can be undone with one `u`. It does not
save the buffer, and it does nothing outside Visual mode.

Tests are in `tests/visual_wrap/`; see [the testing guide](../../docs/testing.md).
