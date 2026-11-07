# Neovim configuration

This is a personal Neovim configuration used on macOS and Linux. This README
describes its current organization and startup flow; it does not require the
layout to remain unchanged as the configuration evolves.

## Design philosophy

Everything tries to follow the Unix philosophy: one module does one thing and
does it well. Modules do not know about each other; `init.lua` and
[`lua/digital_notes.lua`](lua/digital_notes.lua) combine them. The rules are in
[`AGENTS.md`](AGENTS.md).

## Startup flow

[`init.lua`](init.lua) is the main entry point. At startup it currently:

1. Loads global editor options from `lua/settings.lua`.
2. Registers packages with `vim.pack.add()`.
3. Loads Treesitter and formatting configuration.
4. Applies the colorscheme and custom marks.
5. Configures and enables language servers.
6. Sets up the extended MiniFiles behavior and keymaps.
7. Sets up the note modules through `lua/digital_notes.lua`.
8. Registers the user commands and keymaps in `lua/keybinds.lua`.
9. Applies Markdown-specific highlighting.

Files under `plugin/` are runtime plugin configuration loaded by Neovim. The
`ftplugin/` directory contains settings that apply only to matching filetypes.

## Current structure

```text
~/.config/nvim/
├── init.lua                 Main entry point and package declarations
├── nvim-pack-lock.json      Package revisions managed by vim.pack
├── lua/
│   ├── settings.lua         Global editor options
│   ├── keybinds.lua         User commands and mappings
│   ├── fmt.lua              Conform formatter setup
│   ├── lsp/                 Language-server modules
│   ├── digital_notes.lua    Wires the note modules; daily and weekly notes
│   ├── templater/           {{}} templates, Lua support, :InsertTemplate
│   ├── frontmatter/         Refresh updated_at on save
│   ├── markdown-navigation/ Follow links, go back
│   └── ...                  Focused editor-feature modules
├── plugin/                  Runtime setup for installed plugins
├── ftplugin/                Filetype-local configuration
├── tests/                   Headless tests, one directory per module
└── docs/                    Longer operational documentation
```

The modules under `lua/` are loaded with `require()`. Related behavior may be
grouped into a directory, as with `lua/lsp/` and `lua/templater/`, while smaller
features remain single modules.

## Packages and plugin setup

Packages are declared in [`init.lua`](init.lua) with Neovim's `vim.pack` API.
Most plugin-specific setup currently lives under `plugin/`:

- `plugin/mininvim.lua` configures the selected `mini.nvim` modules.
- `plugin/rendermarkdown.lua` configures rendered Markdown display.

The lock file records resolved package revisions. Treesitter is deliberately
pinned to a specific revision in `init.lua`; other package declarations follow
the branches shown there.

## Language servers and formatting

`lua/lsp/init.lua` coordinates the individual server modules under `lua/lsp/`.
Each server keeps its own settings in a focused file, and the coordinator
enables the configured servers together.

`lua/fmt.lua` configures Conform formatters by filetype and exposes the buffer
formatting function used by the keymap layer.

## Commands and keymaps

`lua/keybinds.lua` contains general commands and mappings. Larger workflows are
delegated to focused modules rather than implemented entirely in a mapping.
For example, daily and weekly note mappings run commands that
`lua/digital_notes.lua` creates.

## Notes workflow

The note features are small independent modules that do not know about each
other; [`lua/digital_notes.lua`](lua/digital_notes.lua) combines them.

- [`templater`](lua/templater/README.md) renders `{{name}}` templates, including
  `{{lua:…}}` code, and inserts them with `:InsertTemplate` or `:PickTemplate`.
- [`frontmatter`](lua/frontmatter/README.md) refreshes `updated_at` on save.
- [`markdown-navigation`](lua/markdown-navigation/README.md) follows links and
  goes back.

The wiring is where one module is told about another, for example
`frontmatter` skips `templater`'s template files. Daily and weekly notes are not
a module: [`digital_notes.lua`](lua/digital_notes.lua) opens a file named after
the day or week and fills it from a template. See
[the notes workflow](docs/notes-workflow.md).

## Documentation and tests

- [`docs/testing.md`](docs/testing.md) contains exact testing commands, the
  abstract test flow, coverage responsibilities, and troubleshooting.
- The README in each `lua/<module>/` directory documents that module.
- `tests/` contains plain Lua tests executed inside headless Neovim, one
  directory per module.

The tests use temporary directories and real Neovim buffers. They do not read
or write the personal knowledge base.

## Paths and devices

The configuration assumes the same home-relative layout on macOS and Linux:
`~/.config/nvim`. Shell documentation derives the location from
`XDG_CONFIG_HOME` when it is set and otherwise falls back to `$HOME/.config`.
Runtime Lua should use Neovim's standard-path and expansion APIs rather than a
device-specific absolute home path.

This directory is tracked as part of a bare dotfiles repository rather than a
standalone Git repository. The repository metadata lives at `~/.dotfiles`, and
the working tree is the home directory.
