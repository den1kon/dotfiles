# Testing the Neovim configuration

This guide explains both how to run the current tests and how those tests are
structured. Commands use absolute paths so they work from any directory.

## Goals and guarantees

The note tests verify observable Neovim behavior:

- Generated daily and weekly templates have the expected content.
- A missing previous note produces no broken navigation link.
- Existing note content is never overwritten.
- Repeating a note command does not reload or save an unsaved buffer.
- User commands and keymaps are registered by the normal setup path.

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
  -l "$nvim_config/tests/notes/note_spec.lua"
```

Replace `note_spec.lua` with another file under `tests/notes/` when needed.

## Run all note tests

`set -e` is important: it stops the shell at the first failed test instead of
allowing a later successful test to hide the failure.

```sh
set -e
nvim_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim_test_log="${TMPDIR:-/tmp}/nvim-notes-test.log"

for test_file in "$nvim_config"/tests/notes/*_spec.lua; do
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
  "$nvim_config/lua/notes" \
  "$nvim_config/tests/notes" \
  "$nvim_config/lua/keybinds.lua"
```

To apply formatting intentionally, run the same command without `--check`.

## Run the full-config smoke test

The isolated tests prove individual behavior. This smoke test loads the normal
configuration and confirms that its public note commands and keymaps exist:

```sh
nvim_test_log="${TMPDIR:-/tmp}/nvim-notes-test.log"

NVIM_LOG_FILE="$nvim_test_log" \
nvim --headless -i NONE \
  '+lua assert(vim.fn.exists(":DailyNote") == 2, "DailyNote command missing")' \
  '+lua assert(vim.fn.exists(":WeeklyNote") == 2, "WeeklyNote command missing")' \
  '+lua assert(vim.fn.maparg("<leader>dn", "n") ~= "", "daily-note keymap missing")' \
  '+lua assert(vim.fn.maparg("<leader>wn", "n") ~= "", "weekly-note keymap missing")' \
  +qa
```

This command deliberately omits `-u NONE`, allowing Neovim to load the real
`init.lua`. It still uses `-i NONE` to avoid reading or writing ShaDa state.

## Run the complete verification

The following sequence is the complete check used after changes to note
automation:

```sh
set -e
nvim_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim_test_log="${TMPDIR:-/tmp}/nvim-notes-test.log"

stylua --check \
  "$nvim_config/lua/notes" \
  "$nvim_config/tests/notes" \
  "$nvim_config/lua/keybinds.lua"

for test_file in "$nvim_config"/tests/notes/*_spec.lua; do
  NVIM_LOG_FILE="$nvim_test_log" \
  nvim --headless -u NONE -i NONE \
    --cmd "set runtimepath+=$nvim_config" \
    -l "$test_file"
done

NVIM_LOG_FILE="$nvim_test_log" \
nvim --headless -i NONE \
  '+lua assert(vim.fn.exists(":DailyNote") == 2, "DailyNote command missing")' \
  '+lua assert(vim.fn.exists(":WeeklyNote") == 2, "WeeklyNote command missing")' \
  '+lua assert(vim.fn.maparg("<leader>dn", "n") ~= "", "daily-note keymap missing")' \
  '+lua assert(vim.fn.maparg("<leader>wn", "n") ~= "", "weekly-note keymap missing")' \
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
  configuration to `runtimepath`, allowing `require("notes.…")` to find modules
  under `lua/notes/`.
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

- `frontmatter_spec.lua` checks reusable YAML metadata and UTC timestamps.
- `note_spec.lua` checks previous-note lookup, buffer reuse, unsaved state, and
  overwrite protection.
- `daily_spec.lua` checks daily template content with and without a previous
  daily note.
- `weekly_spec.lua` checks ISO week calculation and weekly template content
  with and without a previous weekly note.
- `init_spec.lua` checks command and keymap registration, then executes both
  public commands in a temporary working directory.

## Add a test

1. Put the test beside related coverage in `tests/notes/`, or add a focused
   `*_spec.lua` file for a new module.
2. Load the production module with `pcall(require, "notes.module")` and assert
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
  -l "$nvim_config/tests/notes/note_spec.lua"
```

Also confirm that the Lua module path matches its `require()` name. For example,
`require("notes.note")` loads `lua/notes/note.lua`.

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

Pass a fixed Unix timestamp through the module's `now` option. Templates format
stored timestamps in UTC, while daily dates and ISO weeks intentionally follow
local time.
