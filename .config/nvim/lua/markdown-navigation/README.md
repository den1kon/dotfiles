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

- Markdown links: `[text](path/to/file.md)`.
- Wikilinks: `[[target]]` and `[[target|alias]]`. A target without an extension
  gets `.md`.

A relative target is resolved against the directory of the file that contains
the link, with `..` collapsed; an absolute target is used as is. A link is
refused when its target is empty, has no filename, contains one of
`<>:"|?*`, or ends with a space or a dot.

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
