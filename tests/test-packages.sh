#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"
# shellcheck source=lib/packages.sh
. "${SOURCE_DIR}/lib/packages.sh"

# These stubs are called indirectly by install_brewfile.
# shellcheck disable=SC2329
brew() {
  case "$*" in
    'list --formula bazel') return 0 ;;
    'list --formula bazelisk') return 1 ;;
    'help trust') return 0 ;;
    *) return 2 ;;
  esac
}
# shellcheck disable=SC2329
confirm() { return 0; }
package_calls=''
# shellcheck disable=SC2329
run() { package_calls="${package_calls}|$*"; }
# The real function is sourced above; ShellCheck only sees the test override below.
# shellcheck disable=SC2218
install_brewfile "${SOURCE_DIR}/packages/Brewfile.dev" >/dev/null 2>&1
case "$package_calls" in
  *'|brew unlink bazel'*'|env HOMEBREW_NO_INSTALL_CLEANUP=1 brew bundle install --no-upgrade'*) ;;
  *) die 'Bazel was not unlinked before Brewfile installation continued.' ;;
esac

# shellcheck disable=SC2218
install_brewfile "${SOURCE_DIR}/packages/Brewfile.infra" >/dev/null 2>&1
case "$package_calls" in
  *'|brew trust --formula hashicorp/tap/terraform'*'|env HOMEBREW_NO_INSTALL_CLEANUP=1 brew bundle install --no-upgrade'*) ;;
  *) die 'The HashiCorp Terraform formula was not narrowly trusted before installation.' ;;
esac

# CI retries one transient bundle failure and keeps automatic cleanup disabled.
ci_bundle_attempts=0
# shellcheck disable=SC2329
run() {
  case "$*" in
    *'brew bundle install'*)
      ci_bundle_attempts=$((ci_bundle_attempts + 1))
      [ "$ci_bundle_attempts" -gt 1 ]
      ;;
    *) return 0 ;;
  esac
}
# shellcheck disable=SC2218
MACHINE_SETUP_CI=1 install_brewfile "${SOURCE_DIR}/packages/Brewfile.core" >/dev/null 2>&1
[ "$ci_bundle_attempts" -eq 2 ] || die 'CI did not retry a transient Homebrew bundle failure exactly once.'

# A second failure must still fail the setup instead of being hidden.
ci_bundle_attempts=0
# shellcheck disable=SC2329
run() {
  ci_bundle_attempts=$((ci_bundle_attempts + 1))
  return 1
}
if MACHINE_SETUP_CI=1 install_brewfile "${SOURCE_DIR}/packages/Brewfile.core" >/dev/null 2>&1; then
  die 'CI hid a repeated Homebrew bundle failure.'
fi
[ "$ci_bundle_attempts" -eq 2 ] || die 'CI retried a repeated Homebrew bundle failure more than once.'

export PROFILE_NEEDS_ROOT=1 PROFILE_PLATFORM='darwin'
export PROFILE_DEV=1 PROFILE_INFRA=1 PROFILE_DESKTOP=1 PROFILE_LATEX=1
export MACHINE_SETUP_CORE_ONLY=0 MACHINE_SETUP_SKIP_DESKTOP=0
# These stubs are called indirectly by install_profile_packages.
# shellcheck disable=SC2329
is_macos() { return 1; }
# shellcheck disable=SC2329
activate_homebrew() { return 1; }
# shellcheck disable=SC2329
install_homebrew() { return 0; }
processed_brewfiles=''
# shellcheck disable=SC2329
install_brewfile() {
  local stolen
  if IFS= read -r stolen; then
    die "Package command consumed the next Brewfile path: ${stolen}"
  fi
  processed_brewfiles="${processed_brewfiles} $(basename "$1")"
}
install_profile_packages </dev/null
[ "$processed_brewfiles" = ' Brewfile.core Brewfile.dev Brewfile.infra Brewfile.desktop Brewfile.latex' ] || die 'Not every selected Brewfile was processed.'

# A new BasicTeX installation may need a tlmgr self-update before CTAN accepts
# a package installation.
tex_packages_present=0
texlive_calls=''
texlive_self_updated=0
# shellcheck disable=SC2329
tlmgr() {
  if [ "$1" = 'info' ] && [ "$2" = '--only-installed' ] && [ "$tex_packages_present" = '1' ]; then
    printf 'package: %s\ninstalled:   Yes\n' "$3"
    return 0
  fi
  [ "$1" != 'info' ] || printf 'package: %s\ninstalled:   No\n' "$3"
  return 1
}
# shellcheck disable=SC2329
sudo_run() {
  texlive_calls="${texlive_calls}|$*"
  case "$*" in
    'tlmgr update --self') texlive_self_updated=1 ;;
    'tlmgr install '*) [ "$texlive_self_updated" = '1' ] || die 'TeX packages were installed before tlmgr updated itself.' ;;
  esac
}
ensure_texlive_recommended_packages >/dev/null
[ "$texlive_calls" = '|tlmgr update --self|tlmgr install latexmk collection-latexrecommended collection-fontsrecommended' ] || die 'The TeX Live repair sequence is incomplete.'

tex_packages_present=1
texlive_calls=''
ensure_texlive_recommended_packages >/dev/null
[ -z "$texlive_calls" ] || die 'Satisfied TeX packages caused an unnecessary privileged update.'

printf 'package tests passed\n'
