# Ansible Galaxy — the package registry for automation

> **Goal:** consume and publish reusable automation: roles *and* collections,
> with reproducible dependencies via `requirements.yml`.
> Tooling: `scripts/galaxy.sh`, `requirements.yml`.

---

## What Galaxy is

[galaxy.ansible.com](https://galaxy.ansible.com) hosts two artifact types:

| Artifact | Contains | Addressed as |
|---|---|---|
| **role** | playbook logic (tasks/handlers/templates) | `author.rolename` |
| **collection** | plugins: modules, filters, lookups, roles... | `namespace.name` (FQCN root) |

Both are installed by the single entry point:

```bash
ansible-galaxy --help        # role | collection subcommands underneath
```

> Heads-up for this machine: if this command ever crashes with
> `AttributeError ... MutableMapping`, see [wsl-notes.md](wsl-notes.md) §2.

---

## 1. Scaffold a role (offline operation)

```bash
bash scripts/galaxy.sh init myrole
# = ansible-galaxy role init myrole --init-path roles
find roles/myrole -type d
# roles/myrole/{tasks,handlers,templates,files,vars,defaults,meta,tests}
```

The generated `meta/main.yml` + `defaults/main.yml` are exactly what
[roles.md](roles.md) says Galaxy expects. Compare the scaffold with
`roles/webserver/` — ours, annotated.

## 2. Install dependencies from `requirements.yml` (network)

One file, two sections — this is your project's *lockfile*:

```yaml
roles:                                # author.rolename
  - name: geerlingguy.nginx
    version: "3.1.4"                  # PIN for reproducibility
collections:                          # namespace.name
  - name: community.general
    version: ">=8.0.0"                # ranges allowed
```

```bash
bash scripts/galaxy.sh install
# = ansible-galaxy install -r requirements.yml
#   roles       -> ~/.ansible/roles        (see roles_path in ansible.cfg)
#   collections -> ~/.ansible/collections  (see collections_path)
```

**Verify:**

```bash
bash scripts/galaxy.sh list            # ansible-galaxy role list + collection list
ansible-doc community.general.timezone # any installed plugin is now doc-able
```

Other useful commands (also wrapped by `galaxy.sh`):

```bash
ansible-galaxy role info geerlingguy.nginx      # metadata before you install
ansible-galaxy collection list                  # where things resolved from
ansible-galaxy install -r requirements.yml --force   # refresh pins
```

## 3. Build & install a collection (offline)

Our practice collection `local.demo` builds to a tarball:

```bash
bash scripts/galaxy.sh build
# -> collections/ansible_collections/local/demo/local-demo-1.0.0.tar.gz

ansible-galaxy collection install local-demo-1.0.0.tar.gz -p ./collections --force
```

See [collections.md](collections.md) for the full collection lifecycle.

## 4. Publish (when you're ready to share)

```text
1. register a NAMESPACE on galaxy.ansible.com (claim once, yours forever)
2. git push your role/collection to a public repo
3. roles:      "Import Repository" on the Galaxy site UI (or CLI import)
   collections: ansible-galaxy collection publish <tarball> --token <API key>
4. consumers then run: ansible-galaxy <role|collection> install <ns>.<name>
```

Versioning rules of thumb: bump **patch** for fixes, **minor** for new
variables/tasks (backwards compatible), **major** when defaults/behaviour
change. Always note `min_ansible_version` in `meta/main.yml`.

## 5. Version pinning — why it matters

Unpinned installs mean every machine gets a *different* automation fleet on
different days — the classic "works on my machine" generator. Pin exact
versions in shared/CI environments; ranges are acceptable while exploring.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `ERROR! - none of the requirements specified...` (network) | offline / firewalled | skip install; project works without Galaxy adds |
| role installs but won't load | not on `roles_path` | `source scripts/env.sh`, check `ansible-config dump` |
| collection not found (FQCN error) | `collections_path` missing `~/.ansible/collections` | this project's `ansible.cfg` already lists it — verify cfg loaded |
| `--init-dir` unknown option | flag renamed | use `--init-path` (fixed in `galaxy.sh`) |

## Try it yourself

1. `bash scripts/galaxy.sh info geerlingguy.nginx` — read the description
   *before* installing (good habit).
2. Pin `community.general` to an exact version in `requirements.yml`.
3. Build `local.demo`, install the tarball into `/tmp/collections`, and run
   `ANSIBLE_COLLECTIONS_PATH=/tmp/collections ansible-doc local.demo.host_summary`.

**Next:** [collections.md](collections.md).
