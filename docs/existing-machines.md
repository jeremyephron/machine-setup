# Existing-machine setup

The setup can be adopted without first resetting or cleaning the machine.
Start with a preview, apply the core configuration, verify it, and then install
the complete selected profile:

```bash
./setup.sh plan
./setup.sh apply --core-only
./setup.sh doctor --core-only
./setup.sh apply
./setup.sh doctor
```

`apply` asks for a profile and saves the choice locally. A profile can instead
be supplied explicitly with `--profile PROFILE`. Review the interactive chezmoi
preview before accepting changes to existing managed files.

The process preserves unmanaged files, already-installed applications, and SSH
keys at their configured paths. If a file has local changes that should remain
private to one machine, keep them in the documented local override file rather
than adding them to a managed template.

## Organize repositories

Setup creates these directories but does not move repositories into them:

```text
~/src/personal
~/src/work
~/src/<company>
~/src/scratch
```

`<company>` is the `machineSetup.companyFolder` value in the local chezmoi
config and uses the work Git identity. It is a single folder name, not a path.

Move repositories individually after deciding which identity they should use.
Before each move:

1. Commit, stash, or otherwise preserve uncommitted work.
2. Record the remotes and check scripts or services for absolute paths.
3. Move the repository into its intended identity directory.
4. Verify the effective Git identity and where each value came from:

   ```bash
   git config --show-origin --get-regexp '^user\.(name|email|signingKey)$'
   ```

A repository-local `user.name`, `user.email`, or `user.signingKey` takes
precedence over the directory identity. Remove or update an unintended local
override before committing.

## Cleanup

Cleanup is optional and should only be considered after the complete profile
has been used successfully. Run:

```bash
./setup.sh cleanup
```

The command does not move repositories or bulk-remove packages. It displays
each candidate, requires confirmation for the exact action, and creates a
recoverable backup where practical.
