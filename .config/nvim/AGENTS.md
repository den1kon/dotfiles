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

- Add headless Neovim tests for nontrivial Lua behavior and regressions.
- Tests should exercise real Neovim buffer, window, command, and filesystem
  behavior rather than source-text details.
- Run the relevant headless tests and `stylua --check` after changes.
