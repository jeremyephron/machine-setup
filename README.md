# Jeremy's machine setup

This repository turns a fresh Apple silicon Mac or Ubuntu 24.04+ machine into
Jeremy's working environment. It also converges an existing machine safely:
preview first, install missing pieces without blanket upgrades, and keep every
removal in a separate confirmed cleanup workflow.

The fast path delivers Bash, Git/SSH, Neovim, tmux, the preferred command-line
tools, managed configuration, and applicable macOS preferences. A full profile
continues with the selected language runtimes, infrastructure tools, desktop
apps, and LaTeX. The target is a useful core in well under 20 minutes; app
downloads and TeX can continue after that depending on the network.

## Start a new machine

After the OS account, network, and Bitwarden are ready:

```bash
mkdir -p "$HOME/src/personal"
git clone https://github.com/jeremyephron/machine-setup.git "$HOME/src/personal/machine-setup"
cd "$HOME/src/personal/machine-setup"
./setup.sh apply --core-only
./setup.sh doctor --core-only
./setup.sh apply
./setup.sh doctor
```

The first run asks for a machine profile and local-only identity values. The
selected profile is saved, so later commands can omit `--profile`. The first two
commands establish and verify the fast terminal/editor baseline; the last two
install and verify the full profile. Re-running `apply` is expected and safe.

On an existing machine, begin with a read-only preview:

```bash
./setup.sh plan
```

If the machine has no saved profile yet, the command asks you to select one.

## Commands

| Command | Purpose | Changes data? |
| --- | --- | --- |
| `plan` | Show the profile, package gaps, and chezmoi diff when initialized | No |
| `apply` | Install missing items and preview/apply managed-file changes | Yes |
| `doctor` | Check the machine and list manual follow-ups | No |
| `update` | Explicitly upgrade packages and refresh verified locks | Yes |
| `identities` | Reuse or generate per-account SSH keys and guide GPG setup | Yes, prompted |
| `cleanup` | Review optional cleanup candidates and confirm each action | Yes, separately confirmed |

Useful flags are `--profile NAME`, `--core-only`, `--skip-desktop`, `--dry-run`,
and `--yes`. A dry run is equivalent to the read-only plan. `--yes` never
bypasses destructive cleanup confirmations.

## Profiles

| Profile | Intended machine | Included layers |
| --- | --- | --- |
| `personal-mac-laptop` | Personal Apple silicon Mac | Core, development, infrastructure, desktop, LaTeX, macOS preferences |
| `work-mac-laptop` | Work Apple silicon Mac | Core, development, infrastructure, desktop, LaTeX, macOS preferences |
| `work-mac-server` | UI-capable, often-headless Mac mini | Core, development, infrastructure, desktop, LaTeX, macOS preferences |
| `work-linux-server` | Ubuntu 24.04+ server | Core, development, infrastructure |
| `personal-linux-laptop` | x86-64 Ubuntu 24.04+ desktop | Core, development, infrastructure, desktop, LaTeX |
| `minimal-remote` | Root-enabled Ubuntu host | Core only |
| `minimal-remote-no-root` | Restricted Linux host | Verified user-local core subset |

Full UI profiles target the same workflows, but their application packages
differ where an app is platform-specific. Web equivalents and manual omissions
remain visible in the finish checklist.
Ubuntu ARM64 remains supported by the server and remote profiles; its proprietary
desktop app set is not represented as equivalent to x86-64.

## Important behavior

- [chezmoi](https://www.chezmoi.io/) owns dotfiles and templates. Machine-local
  names, emails, GPG fingerprints, SSH key paths, and proxy endpoints live only
  in its local config.
- Homebrew owns most cross-platform packages; Ubuntu `apt` owns prerequisites
  and services. Normal `apply` passes Homebrew's no-upgrade mode.
- [mise](https://mise.jdx.dev/) selects Python 3.13, current Node LTS, and current
  Java LTS. Its checked-in lock records URLs and checksums for Apple silicon,
  Linux x86-64, and Linux ARM64.
- Rust uses rustup stable. Project files can override any language version.
- Python projects stay clean. `ipy`/`pyscratch` opens a separate scientific
  environment with Jupyter, NumPy, SciPy, pandas, Polars, Matplotlib, scikit-learn,
  scikit-image, Pillow, Requests, and Beautiful Soup.
- Git has no fallback identity. Repositories under `~/src/personal` use the
  personal account; `~/src/work` and the locally named company folder use work;
  `~/src/scratch` requires an explicit choice. The company folder name is kept
  only in the local chezmoi config.
- Standalone release archives are version-pinned and checksum-verified; signed
  package managers and vendor repositories manage the rest.
- Secrets, private keys, VPN settings, account sessions, and employer-specific
  data are never committed.

See [the component review](docs/components.md),
[existing-machine guide](docs/existing-machines.md),
[manual finish checklist](docs/manual-steps.md), and
[maintenance notes](docs/maintenance.md).
