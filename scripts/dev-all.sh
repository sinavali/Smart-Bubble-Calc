#!/usr/bin/env bash
# Smart-Bubble-Calc: Local Development & Android Testing Entrypoint (Fedora Linux)
# Invariant: ZERO half-space characters (\u200c) allowed.
# Culture: fa-IR, Tehran timezone & Iranian financial market regulations.

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Ensure scripts/dev_all.py is executable
chmod +x "${SCRIPT_DIR}/dev_all.py"

exec python3 "${SCRIPT_DIR}/dev_all.py" "$@"
