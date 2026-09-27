#!/usr/bin/env bash
# =============================================================================
# scripts/setup.sh - smoke test: "is this machine ready for the project?"
# -----------------------------------------------------------------------------
# Runs four checks in order: tool version -> environment loaded ->
# inventory resolvable -> module transport works.
# Deeper diagnosis: bash scripts/doctor.sh | Full validation: scripts/validate.sh
# =============================================================================
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."   # always run from the project root
source scripts/env.sh >/dev/null         # export ANSIBLE_* (works on WSL /mnt/*)

echo "==> ansible version"
ansible --version | head -n 1

echo "==> configuration in force (CONFIG_FILE must point into this repo)"
ansible-config dump --only-changed | head -n 4

echo "==> inventory graph"
ansible-inventory --graph

echo "==> module transport to localhost"
ansible local -m ping

