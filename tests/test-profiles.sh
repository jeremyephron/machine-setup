#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "${SOURCE_DIR}/lib/common.sh"
# shellcheck source=lib/profiles.sh
. "${SOURCE_DIR}/lib/profiles.sh"

assert_equal() {
  if [ "$1" != "$2" ]; then
    printf 'Expected %s, got %s: %s\n' "$2" "$1" "$3" >&2
    exit 1
  fi
}

count=0
for profile in $MACHINE_SETUP_PROFILES; do
  profile_is_valid "$profile"
  load_profile "$profile"
  assert_equal "$PROFILE_NAME" "$profile" 'profile name'
  case "$profile" in
    personal-mac-laptop | work-mac-laptop | work-mac-server)
      assert_equal "$PROFILE_PLATFORM" darwin "$profile platform"
      assert_equal "$PROFILE_DESKTOP" 1 "$profile desktop"
      assert_equal "$PROFILE_DEV" 1 "$profile development"
      ;;
    work-linux-server)
      assert_equal "$PROFILE_PLATFORM" ubuntu "$profile platform"
      assert_equal "$PROFILE_DESKTOP" 0 "$profile desktop"
      assert_equal "$PROFILE_INFRA" 1 "$profile infrastructure"
      ;;
    personal-linux-laptop)
      assert_equal "$PROFILE_PLATFORM" ubuntu "$profile platform"
      assert_equal "$PROFILE_DESKTOP" 1 "$profile desktop"
      assert_equal "$PROFILE_LATEX" 1 "$profile latex"
      ;;
    minimal-remote)
      assert_equal "$PROFILE_CORE_ONLY" 1 "$profile core-only"
      assert_equal "$PROFILE_NEEDS_ROOT" 1 "$profile root"
      ;;
    minimal-remote-no-root)
      assert_equal "$PROFILE_CORE_ONLY" 1 "$profile core-only"
      assert_equal "$PROFILE_NEEDS_ROOT" 0 "$profile no-root"
      ;;
  esac
  count=$((count + 1))
done

assert_equal "$count" 7 'profile count'
printf 'profile tests passed (%s profiles)\n' "$count"
