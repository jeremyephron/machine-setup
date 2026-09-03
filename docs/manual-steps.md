# Manual finish checklist

Automation stops where a human should see a recovery key, consent screen, or
account boundary. After the profile has been saved, `./setup.sh doctor` keeps
these visible.

## Workspaces

Confirm `machineSetup.companyFolder` in
`~/.config/chezmoi/chezmoi.toml`. It is a single machine-local folder name under
`~/src`; the setup creates it and assigns it the work Git identity. Keep the
default `company` or replace it with the appropriate company name for that
machine, then reapply the managed configuration.

## Security and accounts

1. On macOS, enable FileVault in **System Settings → Privacy & Security →
   FileVault** and store the recovery method safely.
2. On macOS, enable the application firewall in **System Settings → Network →
   Firewall**.
3. Confirm each identity's `sshKey` path in
   `~/.config/chezmoi/chezmoi.toml`, then run `./setup.sh identities`. Existing
   keys are reused; a key is generated only when its selected path is missing.
   Keep SSH passphrases in Bitwarden and register new public keys with the
   matching account.
4. Select the intended GPG secret key for each identity by entering its full
   fingerprint as `gpgKey` in the same local config. Import separate keys first
   if you use them; deliberately sharing one key between identities is also
   supported. From the repository root, apply only the affected files with:

   ```bash
   chezmoi --source "$PWD" apply --interactive \
     ~/.gitconfig ~/.gitconfig-personal ~/.gitconfig-work ~/.ssh/config
   ```

5. Sign in to GitHub/`gh`, Bitwarden, Tailscale, VPN, Slack, email, Signal,
   WhatsApp, TickTick, Zotero, Microsoft 365, Spotify, and Obsidian as relevant.

Never put tokens, private keys, recovery keys, VPN profiles, SSH hostnames, or
employer data in this public repository. Use `~/.ssh/config.local`,
`~/.bashrc.local`, the local chezmoi config, OS keychains, and Bitwarden.

## Chrome

Turn on browser sync. Confirm these extensions rather than installing managed
enterprise policies:

- [Bitwarden](https://chromewebstore.google.com/detail/bitwarden-password-manage/nngceckbapebfimnlniiiahkandclblb)
- [Vimium](https://chromewebstore.google.com/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb)
- [Video Speed Controller](https://chromewebstore.google.com/detail/video-speed-controller/nffaoalbilbmmfgbnbgppjihopabppdk)

Review Chrome sync and password-manager behavior before making a browser the
default. This setup deliberately uses Chrome app windows for WhatsApp, TickTick,
Word, Excel, and PowerPoint on Linux.

## macOS applications

- Open Ghostty once and confirm Homebrew Bash starts.
- Grant Rectangle Accessibility permission and confirm launch at login.
- Open OpenSuperWhisper once, grant its requested microphone and accessibility
  permissions, and set its dictation shortcut.
- In Skim's Sync preferences, verify auto-check/reload and the Neovim inverse
  search command. Compile a tiny VimTeX document and test both directions.
- Start Docker Desktop and accept its normal first-run setup.
- Start Tailscale/OpenVPN and authorize only the intended networks.
- Log out once after apply so login shell, keyboard repeat, and trackpad defaults
  are active everywhere.

## Ubuntu desktop differences

The Ubuntu profile uses managed Chrome launchers for WhatsApp, TickTick, Word,
Excel, and PowerPoint. GNOME window management and Linux PDF viewers replace
Rectangle and Skim; XQuartz is macOS-specific. OpenSuperWhisper is not installed
on Ubuntu, and Cursor installation currently remains manual. Obsidian and Zotero
are installed from checksum-pinned official upstream releases.

Ubuntu normally starts with Bash. On an unusual server or remote account where
doctor reports another login shell, use `chsh -s /bin/bash` if the administrator
allows it; the setup does not bypass host policy to make that change.
