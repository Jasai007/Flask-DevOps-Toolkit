# Collections — the packaging unit for plugins

> **Goal:** understand FQCN addressing, the collection layout, and build a
> working custom module + filter (both ship with this project).
> Playbook: `20_collections.yml`. Collection: `collections/ansible_collections/local/demo/`.

---

## Roles vs collections (the confusion, ended)

```text
role       → reusable PLAYBOOK LOGIC        (tasks/handlers/templates)
collection → PACKAGING FORMAT for plugins   (modules, filters, lookups,
             inventory plugins, roles, docs) under one namespace + version
```

Everything modern is addressed **FQCN** (Fully Qualified Collection Name):

```text
ansible.builtin.debug        namespace.collection.plugin   ^-- always present
local.demo.human_size        ours (committed to this repo)
community.general.timezone   from Galaxy
└───┴──┘└──┴──┘
 ns    collection  plugin
```

## Anatomy of a collection

The **path is the identity** — Ansible derives the FQCN from it:

```text
collections/                      <- one entry of collections_path
└── ansible_collections/          <- fixed directory name
    └── local/                    <- namespace
        └── demo/                 <- collection name  → FQCN prefix local.demo
            ├── galaxy.yml        BUILD metadata (version, license, author)
            ├── README.md
            ├── meta/runtime.yml  RUNTIME contract (requires_ansible: ">=2.14")
            └── plugins/
                ├── modules/host_summary.py   → local.demo.host_summary
                └── filter/human_size.py      → local.demo.human_size
```

Discovery: `ansible.cfg` sets `collections_path = ./collections:~/.ansible/collections`.

## Our custom MODULE — `host_summary`

Modules are small Python programs Ansible ships to the target and runs there.
Read the annotated source: `collections/ansible_collections/local/demo/plugins/modules/host_summary.py`

The four rules it demonstrates:

1. **`DOCUMENTATION` / `EXAMPLES` / `RETURN` docstrings** — these *power*
   `ansible-doc`; without them your plugin is undocumented.
2. **`argument_spec`** — declare options so bad input dies before your code:

   ```python
   module = AnsibleModule(argument_spec=dict(), supports_check_mode=True)
   ```

3. **`exit_json` / `fail_json`** — the only two ways out; include diagnostics.
4. **`changed=False` for read-only work** — lying about `changed` breaks
   handlers, `--diff` and your teammates' trust.

Stdlib-only imports (`socket`, `platform`, `os`, `getpass`) = runs on Linux,
macOS, Windows and WSL targets without pip installs.

```bash
# three ways to invoke it (all verified on this machine):
ansible-playbook playbooks/20_collections.yml
ansible localhost -i inventory/hosts -m local.demo.host_summary
ansible-doc local.demo.host_summary        # renders our docstring
```

## Our custom FILTER — `human_size`

Filters transform **values** in Jinja. A filter plugin is a class exposing a
`filters()` dict — name in templates → Python callable:

```python
class FilterModule(object):
    def filters(self):
        return {"human_size": human_size}
```

Used in playbooks/20 (verified outputs):

```jinja
{{ 1536000 | local.demo.human_size }}              → "1.5 MB"
{{ 1536000 | local.demo.human_size(binary=true) }} → "1.5 MiB"
{{ 1536000 | local.demo.human_size(precision=2) }} → "1.54 MB"
```

## Build → ship → install

```bash
bash scripts/galaxy.sh build
# -> local-demo-1.0.0.tar.gz   (namespace-name-version.tar.gz)
ansible-galaxy collection install local-demo-1.0.0.tar.gz -p ./collections --force
```

`galaxy.yml`'s `build_ignore:` keeps tarballs out of the next build; the
project `.gitignore` keeps them out of git.

## Consuming other people's collections

```bash
ansible-galaxy install -r requirements.yml      # community.general, ansible.posix, amazon.aws
ansible-doc -t callback -l                      # e.g. community.general.yaml callback
```

Then enable pretty output in `ansible.cfg`:

```ini
stdout_callback = community.general.yaml
```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `couldn't resolve module/local.demo...` | `collections_path` not loaded | `source scripts/env.sh`; check `ansible-config dump` |
| filter unknown in Jinja | needs FQCN on the right of `\|` | `x \| local.demo.human_size` not `x \| human_size` |
| `requires_ansible` error | core too old | upgrade ansible-core or lower `meta/runtime.yml` |
| `ansible-doc` empty | missing `DOCUMENTATION` block | copy the structure from `host_summary.py` |

## Try it yourself

1. Add a `disk_summary` module: reuse `host_summary.py` structure, return
   `shutil.disk_usage('/')`. Invoke it ad-hoc.
2. Extend `human_size` with a `bits=true` option (multiply by 8).
3. `ansible-playbook playbooks/20_collections.yml --check` — why does the
   custom module still run under `--check`? (hint: `supports_check_mode`)

**Next:** [dynamic-inventory.md](dynamic-inventory.md).
