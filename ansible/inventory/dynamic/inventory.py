#!/usr/bin/env python3
"""ANSIBLE SCRIPT DYNAMIC INVENTORY - the contract in one place.

Ansible treats any executable passed via ``-i`` that answers these two
questions as an inventory source:

``--list``      print ONE JSON document describing the ENTIRE inventory:
                {
                  "_meta": {"hostvars": { "<host>": {..vars..}, ... }},
                  "<group>": {"hosts": [..], "children": [..], "vars": {..}},
                  ...
                }
``--host NAME``  print ONLY the vars of that host as JSON (``{}`` is legal;
                when ``_meta.hostvars`` is provided this is rarely called).

DESIGN NOTES (why it looks like this):
  * The Python here is deliberately dumb - ALL content lives in hosts.json
    next to this file, so learners edit JSON, not code.
  * ``_meta.hostvars`` is the efficient form: one ``--list`` call answers
    everything; Ansible caches it and never needs ``--host``.
  * ``common_vars`` from hosts.json are merged into every host here;
    GROUP vars are declared under "groups" and merged by Ansible itself.

TRY IT (from the project root):
    python3 inventory/dynamic/inventory.py --list | head
    python3 inventory/dynamic/inventory.py --host web1
    ansible-inventory -i inventory/dynamic/inventory.py --graph
    ansible-inventory -i inventory/dynamic/inventory.py --list
    ansible-playbook -i inventory/dynamic/inventory.py playbooks/21_dynamic_inventory.yml
"""

from __future__ import absolute_import, division, print_function

import json
import os
import sys

__metaclass__ = type

# The data file lives NEXT TO this script - find it relative to our own
# location so the inventory works no matter which directory you call it from.
HERE = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(HERE, "hosts.json")

USAGE = (
    "usage: inventory.py --list            # whole inventory as JSON\n"
    "       inventory.py --host <name>     # vars of one host as JSON\n"
)


def load_data():
    """Read and parse hosts.json (single source of truth for this inventory)."""
    if not os.path.exists(DATA_FILE):
        sys.stderr.write("ERROR: data file not found: %s\n" % DATA_FILE)
        sys.exit(2)
    with open(DATA_FILE, "r") as data_file:
        return json.load(data_file)


def build_hostvars(data):
    """Return {hostname: {var: value}} = common_vars + per-host vars.

    Group vars are NOT included here - groups carry their own "vars" key in
    the --list response and Ansible merges them onto member hosts itself.
    """
    common = data.get("common_vars", {})
    hostvars = {}
    for hostname, host_vars in data.get("hosts", {}).items():
        merged = dict(common)      # shallow copy - never mutate the source
        merged.update(host_vars)   # per-host values win over common values
        hostvars[hostname] = merged
    return hostvars


def build_inventory(data):
    """Compose the complete --list response from hosts.json."""
    inventory = {
        # Ansible skips --host round trips when _meta.hostvars is present.
        "_meta": {"hostvars": build_hostvars(data)},
    }
    for group_name, group in data.get("groups", {}).items():
        entry = {}
        if "hosts" in group:
            entry["hosts"] = group["hosts"]
        if "children" in group:
            entry["children"] = group["children"]
        if "vars" in group:
            entry["vars"] = group["vars"]
        inventory[group_name] = entry
    # Groups that nobody references as a child become direct children of the
    # implicit top-level group "all" - that is how webservers/dbservers/local
    # show up under @all in `ansible-inventory --graph`.
    return inventory


def main():
    """Entry point - exactly two accepted invocations (see module docstring)."""
    args = sys.argv[1:]
    data = load_data()

    if args == ["--list"]:
        print(json.dumps(build_inventory(data), indent=2, sort_keys=True))
    elif len(args) == 2 and args[0] == "--host":
        hostvars = build_hostvars(data)
        # Unknown host -> {} is a valid answer, never crash the inventory.
        print(json.dumps(hostvars.get(args[1], {}), indent=2, sort_keys=True))
    else:
        sys.stderr.write(USAGE)
        sys.exit(1)


if __name__ == "__main__":
    main()
