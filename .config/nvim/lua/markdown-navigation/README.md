# markdown-navigation

Follow Markdown links and wikilinks under the cursor, and go back. That is all
it does; it registers three commands and no keymaps, so callers bind keys.

## Commands

| Command               | Action                                                    |
| --------------------- | --------------------------------------------------------- |
| `:FollowLink`         | Open the link under the cursor in the current window      |
| `:FollowLinkInNewTab` | Open the link under the cursor in a new tab               |
| `:FollowBack`         | Return to the Markdown buffer visited before this one     |

The same actions are available as `require("markdown-navigation").follow_link(options)`
(with `{ tab = true }` for a new tab) and `.follow_back()`; each returns whether
it moved. Failures show a warning and leave the buffer unchanged.

## Links

- **Markdown links**, `[text](path/to/file.md)`, are relative to the directory of
  the file that contains them, or absolute. They are never searched for.
- **Wikilinks**, `[[target]]` and `[[target|alias]]`, are flat: a target without
  an extension gets `.md`, and it is looked for in nearby directories, see
  below.

`..` in a relative path is collapsed. A link is refused when its target is empty,
has no filename, contains one of `<>:"|?*`, or ends with a space or a dot.

### Where a wikilink is looked for

For `[[reference]]` in `folder_a/folder_b/file.md`, the first existing file wins
in this order:

1. `folder_a/folder_b/` (the file's own directory)
2. its subdirectories, `down` levels deep, nearest level first and in name order
   within a level (hidden directories are skipped)
3. its parent directories, `up` levels, nearest first

With the defaults (`down = 1`, `up = 1`) that is `folder_b/`, then
`folder_b/*/`, then `folder_a/`. Sibling directories such as `folder_a/folder_c/`
are not searched. A target with a path, `[[child/note]]`, is tried the same way
under each of those directories, and an absolute target is used as written.

If nothing is found, following the link opens `reference.md` in the file's own
directory. The file is not created until you save it, which makes a link a quick
way to start a new note.

```lua
require("markdown-navigation").setup({
	wikilink_search = { down = 2, up = 1 }, -- default { down = 1, up = 1 }
})
```

Levels are non-negative integers; `0` turns that direction off.

## History

`:FollowBack` uses a stack kept per window. Entering a Markdown buffer in a
window pushes it; going back drops the current buffer and returns the latest
earlier one that is still listed, so deleted buffers are skipped.

## Files

- `init.lua`: `setup()`, the commands, and the two actions.
- `links.lua`: pure functions that find links in a line, pick the one at a
  column, and resolve a link to a path.
- `history.lua`: the per-window buffer stack.

Tests are in `tests/markdown-navigation/`; see
[the testing guide](../../docs/testing.md).
