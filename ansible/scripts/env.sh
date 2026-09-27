#!/usr/bin/env bash
# =============================================================================
# scripts/env.sh - load this project's Ansible environment into YOUR SHELL
# -----------------------------------------------------------------------------
# WHY IT EXISTS: Ansible SKIPS auto-discovery of ./ansible.cfg when the
# current directory is world-writable (mode 777 - typical for /mnt/<drive>
# in WSL, some NFS mounts, CI containers). Environment variables rank ABOVE
# ansible.cfg, so exporting them bypasses discovery entirely. It also makes
# every command work from ANY directory.
#
# USAGE:   source scripts/env.sh        <- MUST be `source`, not `./env.sh`
#          (running it directly would export vars into a subshell that dies)
# UNDO:    unset_ansible_env            <- helper defined below
# VERIFY:  ansible-config dump --only-changed
#
# NOTE: no `set -euo pipefail` here on purpose - this file runs INSIDE your
#       interactive shell and must not change YOUR shell options.
# =============================================================================

# Running instead of sourcing? Tell the user and stop (a subshell cannot
# change the parent shell's environment anyway).
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "This script must be SOURCED so its exports reach your shell:"
  echo "    source scripts/env.sh"
  exit 1
fi

# Project root = parent of scripts/, resolved robustly even when sourced
# from another directory:
_ANSIBLE_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# The four settings that make this project self-contained:
# ---------------------------------------------------------------------------
export ANSIBLE_CONFIG="${_ANSIBLE_PROJECT_ROOT}/ansible.cfg"
export ANSIBLE_ROLES_PATH="${_ANSIBLE_PROJECT_ROOT}/roles:${HOME}/.ansible/roles"
export ANSIBLE_COLLECTIONS_PATH="${_ANSIBLE_PROJECT_ROOT}/collections:${HOME}/.ansible/collections"
export ANSIBLE_INVENTORY="${_ANSIBLE_PROJECT_ROOT}/inventory/hosts"
# NOTE: a CLI -i flag still WINS over ANSIBLE_INVENTORY, so dynamic
# inventories keep working:  ansible-playbook -i inventory/dynamic/... ...

unset _ANSIBLE_PROJECT_ROOT

# Helper so the change is reversible in the current shell:
unset_ansible_env() {
  unset ANSIBLE_CONFIG ANSIBLE_ROLES_PATH ANSIBLE_COLLECTIONS_PATH ANSIBLE_INVENTORY
  unset -f unset_ansible_env
  echo "Ansible environment variables cleared."
}

echo "Ansible environment loaded (project root: ${ANSIBLE_CONFIG%/*}):"
echo "  ANSIBLE_CONFIG=${ANSIBLE_CONFIG}"
echo "  ANSIBLE_ROLES_PATH=${ANSIBLE_ROLES_PATH}"
echo "  ANSIBLE_COLLECTIONS_PATH=${ANSIBLE_COLLECTIONS_PATH}"
echo "  ANSIBLE_INVENTORY=${ANSIBLE_INVENTORY}"
echo "Verify with:  ansible-config dump --only-changed"
