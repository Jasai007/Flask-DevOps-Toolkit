#!/usr/bin/env bash
# =============================================================================
# scripts/doctor.sh - diagnose the Ansible environment and PRINT THE FIX
# -----------------------------------------------------------------------------
# Run this FIRST on any new machine. It checks the failure modes people
# actually hit (and the two that this project hit on WSL - see
# docs/wsl-notes.md) and prints the exact remediation command.
#
# USAGE:  bash scripts/doctor.sh
# EXIT:   0 = healthy enough to work, 1 = something will break
# =============================================================================
set -uo pipefail            # NO -e: a failed check must not abort the doctor

cd "$(dirname "${BASH_SOURCE[0]}")/.."   # always diagnose from project root

OK=0; WARN=0; FAIL=0
ok()   { printf '\033[32m[ OK ]\033[0m %s\n' "$*"; OK=$((OK+1)); }
warn() { printf '\033[33m[WARN]\033[0m %s\n' "$*"; WARN=$((WARN+1)); }
bad()  { printf '\033[31m[FAIL]\033[0m %s\n' "$*"; FAIL=$((FAIL+1)); }
fix()  { printf '        \033[2m-> fix: %s\033[0m\n' "$*"; }

echo "================ Ansible environment doctor ================"

# --- 1. Where are we running? ------------------------------------------------
ENV_NAME="unknown OS"
case "$(uname -s)" in
  Linux)  ENV_NAME="Linux" ;;
  Darwin) ENV_NAME="macOS" ;;
esac
if grep -qi microsoft /proc/version 2>/dev/null; then
  ENV_NAME="WSL ($(uname -r))"
elif [[ -f /.dockerenv ]]; then
  ENV_NAME="Docker container"
fi
echo "Environment: ${ENV_NAME}"
echo

# --- 2. Ansible binaries -----------------------------------------------------
if command -v ansible >/dev/null 2>&1; then
  ok "ansible found: $(ansible --version 2>/dev/null | head -1)"
else
  bad "ansible not found on PATH"
  fix "see docs/00-first-steps.md - apt install ansible-core | pipx install ansible-core"
fi
if command -v ansible-playbook >/dev/null 2>&1; then
  ok "ansible-playbook found"
else
  bad "ansible-playbook not found"
fi

# --- 3. Is OUR ansible.cfg actually loaded? ---------------------------------
if [[ -n "${ANSIBLE_CONFIG:-}" ]]; then
  ok "ANSIBLE_CONFIG is set explicitly: ${ANSIBLE_CONFIG}"
fi
CFG_DUMP="$(ansible-config dump --only-changed 2>/dev/null || true)"
# Must match THIS project's file - a stray ~/.ansible.cfg would otherwise
# make this check pass while our project settings stay ignored:
if printf '%s' "${CFG_DUMP}" | grep -qF "${PWD}/ansible.cfg"; then
  ok "project ansible.cfg loaded (CONFIG_FILE = ${PWD}/ansible.cfg)"
else
  bad "project ansible.cfg is NOT loaded - settings (inventory, roles_path...) are ignored"
  fix "quick:  source scripts/env.sh"
  fix "perma:  see docs/wsl-notes.md (/etc/wsl.conf -> options = \"metadata,umask=22,fmask=11\" + wsl --shutdown)"
  OTHER_CFG="$(ansible-config list 2>/dev/null | grep -A1 '^CONFIG_FILE' | tail -1 || true)"
  [[ -n "${OTHER_CFG}" ]] && echo "        (currently: ${OTHER_CFG})"
fi
DIR_MODE="$(stat -c '%a' . 2>/dev/null || echo 'n/a')"
if [[ "${DIR_MODE}" == "777" || "${DIR_MODE}" == "666" ]]; then
  warn "project directory mode is ${DIR_MODE} (world-writable) - ansible skips ./ansible.cfg here"
  fix "this is the classic WSL /mnt/<drive> symptom - docs/wsl-notes.md"
fi

# --- 4. ansible-galaxy health (the stale-packaging crash) -------------------
# Judge by EXIT CODE, not by stderr text: Ansible prints the harmless
# "world writable directory" warning on stderr even when galaxy works.
if ansible-galaxy --version >/dev/null 2>&1; then
  ok "ansible-galaxy runs cleanly"
else
  GALAXY_ERR="$(ansible-galaxy --version 2>&1 || true)"
  if printf '%s' "${GALAXY_ERR}" | grep -q "MutableMapping"; then
    bad "ansible-galaxy crashes: stale packaging/pyparsing in ~/.local shadows system copies"
    fix "mv ~/.local/lib/python3*/site-packages/{packaging,packaging-*.dist-info,pyparsing,pyparsing-*.dist-info} ~/.local_fix_backup_ansible/"
    fix "(documented in docs/wsl-notes.md - backup kept, restorable)"
  else
    bad "ansible-galaxy failed: $(printf '%s' "${GALAXY_ERR}" | tail -1)"
  fi
fi

# --- 5. Python + PyYAML (needed by Ansible on control node) -----------------
if command -v python3 >/dev/null 2>&1; then
  ok "python3: $(python3 --version 2>&1)"
  if python3 -c 'import yaml' 2>/dev/null; then
    ok "PyYAML importable (ansible-inventory --list needs it)"
  else
    bad "PyYAML missing"
    fix "pip3 install --user --break-system-packages pyyaml   (PEP 668 systems)"
  fi
else
  bad "python3 not found"
fi

# --- 6. Linters (optional but recommended) ----------------------------------
command -v yamllint >/dev/null 2>&1 \
  && ok "yamllint: $(yamllint --version 2>&1)" \
  || { warn "yamllint not installed (optional)"; fix "pip3 install --user --break-system-packages yamllint"; }
command -v ansible-lint >/dev/null 2>&1 \
  && ok "ansible-lint: $(ansible-lint --version 2>&1 | head -1)" \
  || { warn "ansible-lint not installed (optional)"; fix "pipx install ansible-lint   (or see docs/00-first-steps.md)"; }

# --- 7. Privilege escalation mode -------------------------------------------
# NOTE: only `sudo -n` (non-interactive) here - `sudo -v` would PROMPT for a
# password and hang this script in non-interactive runs (CI, agents, pipes).
if sudo -n true 2>/dev/null; then
  ok "sudo works without a password (unattended become)"
else
  warn "sudo needs a password - plays with become: true will prompt interactively"
  fix "run playbooks from a terminal so you can type it, or configure NOPASSWD for labs"
fi

# --- 8. git ------------------------------------------------------------------
command -v git >/dev/null 2>&1 \
  && ok "git: $(git --version | awk '{print $3}')" \
  || { warn "git not found - needed for ansible-pull / CI examples"; }

# --- 9. Currently active inventory ------------------------------------------
if ansible-inventory --graph >/dev/null 2>&1; then
  ok "default inventory resolves: $(ansible-inventory --graph 2>/dev/null | head -3 | tail -1 | tr -d ' |')"
else
  warn "default inventory could not be parsed"
  fix "source scripts/env.sh and retry"
fi

# --- Summary ----------------------------------------------------------------
echo
echo "============================================================"
echo "Doctor summary: ${OK} ok, ${WARN} warnings, ${FAIL} failures"
if [[ "${FAIL}" -gt 0 ]]; then
  echo "Resolve the [FAIL] items above, then re-run: bash scripts/doctor.sh"
  exit 1
fi
echo "Healthy enough to work. Next: bash scripts/validate.sh"
exit 0
