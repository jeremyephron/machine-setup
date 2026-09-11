# Components

This document describes the durable parts of the setup, what each part does,
and where it is maintained.

## Bootstrap and lifecycle

| Area | Behavior | Where to change it |
| --- | --- | --- |
| Entry point | `plan`, `apply`, `doctor`, `update`, `identities`, and `cleanup` | `setup.sh` |
| Profiles | Seven named machine roles select the appropriate layers | `lib/profiles.sh` |
| Packages | `apply` installs missing requirements; `update` performs routine upgrades | `lib/packages.sh` |
| Tool versions | Bootstrap tools and standalone archives are pinned and checksummed | `lib/versions.sh` |
| User files | chezmoi renders the templates under `home/` | `.chezmoiroot`, `home/` |
| Existing files | Changes are previewed and applied interactively; unmanaged files and applications are preserved | `setup.sh`, chezmoi |
| Cleanup | Cleanup is a separate, confirmed operation with backups where practical | `scripts/cleanup-legacy.sh` |
| Verification | Static checks, profile tests, template rendering, CI, and `doctor` | `tests/`, `.github/` |

`plan` previews a profile without changing the machine. `apply` installs and
configures it, `doctor` checks it, and `update` upgrades software while
reapplying managed configuration. Identity setup and cleanup remain separate so
their effects are explicit.

## Shell and terminal

- Bash is the supported shell. macOS uses Homebrew Bash so every supported
  platform has the required Bash features.
- `.bash_profile` suppresses macOS's default-shell warning and loads `.bashrc`.
- `.bashrc` initializes Homebrew, mise, direnv, fzf, Neovim, the prompt, and
  optional machine-local configuration.
- `socks-proxy on|off|status` uses a target supplied in machine-local settings.
  On macOS it also enables or disables the SOCKS proxy for the active network
  service in System Settings. Set `MACHINE_SETUP_SOCKS_NETWORK_SERVICE` in
  `~/.config/machine-setup/local.bash` to override automatic service detection.
- `git-delete-merged` fetches and prunes, finds the remote default branch,
  excludes protected and current branches, shows the candidates, asks for
  confirmation, and uses non-forced deletion.
- Ghostty is the primary terminal. tmux enables true color, mouse support, vi
  copy mode, and a large history.

## Git, SSH, and directories

The managed project layout is:

```text
~/src/
├── personal/   personal Git identity, signing key, and SSH key
├── work/       work Git identity, signing key, and SSH key
├── <company>/  work Git identity, signing key, and SSH key
└── scratch/    no automatic Git identity
```

Git selects identities with `includeIf` directory rules and enables
`user.useConfigOnly`, so a repository outside an identity directory cannot
silently use the wrong account. Repository-local Git configuration can still
override these rules when needed. The `machineSetup.companyFolder` value names
the company directory; it is stored only in the machine's local chezmoi config
and defaults to `company` on a new setup.

SSH private-key paths and GPG fingerprints are machine-local values and are not
committed. Identity setup reuses a selected SSH key when it exists and only
generates one when it is missing. The managed SSH file contains defaults and
generic GitHub aliases; private host entries belong in unmanaged
`~/.ssh/config.local`. Commit and tag signing are enabled for an identity only
when that identity has an explicit GPG fingerprint.

## Packages and applications

Package manifests are grouped by role:

- Core: Bash, Neovim, tmux, Git, Git LFS, delta, GitHub CLI, GPG, fzf,
  ripgrep, fd, bat, jq/yq, nnn, btop, tree, watch, direnv, shellcheck/shfmt,
  Tree-sitter CLI, chezmoi, mise, and uv.
- Development: Bazelisk, CMake, Ninja, GCC, GDB where supported, FFmpeg,
  ImageMagick, pkg-config, pre-commit, and rustup.
- Infrastructure: AWS CLI, kubectl, Terraform, Docker, Tailscale, and OpenVPN.
- macOS desktop: Ghostty, Chrome, Cursor, Rectangle, OpenSuperWhisper, Signal,
  WhatsApp, Slack and its CLI, TickTick, Zotero, Spotify, Obsidian, Skim, Word,
  Excel, PowerPoint, Docker Desktop, Tailscale, OpenVPN Connect, and XQuartz.
- Ubuntu desktop: native packages or supported repositories for desktop tools,
  with browser launchers for web-only applications.

An already-installed macOS application satisfies the requirement even when it
was installed outside Homebrew. The setup does not replace or take ownership of
that application.

## Languages and notebooks

- mise manages Python 3.13, Node LTS, and Java LTS. Per-project configuration
  and standard language version files override the global defaults.
- rustup manages stable Rust.
- The platform compiler and debugger provide C/C++ support, with CMake, Ninja,
  and Homebrew GCC on macOS.
- Jupyter and the curated scientific Python packages live in an isolated
  environment under `~/.local/share/machine-setup/python-scratch`. The `ipy`
  command opens that environment without adding its packages to projects.

## Neovim

The Lua configuration provides Monokai, comma leader, fuzzy file search, Git
change indicators and Fugitive, persistent undo, split and indentation defaults,
trailing-space cleanup, terminal access, Treesitter, diagnostics, completion,
formatting, linting, and VimTeX/Skim integration.

Plugins are bootstrapped with pinned lazy.nvim and locked by `lazy-lock.json`.
The configuration uses the native LSP API, Mason-managed development tools,
nvim-cmp, Telescope with fzf-native, Conform, and nvim-lint. Core setup installs
and checks plugins; development profiles also install the locked language
servers, debuggers, formatters, and linters.

## OS and application preferences

macOS configuration sets keyboard repeat, disables press-and-hold and automatic
text substitutions, shows useful Finder details, keeps the Dock compact, and
enables tap-to-click. Rectangle launches at login. Skim reloads changed PDFs
and supports inverse search into Neovim.

FileVault and the application firewall require guided confirmation in System
Settings. Account sign-ins and Chrome extension installation remain manual;
browser sync restores Bitwarden, Vimium, and Video Speed Controller.
