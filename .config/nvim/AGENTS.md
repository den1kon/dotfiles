# Neovim configuration

## Design principles

- Keep the configuration modular and written in Lua.
- Group related functionality in dedicated directories under `lua/`.
- Keep keymap files focused on registration; put nontrivial behavior in
  dedicated modules.
- Prefer Neovim's built-in APIs and existing plugins. Do not add a dependency
  when a small native implementation is sufficient.
- Do not modify installed plugin source under Neovim's data directory.

## Readability

- Optimize code for human readability and straightforward review.
- Prefer descriptive names, direct control flow, small cohesive functions, and
  explicit data flow.
- Keep implementation size proportional to the problem. More code increases
  review cost, so prefer the smallest clear and complete solution.
- Do not reduce line count by making code dense, clever, or implicit.
- Avoid unnecessary indirection and premature abstractions.
- Code should remain understandable without relying on comments.
- Use comments to explain intent, invariants, safety constraints, or
  Neovim-specific behavior; do not use comments merely to restate the code.

## Documentation

- Treat files under `docs/` and all `README.md` files as maintained parts of
  the codebase.
- When code behavior, commands, structure, configuration, or testing changes,
  update the relevant documentation in the same task.
- Keep documented paths, examples, guarantees, and module responsibilities
  consistent with the current implementation.
- Prefer one authoritative explanation with links from narrower documentation
  instead of duplicating detailed instructions.
- Document current behavior, not speculative future behavior.

## Paths and portability

- This configuration is used on both macOS and Linux.
- Do not hardcode device-specific home paths such as `/Users/name` or
  `/home/name` in code, tests, rules, or documentation.
- In documentation and shell examples, use `~`, `$HOME`, or XDG environment
  variables.
- Prefer paths relative to the configuration root when referring to files
  inside this repository.
- In Lua, use Neovim path APIs such as `vim.fn.stdpath()` or
  `vim.fn.expand("~")` instead of embedding a home-directory path.
- Some tools do not expand `~`. Before passing a path to such a tool, resolve
  the current device's home directory and use the resulting absolute path.

## Dotfiles repository

- This configuration is tracked through the bare Git repository
  `$HOME/.dotfiles`, with `$HOME` as its working tree.
- Do not initialize a separate Git repository inside the Neovim configuration.
- The user's interactive aliases are:
  - `dotfiles`: run Git against the bare dotfiles repository.
  - `lazydots`: open Lazygit against the same repository and working tree.
- In noninteractive commands, use:
  `git -C "$HOME" --git-dir="$HOME/.dotfiles" --work-tree="$HOME"`.
- Scope status, diff, history, staging, and other operations to `.config/nvim`
  or to exact files. The working tree is the entire home directory.
- The repository hides untracked files by default. Inspect new Neovim files
  with `status --short --untracked-files=all -- .config/nvim`.
- Stage exact files only. Do not use broad commands such as `git add -A` or
  `git add .` against the home-directory work tree.
- Inspect the staged diff before committing.
- Follow the existing commit-message convention, such as
  `[neovim] describe the change`.
- Never run an unscoped destructive Git command against the home-directory
  work tree.

## Buffer and file safety

- Preserve unsaved buffer changes.
- Never use forced commands such as `:edit!`, `:buffer!`, or `:quit!` to work
  around modified-buffer errors.
- Do not save, overwrite, or discard a buffer automatically unless the user
  explicitly requests that behavior.
- When a command targets the file already displayed in the current buffer,
  reuse that buffer instead of re-editing or reloading it.
- Let Neovim block navigation away from an unrelated modified buffer rather
  than silently discarding or saving its contents.

## Commands and mappings

- Prefer descriptive user commands for reusable workflows.
- Keymaps should be thin entry points to the same underlying Lua functions.
- Give commands and mappings useful `desc` values.
- Preserve the user's buffer- and window-oriented workflow unless a different
  behavior is explicitly requested.

## Verification

- Read `docs/testing.md` before running, adding, or changing tests; it is the
  authoritative testing guide for this configuration.
- Add headless Neovim tests for nontrivial Lua behavior and regressions.
- Tests should exercise real Neovim buffer, window, command, and filesystem
  behavior rather than source-text details.
- Run the relevant headless tests and `stylua --check` after changes.
