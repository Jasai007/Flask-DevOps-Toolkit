# Roles — packaging automation for reuse

> **Goal:** understand the role skeleton, variable priority inside it, how
> roles compose (dependencies), and static vs dynamic usage.
> Playbooks: `18_roles.yml`, `19_dynamic_roles.yml`.

---

## Why roles

A playbook past ~100 lines becomes unreviewable. A role turns it into a
**contract with a fixed layout** that anyone can consume without reading
your code first:

```text
roles/webserver/
├── defaults/main.yml    WEAK variables  → operators override these
├── vars/main.yml        STRONG variables → OS truth, rarely overridden
│   ├── Debian.yml        (loaded conditionally in this project)
│   ├── RedHat.yml
│   └── default.yml       fallback
├── tasks/main.yml       the work (entry point, runs top→bottom)
├── handlers/main.yml    notified, once-per-play, defined-order
├── templates/           Jinja2 files (template module resolves HERE)
├── files/               static files (copy module resolves HERE)
├── meta/main.yml        galaxy_info + dependencies
├── tests/test.yml       standalone smoke test
└── README.md            the contract: variables + usage
```

Path resolution is what makes `src: index.html.j2` "just work": module file
lookups search the **role's** directory first.

## Variable priority (the part everyone gets wrong)

Highest wins:

```text
-e extra vars  >  task vars  >  role vars/main.yml  >  play vars
>  inventory group_vars/host_vars  >  role defaults/main.yml   ← weakest
```

Design rule enforced in this project:

- **defaults/** = anything a site might differ on (`app_user`, ports,
  package lists) — override with `-e`, no role edits.
- **vars/** = non-negotiable truth per OS family (`common_packages`) —
  deliberately high priority.

```bash
ansible-playbook playbooks/18_roles.yml -e app_user=alice        # override
ansible-playbook playbooks/18_roles.yml -e webserver_package=apache2 \
                                   -e webserver_service=httpd     # swap webserver
```

## Dependencies

`roles/webserver/meta/main.yml`:

```yaml
dependencies:
  - role: common
```

Requesting `webserver` silently inserts `common` in front (recursively — a
dependency's dependencies run first). You never have to remember bootstrap
order.

## Static vs dynamic usage (`18` vs `19`)

| | `import_role` (static) | `include_role` (dynamic) |
|---|---|---|
| resolved | at playbook **parse** time | at **run** time |
| equivalent to | copy-paste of the role's tasks | a task that executes the role |
| `when:` | applies to each imported task | applies to the include |
| `loop:` | ❌ cannot loop | ✅ can loop |
| own `vars:` | merges into play scope | scoped to the include |
| tags | propagate to tasks | land on the *include* unless `apply:` is used |

`apply:` placement is a classic syntax trap (caught by `--syntax-check`):

```yaml
- ansible.builtin.include_role:
    name: webserver
    apply:            # ← INSIDE the module's mapping
      tags: [web]
  when: deploy_webserver | bool
```

## Run them

```bash
source scripts/env.sh

ansible-playbook playbooks/18_roles.yml                # both roles
ansible-playbook playbooks/18_roles.yml --tags webserver
ansible-playbook playbooks/18_roles.yml --list-tasks
ansible-playbook playbooks/19_dynamic_roles.yml        # import vs include
ansible-playbook playbooks/19_dynamic_roles.yml -e deploy_webserver=false
ansible-playbook roles/webserver/tests/test.yml        # role in isolation
```

**Note:** role tasks carry their own `become: true` (roles must be
self-contained), so the *plays* don't need play-level become and
`site.yml --tags validate` runs without sudo.

## Create your own (two ways)

```bash
# scaffolded (full skeleton generated for you):
bash scripts/galaxy.sh init myrole          # ansible-galaxy role init --init-path roles

# or study/copy the two we ship:
#   roles/common    - baseline (OS vars pattern, no dependencies)
#   roles/webserver - service (templates, handlers, dependency on common)
```

## Checklist before you publish a role

- [ ] `defaults/` covers everything a consumer might change
- [ ] `meta/main.yml` complete: `galaxy_info` (platforms, license, min version) + dependencies
- [ ] `README.md` documents every variable with defaults (table format)
- [ ] `tests/test.yml` runs standalone
- [ ] tasks are idempotent → second run shows `changed=0`
- [ ] handlers for every service restart; never restart inline
- [ ] FQCN modules only (`ansible.builtin.*`)

**Next:** [galaxy.md](galaxy.md) — sharing and consuming roles at scale.
