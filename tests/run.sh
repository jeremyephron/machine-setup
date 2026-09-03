#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
"${SOURCE_DIR}/tests/test-static.sh"
"${SOURCE_DIR}/tests/test-profiles.sh"
"${SOURCE_DIR}/tests/test-packages.sh"
"${SOURCE_DIR}/tests/test-templates.sh"
