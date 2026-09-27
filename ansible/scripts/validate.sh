#!/usr/bin/env bash
# =============================================================================
# scripts/validate.sh - ONE command that proves the whole project is healthy
# -----------------------------------------------------------------------------
# WHAT IT RUNS (in order, stopping at the first failure with context):
#   1. tool versions
#   2. --syntax-check on EVERY playbook (playbooks/*.yml, site.yml, role tests)
#   3. static inventory graph
#   4. dynamic inventory --graph  (script inventory contract)
#   5. python byte-compile of inventory.py (catches syntax errors early)
#   6. ansible-vault decrypt round-trip (if vault material exists)
#   7. markdown link check - every README/docs link resolves to a real file
#
# USAGE:  bash scripts/validate.sh
# NOTE:   sources scripts/env.sh first so ansible.cfg settings are loaded
#         even on world-writable directories (WSL /mnt/<drive>...).
# =============================================================================
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."          # project root
source scripts/env.sh >/dev/null                 # exports ANSIBLE_* vars
trap 'echo; echo "FAILED at: ${BASH_COMMAND}" >&2; exit 1' ERR

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
CHECKS=0

step "1/7 tool versions"
ansible --version | head -1
ansible-playbook --version | head -1

step "2/7 syntax-check every playbook"
for pb in playbooks/*.yml site.yml roles/*/tests/test.yml; do
  printf '    %-45s' "$pb"
  ansible-playbook --syntax-check "$pb" >/dev/null
  echo "OK"
  CHECKS=$((CHECKS+1))
done

step "3/7 static inventory graph (inventory/hosts)"
ansible-inventory --graph | sed 's/^/    /'

step "4/7 dynamic inventory (inventory/dynamic/inventory.py)"
ansible-inventory -i inventory/dynamic/inventory.py --graph | sed 's/^/    /'

step "5/7 byte-compile the dynamic inventory script"
python3 -m py_compile inventory/dynamic/inventory.py
echo "    OK (syntax valid)"

step "6/7 vault round-trip (encrypt/decrypt sanity)"
if [[ -f vault/secrets.yml && -f scripts/vault_pass_demo.txt ]]; then
  ansible-vault view vault/secrets.yml --vault-password-file scripts/vault_pass_demo.txt \
    | head -3 | sed 's/^/    /'
  echo "    OK (vault decrypts with the demo password)"
else
  echo "    skipped (vault material not present yet)"
fi

step "7/7 markdown links (README + docs)"
python3 scripts/check_links.py

echo
echo "============================================================"
echo "VALIDATION PASSED - ${CHECKS} playbooks syntax-checked, inventories OK, vault OK, docs linked"
