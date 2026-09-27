#!/usr/bin/env bash
# =============================================================================
# scripts/galaxy.sh - Ansible Galaxy workflow, expressed as a script
# -----------------------------------------------------------------------------
# WHAT IS GALAXY? galaxy.ansible.com is the package registry for Ansible:
#   * ROLES       reusable automation packaged as a folder structure
#   * COLLECTIONS bundles of modules/plugins/roles/variables (namespace + version)
#
# USAGE (run from anywhere):
#   bash scripts/galaxy.sh install      # install everything in requirements.yml
#   bash scripts/galaxy.sh init NAME    # scaffold roles/NAME with `role init`
#   bash scripts/galaxy.sh list         # what is installed on this machine
#   bash scripts/galaxy.sh info ROLE    # Galaxy metadata for a role
#   bash scripts/galaxy.sh build        # build our local.demo collection tarball
#   bash scripts/galaxy.sh help         # this text
#
# install/build need network access to galaxy.ansible.com.
# =============================================================================
set -euo pipefail

# Operate from the project root no matter where the script was called from:
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Stage banner - so a learner always knows WHICH step is running.
step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
hint() { printf '\033[2m    %s\033[0m\n' "$*"; }

case "${1:-help}" in
  install)
    step "Install ROLES + COLLECTIONS from requirements.yml"
    hint "roles -> ~/.ansible/roles    collections -> ~/.ansible/collections"
    if ansible-galaxy install -r requirements.yml; then
      step "Done. Verify with: bash scripts/galaxy.sh list"
    else
      printf '\033[1;31mInstall failed.\033[0m Common causes:\n' >&2
      hint "no network / galaxy.ansible.com unreachable (try again online)"
      hint "ansible-galaxy broken -> run bash scripts/doctor.sh for diagnosis"
      exit 1
    fi
    ;;

  init)
    # Scaffolds the full role skeleton (tasks/ handlers/ templates/ meta/...)
    # exactly like the roles/ we ship in this project.
    # NOTE: the flag is --init-path (NOT --init-dir) in ansible-core >= 2.11.
    [ -n "${2:-}" ] || { echo "usage: galaxy.sh init <role_name>" >&2; exit 1; }
    step "Scaffold roles/$2 via 'ansible-galaxy role init'"
    ansible-galaxy role init "$2" --init-path roles
    hint "Next: edit roles/$2/{tasks,defaults,meta} then try it from a playbook"
    ;;

  list)
    step "Roles installed on this machine"
    ansible-galaxy role list
    step "Collections installed on this machine"
    ansible-galaxy collection list
    hint "Our practice collection (local.demo) lives in ./collections"
    ;;

  info)
    [ -n "${2:-}" ] || { echo "usage: galaxy.sh info <namespace.rolename>" >&2; exit 1; }
    step "Galaxy metadata for $2"
    ansible-galaxy role info "$2"
    ;;

  build)
    # Build OUR collection into an installable tarball (offline operation!).
    # Output: local-demo-<version>.tar.gz inside the collection directory.
    step "Build collection local.demo -> local-demo-*.tar.gz"
    ( cd collections/ansible_collections/local/demo && ansible-galaxy collection build --force )
    hint "Install it elsewhere with:"
    hint "ansible-galaxy collection install local-demo-1.0.0.tar.gz -p ./collections --force"
    ;;

  *)
    sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    ;;
esac
