# Home Manager configuration

## Layout

- `flake.nix` defines two standalone Home Manager configurations:
  - `macbook` (`aarch64-darwin`)
  - `linux` (`x86_64-linux`)
- Each configuration lists its modules explicitly. A new `*.nix` module does
  nothing until it is added to the relevant module lists in `flake.nix`.
  Decide deliberately whether it belongs to one machine or both.
- Keep one module per tool or concern, such as `git.nix`, `tmux.nix`, or
  `firefox.nix`. Put large static data in a separate file imported by the
  owning module, as `firefox.nix` does with `firefox-bookmarks.nix`.
- `home.nix` owns packages, fonts, and machine detection. Packages that only
  make sense on one machine go in the `isMacbook` or `isLinux` lists.
- `username` and `system` arrive through `extraSpecialArgs`. Use them instead
  of redefining machine-specific values in individual modules.

## Design principles

- Prefer a Home Manager `programs.<name>` module over writing raw config files
  with `home.file` or `xdg.configFile`. Fall back to raw files only when the
  module cannot express the setting.
- Prefer nixpkgs packages over manual installation, Homebrew, or ad hoc
  download scripts.
- Do not add a flake input when nixpkgs or Home Manager already provides the
  package or module.
- Keep changes small and proportional to the problem. Avoid helper functions
  and abstractions for a single use.
- Use comments to explain intent, workarounds, and non-obvious behavior, such
  as why a policy or preference is needed. Do not restate option names.
- Keep commented-out code only when it is an intentional, easy toggle. Remove
  dead experiments instead of commenting them out.
- Format Nix files with `nixfmt`.

## Paths and portability

- This configuration is used on both macOS and Linux, with different
  usernames.
- Do not hardcode home paths such as `/Users/name` or `/home/name`. Use
  `config.home.homeDirectory`, paths relative to the home directory in
  `home.file`, or `$HOME` in shell snippets.
- Guard platform-specific packages and settings with `isMacbook`/`isLinux`,
  `pkgs.stdenv.isDarwin`/`isLinux`, or `lib.mkIf`. Verify that a package
  supports both platforms before adding it to the shared list.
- Never put secrets, tokens, or private keys in Nix files. Everything
  evaluated ends up in the world-readable Nix store.

## Applying changes

- The `Makefile` wraps the common commands: `make mac`, `make linux`,
  `make update`, and `make clean`.
- To verify a change without activating it, build the configuration:
  `home-manager build --flake .#macbook` (or `.#linux` on Linux). Remove the
  resulting `result` symlink afterwards.
- Do not run `home-manager switch` unless the user asks for it. Activation
  changes the live home directory.
- Do not run `nix flake update` unless the user asks. Lock file updates are
  committed separately from configuration changes.
- Never run `nix-collect-garbage` or `make clean` unless the user asks; it
  removes rollback generations.
- Some applications only read their managed files at startup. After a switch,
  tell the user when a restart is needed, for example Firefox for
  `containers.json`, `user.js`, policies, and extensions.

## Application notes

- Firefox:
  - The managed profile lives under the Home Manager–managed Firefox
    directory, on macOS `~/Library/Application Support/org.nixos.firefox`.
    The older `~/Library/Application Support/Firefox` directory is unmanaged.
  - Container `id` values must stay unique and stable. Never renumber existing
    containers; assign the next free id to a new one. `containersForce`
    overwrites containers created in the browser.
  - Extensions are allowlisted through `policies.ExtensionSettings`; anything
    not declared there is blocked. Add new extensions there with a comment
    naming them.
  - Prefer enterprise policies for behavior Firefox exposes as a policy, and
    `settings` (`user.js`) for preferences.

## Dotfiles repository

- This configuration is tracked through the bare Git repository
  `$HOME/.dotfiles`, with `$HOME` as its working tree.
- Do not initialize a separate Git repository inside the Home Manager
  configuration. Nix currently evaluates the flake as a plain path, so new
  files are visible without staging; a `.git` directory would change that.
- The user's interactive aliases are:
  - `dotfiles`: run Git against the bare dotfiles repository.
  - `lazydots`: open Lazygit against the same repository and working tree.
- In noninteractive commands, use:
  `git -C "$HOME" --git-dir="$HOME/.dotfiles" --work-tree="$HOME"`.
- Scope status, diff, history, staging, and other operations to
  `.config/home-manager` or to exact files. The working tree is the entire
  home directory.
- The repository hides untracked files by default. Inspect new files with
  `status --short --untracked-files=all -- .config/home-manager`.
- Stage exact files only. Do not use broad commands such as `git add -A` or
  `git add .` against the home-directory work tree.
- Do not stage unrelated modifications that happen to be in the working tree;
  ask the user when ownership of a change is unclear.
- Commit `flake.lock` updates on their own, for example
  `[home-manager] flake update`.
- Inspect the staged diff before committing.
- Follow the existing commit-message convention: a `[home-manager]` prefix
  followed by a short lowercase summary, such as
  `[home-manager] add obsidian for macbook`.
- Never run an unscoped destructive Git command against the home-directory
  work tree.
