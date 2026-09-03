#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"

[ "${MACHINE_SETUP_CI:-0}" = '0' ] || die 'Identity setup is intentionally disabled in CI.'
ensure_dir "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

git_email() {
  git config --file "$HOME/.gitconfig-$1" --get user.email 2>/dev/null || true
}

for identity in personal work; do
  key="$(identity_ssh_key "$identity")"
  email="$(git_email "$identity")"
  if [ -f "$key" ]; then
    if [ ! -f "${key}.pub" ]; then
      warn "${identity} SSH private key exists, but ${key}.pub is missing. Recreate the public key with: ssh-keygen -y -f $(shell_quote "$key") > $(shell_quote "${key}.pub")"
    else
      success "${identity} SSH key already exists: ${key}"
    fi
    continue
  fi
  case "$identity" in
    personal) identity_label='Personal' ;;
    work) identity_label='Work' ;;
  esac
  heading "${identity_label} SSH key"
  ensure_dir "$(dirname "$key")"
  info 'ssh-keygen will ask for a passphrase; use a unique one stored in Bitwarden.'
  ssh-keygen -t ed25519 -a 100 -C "${email:-$identity}" -f "$key"
  if [ "$(uname -s)" = 'Darwin' ]; then
    ssh-add --apple-use-keychain "$key" || warn 'Add the key to ssh-agent after the next login.'
  else
    ssh-add "$key" || warn 'Start ssh-agent and add this key when needed.'
  fi
  printf '\nPublic key to register for %s accounts:\n' "$identity"
  cat "${key}.pub"
done

heading 'GPG signing keys'
if gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -q '^sec'; then
  gpg --list-secret-keys --keyid-format LONG
else
  warn 'No secret GPG keys are present.'
fi
cat <<'EOF'

Restore the separate personal and work signing keys from their encrypted
Bitwarden-backed copies. Then put each full key fingerprint in:

  ~/.config/chezmoi/chezmoi.toml

under data.identity.personal.gpgKey and data.identity.work.gpgKey, and run:

  ./setup.sh apply --profile <this-profile>

Finally register each public SSH key and GPG public key with the matching
GitHub/account provider. The setup deliberately does not transmit keys or sign
in to accounts on your behalf.
EOF
