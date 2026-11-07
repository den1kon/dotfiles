# Testing the Neovim configuration

This guide explains both how to run the current tests and how those tests are
structured. Commands use absolute paths so they work from any directory.

## Goals and guarantees

The tests verify observable Neovim behavior:

- Templates render, insert, and are found in the configured directories.
- Frontmatter `updated_at` is refreshed on save, except in template files.
- Links are followed, including flat wikilinks found in nearby directories.
- Daily and weekly notes are filled from their templates.
- A missing previous note leaves the link placeholder visible, never a broken link.
- Existing note content is never overwritten.
- Repeating a note command does not reload or save an unsaved buffer.
- User commands are registered by the normal setup path.

Tests operate on temporary directories and real Neovim buffers. They never open
or modify files in the personal knowledge base. Generated test files are removed
before each test process exits.

## Prerequisites

The commands expect:

- Neovim on `PATH` as `nvim`.
- StyLua on `PATH` as `stylua` for formatting verification.
- The configuration at `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`.

No Lua testing framework or additional Neovim plugin is required. Tests use
Lua's built-in `assert()` and Neovim's actual Lua API.

## Run one test

Use a single test while developing one module:

```sh
nvim_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim_test_log="${TMPDIR:-/tmp}/nvim-notes-test.log"

NVIM_LOG_FILE="$nvim_test_log" \
nvim --headless -u NONE -i NONE \
  --cmd "set runtimepath+=$nvim_config" \
  -l "$nvim_config/tests/templater/render_spec.lua"
```

Replace `render_spec.lua` with another file under `tests/<module>/` when needed.

## Run all tests

`set -e` is important: it stops the shell at the first failed test instead of
allowing a later successful test to hide the failure.

```sh
set -e
nvim_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim_test_log="${TMPDIR:-/tmp}/nvim-notes-test.log"

for test_file in "$nvim_config"/tests/*/*_spec.lua; do
  NVIM_LOG_FILE="$nvim_test_log" \
  nvim --headless -u NONE -i NONE \
    --cmd "set runtimepath+=$nvim_config" \
    -l "$test_file"
done
```

Each test gets a new Neovim process. Commands, mappings, buffers, and options
from one test therefore cannot leak into another.

## Check formatting

StyLua's check mode reports formatting differences without rewriting files:

```sh
nvim_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

stylua --check \
  "$nvim_config/lua/templater" \
  "$nvim_config/lua/frontmatter" \
  "$nvim_config/lua/markdown-navigation" \
  "$nvim_config/lua/digital_notes" \
  "$nvim_config/lua/visual_wrap" \
  "$nvim_config/tests/templater" \
  "$nvim_config/tests/frontmatter" \
  "$nvim_config/tests/markdown-navigation" \
  "$nvim_config/tests/digital_notes" \
  "$nvim_config/tests/visual_wrap" \
  "$nvim_config/lua/keybinds.lua"
```

To apply formatting intentionally, run the same command without `--check`.

## Run the full-config smoke test

The isolated tests prove individual behavior. This smoke test loads the normal
configuration and confirms that its public note commands and keymaps exist (the
list is in the command below):

```sh
nvim_test_log="${TMPDIR:-/tmp}/nvim-notes-test.log"

NVIM_LOG_FILE="$nvim_test_log" \
nvim --headless -i NONE \
  '+lua for _, command in ipairs({ "DailyNote", "WeeklyNote", "InsertTemplate", "PickTemplate", "FollowLink", "FollowLinkInNewTab", "FollowBack" }) do assert(vim.fn.exists(":" .. command) == 2, command .. " command missing") end' \
  '+lua for _, key in ipairs({ "<leader>dn", "<leader>wn", "<leader>if", "<leader>it", "<leader>pt", "<leader>fl", "<leader>ft", "<leader>gb" }) do assert(vim.fn.maparg(key, "n") ~= "", key .. " keymap missing") end' \
  '+lua for _, key in ipairs({ "<leader>b", "<leader>i", "<leader>c" }) do assert(vim.fn.maparg(key, "x") ~= "", key .. " visual keymap missing") end' \
  +qa
```

This command deliberately omits `-u NONE`, allowing Neovim to load the real
`init.lua`. It still uses `-i NONE` to avoid reading or writing ShaDa state.

## Run the complete verification

The following sequence is the complete check used after changes to the
modules it covers:

```sh
set -e
nvim_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim_test_log="${TMPDIR:-/tmp}/nvim-notes-test.log"

stylua --check \
  "$nvim_config/lua/templater" \
  "$nvim_config/lua/frontmatter" \
  "$nvim_config/lua/markdown-navigation" \
  "$nvim_config/lua/digital_notes" \
  "$nvim_config/lua/visual_wrap" \
  "$nvim_config/tests/templater" \
  "$nvim_config/tests/frontmatter" \
  "$nvim_config/tests/markdown-navigation" \
  "$nvim_config/tests/digital_notes" \
  "$nvim_config/tests/visual_wrap" \
  "$nvim_config/lua/keybinds.lua"

for test_file in "$nvim_config"/tests/*/*_spec.lua; do
  NVIM_LOG_FILE="$nvim_test_log" \
  nvim --headless -u NONE -i NONE \
    --cmd "set runtimepath+=$nvim_config" \
    -l "$test_file"
done

NVIM_LOG_FILE="$nvim_test_log" \
nvim --headless -i NONE \
  '+lua for _, command in ipairs({ "DailyNote", "WeeklyNote", "InsertTemplate", "PickTemplate", "FollowLink", "FollowLinkInNewTab", "FollowBack" }) do assert(vim.fn.exists(":" .. command) == 2, command .. " command missing") end' \
  '+lua for _, key in ipairs({ "<leader>dn", "<leader>wn", "<leader>if", "<leader>it", "<leader>pt", "<leader>fl", "<leader>ft", "<leader>gb" }) do assert(vim.fn.maparg(key, "n") ~= "", key .. " keymap missing") end' \
  '+lua for _, key in ipairs({ "<leader>b", "<leader>i", "<leader>c" }) do assert(vim.fn.maparg(key, "x") ~= "", key .. " visual keymap missing") end' \
  +qa
```

No output from StyLua or the smoke test means success. Each Lua test prints its
own success message. Any failed assertion or command stops the sequence with a
nonzero exit status.

## Neovim command-line flags

- `--headless` starts Neovim without displaying its user interface.
- `-u NONE` skips the normal `init.lua` and plugins, isolating the module under
  test.
- `-i NONE` disables the ShaDa file so tests do not read or write editor state.
- `--cmd` executes a command before other startup arguments. Here it adds the
  configuration to `runtimepath`, allowing `require("templater.…")` to find modules
  under `lua/templater/`.
- `-l FILE` executes `FILE` as Lua and exits after the script completes.
- `+qa` quits Neovim after the smoke-test assertions pass.

`NVIM_LOG_FILE` is set to an absolute temporary path so diagnostic messages do
not create a relative `nvim.log` in the directory from which tests are run.

## Abstract testing flow

Each test follows four phases:

1. **Arrange:** Load the real module and create controlled input, such as a
   temporary directory, fixed timestamp, or empty Neovim buffer.
2. **Act:** Call the production function or execute the registered user
   command.
3. **Assert:** Inspect returned values, buffer contents, modified state,
   commands, mappings, or filesystem state with literal expected values.
4. **Cleanup:** Abandon only test buffers with `enew!`, restore any changed
   working directory, and delete the temporary directory.

Tests use real Neovim APIs rather than mocks. For example, overwrite protection
is checked by opening a real buffer containing existing text, while persistence
is checked by confirming that an unsaved generated note does not exist on disk.

## Test-file responsibilities

Tests live in one directory per module under `tests/`.

- `templater/render_spec.lua` checks `{{name}}` rendering: predefined variables,
  arguments, caller and user variables and their precedence, lazy evaluation,
  context fields as variables, `{{lua:…}}` code, and keeping a placeholder when it
  is unmapped, fails, or its variable returns nil (while "" and false are values).
- `templater/directories_spec.lua` checks template lookup across several
  directories (first match wins), any file extension, paths, listing (including
  symlinks to files), and which paths count as template files.
- `templater/insert_spec.lua` runs `:InsertTemplate` for every position, the
  cursor afterwards, rendering with the buffer's details, error reporting,
  completion, and `:PickTemplate` (with a stubbed `vim.ui.select`): both prompts,
  a given position, names shown without extensions, cancelling, the original
  window, and no templates.
- `frontmatter/frontmatter_spec.lua` checks refreshing only `updated_at` inside the
  block, the skipped cases (other filetypes, no or unterminated frontmatter),
  `exclude`, `update_on_save`, and the real save hook through `:write`.
- `markdown-navigation/links_spec.lua` checks link finding, picking the link at a
  column, path resolution including every refusal, and the wikilink search order
  across a temporary directory tree with configurable depths.
- `markdown-navigation/navigation_spec.lua` follows links in real buffers: both
  link kinds, flat wikilinks found in nearby directories, a new tab, going back
  with Neovim's own buffers (toggling, skipping deleted and non-Markdown ones),
  and the warnings for failures.
- `visual_wrap/wrap_spec.lua` drives the Visual-mode toggles in disposable unnamed
  buffers. It covers all three markers, multiline and linewise selections,
  backward and exclusive selections, Unicode, block selections with short lines and
  partial tabs, register preservation, and single-step undo. Toggle cases check
  removal of markers both inside and immediately outside the selection,
  independent toggles on mixed block rows, and preservation of bold markers when
  toggling italic.
- `digital_notes/digital_notes_spec.lua` checks the wiring: every command exists,
  the configured directory supplies the frontmatter template, and saving a
  template keeps its `{{updated_at}}` placeholder while a normal note is refreshed.
- `digital_notes/previous_note_spec.lua` checks the previous-period lookup alone:
  the newest earlier file wins, and other note types, other extensions and
  directories are ignored.
- `digital_notes/notes_spec.lua` runs `:DailyNote` and `:WeeklyNote` in a temporary
  directory: naming, filling from the template, previous-note links, existing and
  unsaved notes left alone, today's and this week's defaults, and a missing
  template.

## Add a test

1. Put the test beside related coverage in `tests/<module>/`, or add a focused
   `*_spec.lua` file for a new module.
2. Load the production module with `pcall(require, "module.name")` and assert
   that it loaded. This gives a readable failure when the module is missing.
3. Derive expected values independently and write them as literals. Do not use
   the production builder to create both the actual and expected result.
4. Use `vim.fn.tempname()` and `vim.fn.mkdir()` for filesystem behavior.
5. Disable swap files in tests that open temporary buffers with
   `vim.o.swapfile = false`.
6. Assert the user-visible result rather than internal implementation details.
7. Restore changed process state and remove temporary data.
8. Run the focused test, then the complete verification sequence.

For a bug fix, first run the new test against the unfixed code and confirm that
it fails for the reported behavior. Apply the smallest fix, rerun the focused
test, and finally run the complete suite.

## Troubleshooting

### A module cannot be found

Confirm that the command includes:

```sh
nvim_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim --headless -u NONE -i NONE \
  --cmd "set runtimepath+=$nvim_config" \
  -l "$nvim_config/tests/templater/render_spec.lua"
```

Also confirm that the Lua module path matches its `require()` name. For example,
`require("templater.variables")` loads `lua/templater/variables.lua`.

### A test reports `E37: No write since last change`

The test attempted to leave a modified buffer. Assert the modified state first,
then use `vim.cmd("enew!")` only during cleanup of that disposable test buffer.
Production code must not use a forced command to bypass this protection.

### Swap-file or ShaDa errors appear

For tests that open buffers, set `vim.o.swapfile = false`. Keep `-i NONE` in the
Neovim command to disable ShaDa state.

### `nvim.log` appears in the current directory

The process inherited a relative `NVIM_LOG_FILE`. Set it to an absolute
temporary path as shown in this guide, or remove that environment override so
Neovim uses its standard state directory.

### A time-dependent assertion changes by timezone

Pass a fixed Unix timestamp as `now` in the context given to templater's
`render()`, `build()` or `insert()`. `{{utc}}` formats it in UTC, while `{{date}}`,
`{{time}}` and the default daily and weekly note names intentionally follow local
time.
