# Dynamic Inventory — hosts generated at runtime

> **Goal:** consume inventories that come from *code or APIs* instead of hand
> maintenance. Playbook: `21_dynamic_inventory.yml`.
> Deep-dive companion: [`inventory/dynamic/README.md`](../inventory/dynamic/README.md).

---

## Why

Static files are fine for labs; fleets change (autoscaling, DHCP, CMDB
records). A **dynamic inventory** re-generates the host list on every query,
so Ansible always sees reality.

## The two styles

```text
SCRIPT inventory                 PLUGIN inventory
inventory.py (any language)      aws_ec2.yml (declarative YAML)
answers --list / --host          runs INSIDE ansible, talks to the API
you build groups/vars yourself   keyed_groups/compose built in
✔ ships in this repo (offline)   ✔ no caching/grouping code to write
```

## The script contract

```text
<executable> --list      → ONE JSON: { "_meta": {hostvars}, group: {...} }
<executable> --host NAME → vars of one host ({} is valid with _meta present)
```

Annotated example (what `inventory.py` assembles from `hosts.json`):

```json
{
  "_meta": { "hostvars": { "web1": {"ansible_host": "192.168.1.10"} } },
  "webservers":  { "hosts": ["web1","web2"], "vars": {"web_port": 80} },
  "dbservers":   { "hosts": ["db1"] },
  "all_servers": { "children": ["webservers","dbservers"] }
}
```

Efficiency rule: always emit `_meta.hostvars` → Ansible never needs per-host
`--host` round trips.

## Step-by-step (verified on this machine)

```bash
source scripts/env.sh

# 1. raw contract
python3 inventory/dynamic/inventory.py --list | head -30
python3 inventory/dynamic/inventory.py --host web1

# 2. Ansible's view
ansible-inventory -i inventory/dynamic/inventory.py --graph
```

Expected graph:

```text
@all:
|--@ungrouped:
|--@all_servers:
|  |--@webservers:
|  |  |--web1
|  |  |--web2
|  |--@dbservers:
|     |--db1
|--@local:
   |--localhost
```

# 3. run a play (targets group 'local' = localhost, always safe)
ansible-playbook -i inventory/dynamic/inventory.py playbooks/21_dynamic_inventory.yml

# 4. inspect the fleet WITHOUT connecting
ansible-playbook -i inventory/dynamic/inventory.py \
    playbooks/21_dynamic_inventory.yml --list-hosts
ansible-playbook -i inventory/dynamic/inventory.py \
    playbooks/21_dynamic_inventory.yml --limit dbservers --list-hosts
```

**Observe in 21:** `inventory_source`/`managed_by` come from `hosts.json`
`common_vars`; `meta: refresh_inventory` re-reads the source mid-play (used
by long plays against autoscaling fleets); `groups` after refresh lists
`all, all_servers, dbservers, local, ungrouped, webservers`.

## Variable scoping gotcha

`group_vars/` is loaded **next to its inventory source**:

```text
-i inventory/hosts                  → inventory/group_vars/* applies
-i inventory/dynamic/inventory.py   → inventory/dynamic/group_vars/* would apply
                                      (does not exist → vars come from hosts.json)
```

Keep variables with their source; do not expect the static `group_vars/` to
follow you into a different inventory.

## Plugin inventory (`aws_ec2.yml` — reference)

```bash
ansible-galaxy collection install -r requirements.yml   # pulls amazon.aws
export AWS_PROFILE=your-profile                          # or env keys
ansible-inventory -i inventory/dynamic/aws_ec2.yml --graph
```

Key directives (heavily commented in the file):

| Directive | Purpose |
|---|---|
| `plugin:` | which plugin parses this file |
| `regions`, `filters` | server-side selection (only running prod instances) |
| `hostnames` | which address Ansible shows/uses (fallback chain) |
| `keyed_groups` | auto-create groups per tag/region (`role_frontend`, ...) |
| `compose` | per-host vars from Jinja over instance attributes |

## Choosing

| Situation | Use |
|---|---|
| internal CMDB/API, any language | **script** |
| AWS/GCP/Azure/VMware/vCenter... | **plugin** (collection-maintained) |
| static lab (this project's default) | plain `inventory/hosts` |

## Try it yourself

1. Add `web3` to `hosts.json` (both `hosts` and `webservers`) → re-run
   `--graph`.
2. Give `db1` a var `db_engine: postgres` and print it in playbook 21 with
   `{{ hostvars['db1'].db_engine | default('n/a') }}`.
3. Write a 20-line script inventory that emits hosts from `getent group
   wheel` (or `kubectl get nodes`) — any JSON per the contract works.

**Next:** [reusable-automation.md](reusable-automation.md).
