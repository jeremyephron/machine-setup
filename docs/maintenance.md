# Maintenance

Normal reruns do not upgrade everything:

```bash
./setup.sh apply
```

Use the explicit update path when there is time to test changes:

```bash
git switch -c codex/update-machine-setup-YYYY-MM
./setup.sh update
./setup.sh apply
./setup.sh doctor
```

`update` refreshes Homebrew-managed selected packages and regenerates the
cross-platform mise lock from `lockfiles/mise.toml`. Review version and checksum
changes. Update Neovim plugins deliberately with `:Lazy update`, then use
`chezmoi --source "$PWD" re-add ~/.config/nvim/lazy-lock.json` from the repository
root so the checked-in lock matches. Mason tool versions are explicit in
`home/dot_config/nvim/lua/machine_setup/lsp.lua`; update those numbers
deliberately from `:Mason`, then run a full apply and editor health check.

When bumping bootstrap tools in `lib/versions.sh`, obtain the release URL and
checksum from the upstream project, test all supported OS/architecture pairs,
and change version plus hashes in one reviewable commit. Never replace a pinned
download with `curl | sh`.

## Review cadence

There is no unattended scheduled upgrade. CI runs syntax/profile/render checks
and bootstraps disposable macOS and Ubuntu hosts. A manual workflow can exercise
the slower full CLI profile. Every few months, review:

- unused Neovim plugins and global Python packages;
- Homebrew leaves/casks printed by cleanup;
- language LTS/minor choices;
- Ubuntu desktop package provenance;
- browser extensions and apps still used;
- whether profile differences are real or can be collapsed.
