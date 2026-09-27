#!/usr/bin/python
# -*- coding: utf-8 -*-
# =============================================================================
# local.demo.host_summary - custom Ansible MODULE (collection plugin)
# -----------------------------------------------------------------------------
# A module is a standalone Python program that Ansible copies to the target
# host and runs there. Rules of the game:
#   * accept args via argument_spec, report via exit_json()/fail_json()
#   * NEVER claim "changed" for read-only work
#   * use only the standard library if you want it to run EVERYWHERE
#     (Linux, macOS, Windows, WSL - no pip installs on targets!)
#
# TRY IT (from the project root, after `source scripts/env.sh`):
#   ansible-playbook playbooks/20_collections.yml
#   ansible localhost -i inventory/hosts -m local.demo.host_summary
#   ansible-doc local.demo.host_summary        # DOCUMENTATION below powers this
# =============================================================================
from __future__ import absolute_import, division, print_function

__metaclass__ = type

DOCUMENTATION = r"""
---
module: host_summary
short_description: Collect a small, cross-platform summary of the host
version_added: "1.0.0"
description:
  - Returns hostname, platform, Python version, user and CPU count.
  - Written as teaching material for this project - pure standard library,
    therefore portable across operating systems.
options: {}
author:
  - Ansible Hands-On Project
"""

EXAMPLES = r"""
# In a playbook (FQCN - fully qualified collection name):
- name: Collect a summary of localhost
  local.demo.host_summary:
  register: result

- name: Show it
  ansible.builtin.debug:
    msg: "{{ result.summary }}"

# Ad-hoc, straight from the shell:
#   ansible localhost -i inventory/hosts -m local.demo.host_summary
"""

RETURN = r"""
summary:
  description: Facts collected about the host.
  returned: always
  type: dict
  contains:
    hostname:
      description: Short host name.
      type: str
      sample: devbox
    platform:
      description: Detailed OS/platform string.
      type: str
      sample: Linux-6.6.87-x86_64-with-glibc2.39
    python_version:
      description: Version of Python that executed the module.
      type: str
      sample: 3.12.3
    user:
      description: User the module ran as.
      type: str
      sample: ansible
    cpu_count:
      description: Number of logical CPUs.
      type: int
      sample: 4
msg:
  description: Human readable result message.
  type: str
  returned: always
"""

import getpass
import os
import platform
import socket

from ansible.module_utils.basic import AnsibleModule


def collect_summary():
    """Gather safe, read-only host facts using the standard library only."""
    return {
        "hostname": socket.gethostname(),
        "fqdn": socket.getfqdn(),
        "platform": platform.platform(),
        "system": platform.system(),
        "python_version": platform.python_version(),
        "user": getpass.getuser(),
        "cpu_count": os.cpu_count(),
    }


def main():
    """Entry point - every Ansible module ends in exit_json() or fail_json()."""
    # argument_spec declares the options this module accepts. Ours takes none,
    # but declaring it explicitly is what lets Ansible validate (and reject)
    # bad input before your code even runs.
    module = AnsibleModule(
        argument_spec=dict(),
        supports_check_mode=True,   # we only READ state -> safe under --check
    )

    try:
        summary = collect_summary()
    except Exception as exc:                        # noqa: BLE001
        # fail_json is the module equivalent of "task failed" - include enough
        # detail for a human to diagnose without re-running in debug mode.
        module.fail_json(msg="Could not collect host summary: %s" % exc)

    # changed=False - we inspected state without modifying anything. Claiming
    # a change here would lie to handlers, --diff and your teammates.
    module.exit_json(
        changed=False,
        msg="Host summary collected.",
        summary=summary,
    )


if __name__ == "__main__":
    main()
