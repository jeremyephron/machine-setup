#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"

[ "$(uname -s)" = 'Darwin' ] || die 'macOS preferences can only run on macOS.'

heading 'macOS preferences'
defaults write NSGlobalDomain InitialKeyRepeat -int 10
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string 'Nlsv'
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 28
defaults write com.apple.dock mru-spaces -bool false

defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

if [ -d /Applications/Rectangle.app ]; then
  defaults write com.knollsoft.Rectangle launchOnLogin -bool true
fi

if [ -d /Applications/Skim.app ]; then
  defaults write net.sourceforge.skim-app.skim SKAutoCheckFileUpdate -bool true
  defaults write net.sourceforge.skim-app.skim SKAutoReloadFileUpdate -bool true
  defaults write net.sourceforge.skim-app.skim SKTeXEditorPreset -string 'Custom'
  defaults write net.sourceforge.skim-app.skim SKTeXEditorCommand -string '/opt/homebrew/bin/nvim'
  defaults write net.sourceforge.skim-app.skim SKTeXEditorArguments -string '--headless -c "VimtexInverseSearch %line '\''%file'\''"'
fi

for app in Finder Dock; do
  killall "$app" >/dev/null 2>&1 || true
done

brew_bash='/opt/homebrew/bin/bash'
if [ -x "$brew_bash" ] && [ "${SHELL:-}" != "$brew_bash" ]; then
  heading 'Login shell'
  if ! grep -Fxq "$brew_bash" /etc/shells; then
    printf '%s\n' "$brew_bash" | sudo tee -a /etc/shells >/dev/null
  fi
  chsh -s "$brew_bash"
  warn 'The Homebrew Bash login shell takes effect in newly opened terminals.'
fi

heading 'Security settings requiring your review'
if fdesetup status | grep -q 'FileVault is On'; then
  success 'FileVault is enabled.'
else
  warn 'FileVault is off. Open System Settings > Privacy & Security > FileVault and enable it.'
fi
firewall_state="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || true)"
case "$firewall_state" in
  *enabled*) success 'The application firewall is enabled.' ;;
  *) warn 'The firewall is off. Open System Settings > Network > Firewall and enable it.' ;;
esac

warn 'Log out once for keyboard repeat, trackpad, and login-shell changes to settle everywhere.'
