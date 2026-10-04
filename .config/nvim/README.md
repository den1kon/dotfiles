# Neovim configuration

This is a personal Neovim configuration used on macOS and Linux. This README
describes its current organization and startup flow; it does not require the
layout to remain unchanged as the configuration evolves.

## Startup flow

[`init.lua`](init.lua) is the main entry point. At startup it currently:

1. Loads global editor options from `lua/settings.lua`.
2. Registers packages with `vim.pack.add()`.
3. Loads Treesitter and formatting configuration.
4. Applies the colorscheme and custom marks.
5. Configures and enables language servers.
6. Sets up the extended MiniFiles behavior and keymaps.
7. Applies Markdown-specific highlighting.

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
│   ├── notes/               Daily and weekly note automation
│   └── ...                  Focused editor-feature modules
├── plugin/                  Runtime setup for installed plugins
├── ftplugin/                Filetype-local configuration
├── tests/notes/             Headless tests for note automation
└── docs/                    Longer operational documentation
```

The modules under `lua/` are loaded with `require()`. Related behavior may be
grouped into a directory, as with `lua/lsp/` and `lua/notes/`, while smaller
features remain single modules.

## Packages and plugin setup

Packages are declared in [`init.lua`](init.lua) with Neovim's `vim.pack` API.
Most plugin-specific setup currently lives under `plugin/`:

- `plugin/mininvim.lua` configures the selected `mini.nvim` modules.
- `plugin/slipnote.lua` configures wiki-link and frontmatter behavior.
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
For example, daily and weekly note mappings delegate to `lua/notes/`.

## Periodic notes

The note automation opens daily and ISO-weekly Markdown notes, generates an
initial template only for an empty buffer, and never saves automatically. See
the [periodic-note overview](lua/notes/README.md) for its modules, data flow,
and buffer-safety guarantees.

## Documentation and tests

- [`docs/testing.md`](docs/testing.md) contains exact testing commands, the
  abstract test flow, coverage responsibilities, and troubleshooting.
- [`lua/notes/README.md`](lua/notes/README.md) documents the periodic-note
  implementation.
- `tests/notes/` contains plain Lua tests executed inside headless Neovim.

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
