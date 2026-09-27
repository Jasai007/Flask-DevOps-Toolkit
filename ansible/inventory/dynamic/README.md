# `inventory/dynamic/` — Dynamic inventories

Static inventories are files you maintain by hand. **Dynamic** inventories
are *generated* — from a JSON file, a cloud API, a CMDB, a database — so
Ansible always sees the machines that currently exist.

This directory ships both styles:

| File | Style | Runs offline? |
|---|---|---|
| `inventory.py` + `hosts.json` | **script** inventory (any language) | ✅ yes |
| `aws_ec2.yml` | **plugin** inventory (`amazon.aws.aws_ec2`) | ❌ needs AWS + creds |

## The script contract (what `inventory.py` implements)

```text
<your-script> --list        ->  ONE JSON document = entire inventory
<your-script> --host NAME   ->  JSON vars for one host ({" "} is fine)
```

`--list` response shape:

```json
{
  "_meta":    { "hostvars": { "web1": {"ansible_host": "192.168.1.10"} } },
  "webservers": { "hosts": ["web1","web2"], "vars": {"web_port": 80} },
  "all_servers": { "children": ["webservers","dbservers"] }
}
```

- `_meta.hostvars` — per-host vars, provided once so Ansible never needs
  `--host` calls (fast path, always do this).
- group `vars` — merged onto member hosts **by Ansible**.
- groups without a parent become children of the implicit `all`.

## Try it step by step

```bash
source scripts/env.sh                 # loads ANSIBLE_* into your shell

# 1. raw script output (what Ansible parses)
python3 inventory/dynamic/inventory.py --list | head -30
python3 inventory/dynamic/inventory.py --host web1

# 2. Ansible's own view
ansible-inventory -i inventory/dynamic/inventory.py --graph
ansible-inventory -i inventory/dynamic/inventory.py --list | less

# 3. run a play against it (playbook targets group 'local' = localhost)
ansible-playbook -i inventory/dynamic/inventory.py playbooks/21_dynamic_inventory.yml

# 4. see fleet groups without touching them
ansible-playbook -i inventory/dynamic/inventory.py \
    playbooks/21_dynamic_inventory.yml --list-hosts
```

## Editing the data

`hosts.json` holds **all** content (hosts, groups, vars); `inventory.py` is
just the adapter. Add a host → edit `hosts` **and** add it to a group in
`groups`. Re-run `--graph` to confirm.

## Variable scoping gotcha

Group/host vars are only auto-loaded from `group_vars/` **next to the
inventory source**. With `-i inventory/dynamic/inventory.py`, Ansible looks
in `inventory/dynamic/group_vars/` (which does not exist) — the static
project's `inventory/group_vars/` applies only to the static inventory.
That is why `hosts.json` carries its own `common_vars`.

## Plugin inventory (`aws_ec2.yml`)

Declarative YAML consumed by an inventory plugin shipped in a collection:

```bash
ansible-galaxy collection install -r requirements.yml   # pulls amazon.aws
ansible-inventory -i inventory/dynamic/aws_ec2.yml --graph
```

See the comments inside `aws_ec2.yml` for `regions`, `filters`,
`keyed_groups`, `compose` and `hostnames`.

## When to choose which

- **script**: bespoke data sources (CMDB, IPAM, internal API), full control,
  any language as long as it prints JSON.
- **plugin**: cloud/official sources, no caching logic to write, maintained
  by the collection authors.
