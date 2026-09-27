# Ansible Hands-On Reference Project

A complete, heavily commented, **runnable** Ansible learning project:
foundations → advanced fundamentals → **Roles → Ansible Galaxy →
Collections → Dynamic Inventory → Reusable Automation** — every playbook
carries its own header (what / why / how to run / what you'll learn) and every
guide follows the same step-by-step template.

Works as a localhost lab (no servers needed) and doubles as a reference for
real fleets.

---

## Quick start

```bash
# 0) sanity: is this machine able to run the project?
bash scripts/doctor.sh

# 1) load project settings into your shell (mandatory on WSL /mnt/*,
#    harmless everywhere else):
source scripts/env.sh

# 2) prove the whole project is healthy (25 playbooks + inventories + vault):
bash scripts/validate.sh

# 3) run something:
ansible-playbook playbooks/01_basic_command.yml    # first playbook
ansible-playbook playbooks/22_selftest.yml          # environment self-test
ansible-playbook site.yml --tags validate           # fast entry-point gate
```

**Prerequisites:** `ansible-core` ≥ 2.14 on a Linux/macOS/WSL control node —
install matrix and troubleshooting: **[docs/00-first-steps.md](docs/00-first-steps.md)**.

> **WSL users:** your `/mnt/<drive>` mount hides `./ansible.cfg` and can
> break `ansible-galaxy` — both are already handled/diagnosed by
> `scripts/env.sh` + `scripts/doctor.sh`; details and the permanent fix are
> in **[docs/wsl-notes.md](docs/wsl-notes.md)**.

---

## Learning path (do them in order)

| # | Playbook | You learn | Guide |
|---|---|---|---|
| 01 | `01_basic_command.yml` | ad-hoc → playbook, task ordering | [01-foundations](docs/01-foundations.md) |
| 02 | `02_create_user.yml` | idempotence | 〃 |
| 03 | `03_install_package.yml` | package module, `ansible-doc` | 〃 |
| 04 | `04_manage_service.yml` | service lifecycle, `enabled` | 〃 |
| 05 | `05_copy_files.yml` | files, `--check --diff`, `mode` | 〃 |
| 06 | `06_variables.yml` | variable precedence, `-e` | 〃 |
| 07 | `07_conditionals.yml` | `when` | 〃 |
| 08 | `08_loops.yml` | `loop` / `item` | 〃 |
| 09 | `09_handlers.yml` | notify → handler (event-driven) | 〃 |
| 10 | `10_template.yml` | Jinja2 templates | 〃 |
| 11 | `11_complete_webserver.yml` | everything combined | 〃 |
| 12 | `12_tags.yml` | tags, `always`, `--list-tags` | [02-advanced](docs/02-advanced-fundamentals.md) |
| 13 | `13_blocks.yml` | block / rescue / always | 〃 |
| 14 | `14_error_handling.yml` | `failed_when`, `changed_when`, `retries/until` | 〃 |
| 15 | `15_filters_lookups.yml` | filters vs lookups | 〃 |
| 16 | `16_vault.yml` | encrypted secrets, `no_log` | 〃 (+ [vault/README](vault/README.md)) |
| 17 | `17_advanced_execution.yml` | `delegate_to`, `run_once`, `serial`, `throttle` | 〃 |
| 18 | `18_roles.yml` | roles, dependencies, overrides | [roles](docs/roles.md) |
| 19 | `19_dynamic_roles.yml` | `import_role` vs `include_role`, `apply` | 〃 |
| — | `requirements.yml` + `galaxy.sh` | Galaxy install/init/publish | [galaxy](docs/galaxy.md) |
| 20 | `20_collections.yml` | FQCN, custom module + filter | [collections](docs/collections.md) |
| 21 | `21_dynamic_inventory.yml` | script & plugin inventories | [dynamic-inventory](docs/dynamic-inventory.md) |
| 22 | `22_selftest.yml` | environment gating | 〃 |
| — | `site.yml` | entry point, `import_playbook`, CI, pull | [reusable-automation](docs/reusable-automation.md) |
| — | `pull.yml` | `ansible-pull` mode | 〃 |

---

## Project structure (what lives where — and why)

```text
ansible/
├── README.md                  ← you are here (index + quick start)
├── ansible.cfg                project settings, every line commented
├── site.yml                   ONE entry point: composes playbooks via import_playbook
├── requirements.yml           external roles + collections (the "lockfile")
├── .yamllint.yml              YAML style rules
├── .ansible-lint              Ansible best-practice rules
├── .gitattributes             force LF endings (WSL/Linux safety)
├── .gitignore                 secrets/caches/build artifacts stay out
│
├── playbooks/                 01→22 curriculum + pull.yml (each self-documenting)
├── roles/
│   ├── common/                baseline: OS vars, user, dirs, packages
│   └── webserver/             nginx + template + handler; depends on common
│
├── collections/
│   └── ansible_collections/local/demo/    OUR practice collection
│       ├── galaxy.yml                    (module + filter, fully commented)
│       └── plugins/{modules,filter}/
│
├── inventory/
│   ├── hosts                  default: localhost (remote examples commented)
│   ├── hosts.example          template for real fleets + host-pattern syntax
│   ├── group_vars/            variables for groups  (all.yml, webservers.yml)
│   ├── host_vars/             variables for single hosts (localhost.yml)
│   └── dynamic/               SCRIPT inventory (inventory.py + hosts.json)
│       └── aws_ec2.yml        PLUGIN inventory reference (needs AWS + creds)
│
├── vault/                     ENCRYPTED demo secrets (ansible-vault, safe to commit)
├── files/                     static files for copy module
├── templates/                 shared Jinja2 templates
│
├── scripts/
│   ├── doctor.sh              environment diagnosis + printed fixes
│   ├── env.sh                 export ANSIBLE_* (works on world-writable dirs)
│   ├── validate.sh            one-command health check of everything
│   ├── galaxy.sh              galaxy workflow: install/init/list/info/build
│   └── vault_pass_demo.txt    PUBLIC demo password (password *script*)
│
├── docs/                      step-by-step guides (see index below)
└── .github/workflows/         CI: yamllint + ansible-lint + syntax-check
```

---

## How Ansible works (the mental model)

```text
Inventory          Playbook           Tasks           Modules
(who)      →       (where/root)  →    (what order) →  (how it's done)
   ↓                    ↓                                    ↓
group/host vars     hosts: + become:                    check state
                                                             ↓
                                               changed? → report results
                                                             ↓
                                                    handlers (if notified)
                                                             ↓
                                                     PLAY RECAP
```

Common results: `ok` (already correct), `changed` (modified), `failed`,
`skipped`, `unreachable`, `rescued` (block recovered), `ignored`
(`ignore_errors`).

### Basic playbook syntax

```yaml
---
- name: Example play
  hosts: local            # inventory target(s)
  become: true            # run tasks as root
  vars:
    example: value        # play-level variables
  tasks:
    - name: Example task
      ansible.builtin.debug:        # FQCN: namespace.collection.module
        msg: "Hello {{ example }}"
```

---

## The five advanced pillars (this project's second half)

| Pillar | Where | One-liner |
|---|---|---|
| **Roles** | `roles/`, playbooks 18–19, [docs/roles.md](docs/roles.md) | package tasks/handlers/templates into a reusable, parameterised unit |
| **Ansible Galaxy** | `requirements.yml`, `scripts/galaxy.sh`, [docs/galaxy.md](docs/galaxy.md) | install/publish roles & collections; pin versions like a lockfile |
| **Collections** | `collections/.../local/demo`, playbook 20, [docs/collections.md](docs/collections.md) | the plugin packaging format; ship your own module + filter (FQCN) |
| **Dynamic Inventory** | `inventory/dynamic/`, playbook 21, [docs/dynamic-inventory.md](docs/dynamic-inventory.md) | hosts from code/APIs: script contract + cloud plugin reference |
| **Reusable Automation** | `site.yml`, `pull.yml`, CI, [docs/reusable-automation.md](docs/reusable-automation.md) | one entry point, tags as API, ansible-pull, CI quality gate |

---

## Documentation index

| Guide | Contents |
|---|---|
| [docs/00-first-steps.md](docs/00-first-steps.md) | install matrix, doctor, first commands, troubleshooting |
| [docs/01-foundations.md](docs/01-foundations.md) | playbooks 01–11 explained |
| [docs/02-advanced-fundamentals.md](docs/02-advanced-fundamentals.md) | playbooks 12–17 explained |
| [docs/roles.md](docs/roles.md) | role anatomy, priority, dependencies, static vs dynamic |
| [docs/galaxy.md](docs/galaxy.md) | init/install/list/info/publish, version pinning |
| [docs/collections.md](docs/collections.md) | FQCN, build/install, writing modules & filters |
| [docs/dynamic-inventory.md](docs/dynamic-inventory.md) | script contract, plugin style, variable scoping |
| [docs/reusable-automation.md](docs/reusable-automation.md) | site.yml, pull mode, CI patterns |
| [docs/environments.md](docs/environments.md) | config precedence, control-node matrix, portability |
| [docs/wsl-notes.md](docs/wsl-notes.md) | this machine's 3 real bugs + verified fixes |
| [docs/cheatsheet.md](docs/cheatsheet.md) | every command, grouped |
| inventory + role + collection READMEs | scoped detail next to the code |

---

## Useful commands

```bash
# validation
bash scripts/doctor.sh                     # machine diagnosis (prints fixes)
bash scripts/validate.sh                   # 25 playbooks + inventories + vault
ansible-playbook --syntax-check <pb>       # single playbook
ansible-playbook --list-tasks --list-hosts <pb>

# preview before touching anything
ansible-playbook --check --diff <pb>

# module / plugin documentation
ansible-doc ansible.builtin.copy
ansible-doc local.demo.host_summary        # OUR custom module
ansible-doc -t callback -l                 # output callbacks (yaml, timer...)

# inventories
ansible-inventory --graph
ansible-inventory -i inventory/dynamic/inventory.py --graph

# the whole thing
ansible-playbook site.yml                  # apply (needs sudo for real changes)
ansible-playbook site.yml --tags validate  # gate, root-free
```

---

## Extending this project

1. **New tier?** → `playbooks/23_<tier>.yml` + one `import_playbook` line in `site.yml`.
2. **New target OS?** → add `roles/common/vars/<Family>.yml` (auto-detected).
3. **Real servers?** → `cp inventory/hosts.example inventory/hosts`, fill in, `ansible all -m ping`.
4. **Cloud fleet?** → wire `inventory/dynamic/aws_ec2.yml` (see its comments).
5. **Team secrets?** → real Vault password outside the repo + CI secret store.
6. **Quality gate?** → enable `.github/workflows/ansible.yml` in your fork.

---

## Status / validation

Everything in this repo was executed against `ansible-core 2.16.3` (WSL2,
Ubuntu 24.04) while building it:

- `bash scripts/validate.sh` → **VALIDATION PASSED — 25 playbooks syntax-checked + inventories OK**
- playbooks 13, 14, 15, 16, 17, 20, 21, 22 and `site.yml --tags validate`
  were **run end-to-end** (expected `rescued=1` / `ignored=1` / assert passes
  as documented in each header)
- `local.demo` collection builds, installs, passes `ansible-doc` and ad-hoc runs
- vault encrypt/decrypt round-trip verified with the demo password script

