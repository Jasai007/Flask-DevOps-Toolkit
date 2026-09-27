# Environments — running this project anywhere

> **Goal:** understand how Ansible finds its configuration and how this
> project stays portable across control nodes (Linux / WSL / macOS / Docker
> / CI), with the exact commands for each.

---

## 1. Configuration precedence (memorise this)

Highest wins:

```text
1. command-line flags        -i, --limit, --vault-password-file, -e ...
2. environment variables     ANSIBLE_CONFIG, ANSIBLE_ROLES_PATH,
                             ANSIBLE_COLLECTIONS_PATH, ANSIBLE_INVENTORY ...
3. ./ansible.cfg             (auto-discovered from your CWD)
4. ~/.ansible.cfg            (per user)
5. /etc/ansible/ansible.cfg  (system-wide)
6. built-in defaults
```

**Inspect what is actually in force:**

```bash
ansible-config dump --only-changed     # short: only non-defaults
ansible-config list | less             # full catalogue + where each came from
```

### The two gotchas this project works around

1. **Relative paths in `ansible.cfg` resolve against your current working
   directory** → always `cd` to the project root (or use `scripts/env.sh`,
   which exports absolute paths).
2. **World-writable CWD blocks `./ansible.cfg` discovery** (WSL `/mnt/*`,
   some NFS/CI mounts). Explicit `ANSIBLE_CONFIG` still works → that is the
   whole trick behind `scripts/env.sh`. Details: [wsl-notes.md](wsl-notes.md).

---

## 2. Control-node matrix

| Control node | Install Ansible | Config discovery | Notes |
|---|---|---|---|
| **Linux (native)** | `apt install ansible-core` or pipx/venv | ✅ automatic | ideal |
| **WSL (this project)** | apt inside WSL | ⚠️ needs `env.sh` or `/etc/wsl.conf` metadata | see [wsl-notes.md](wsl-notes.md) |
| **macOS** | `brew install ansible` or pipx | ✅ automatic | targets: any |
| **Windows (native)** | ❌ not supported upstream | — | use WSL — it *is* the supported path |
| **Docker container** | `pip install ansible-core` in image | ✅ (mount repo, work in /work) | clean-room for CI parity |
| **CI (GitHub Actions)** | `pip install ansible-core` | ✅ | see `.github/workflows/ansible.yml` |

Every environment runs the same entry points:

```bash
bash scripts/doctor.sh        # diagnose
source scripts/env.sh         # make project settings explicit (harmless everywhere)
bash scripts/validate.sh      # prove the project is healthy
ansible-playbook site.yml     # apply everything
```

---

## 3. Install recommendations (best practice ladder)

1. **pipx / venv** — tools isolated from system Python; immune to
   `~/.local` pollution (the class of bug that broke `ansible-galaxy` here).
2. **apt/brew packages** — zero maintenance, slightly older versions.
3. **`pip install --user` into system Python** — ❌ avoid. On Ubuntu 24.04+
   it is also PEP 668 blocked (`--break-system-packages` papers over it).

Pin your linters the same way (`pipx install ansible-lint`, `pipx install
yamllint`) so they never fight with Ansible's own dependencies.

---

## 4. Per-environment inventory strategy

The project ships:

| Source | When to use | How |
|---|---|---|
| `inventory/hosts` | default — localhost lab | picked up by `ansible.cfg` |
| `inventory/hosts.example` | template for real fleets | `cp inventory/hosts.example inventory/hosts` |
| `inventory/dynamic/inventory.py` | generated/hosted fleets | `-i inventory/dynamic/inventory.py` |
| env var | shells/CI that cannot load cfg | `export ANSIBLE_INVENTORY=...` (CLI `-i` still wins) |

For multiple real environments (lab / staging / production), the community
pattern is one directory per environment — nothing in this project forbids it:

```text
inventories/
├── lab/       {hosts, group_vars/, host_vars/}
├── staging/
└── production/
ansible-playbook -i inventories/staging site.yml
```

Move `group_vars/` **next to the inventory it belongs to** — variable files
are scoped to their inventory source, not global.

---

## 5. OS-adaptive automation (targets differ, not just control nodes)

Targets are not all Ubuntu either. This project demonstrates the standard
pattern in `roles/common`:

```text
tasks/main.yml
  └─ include_vars: lookup('first_found', files=[{{ ansible_os_family }}.yml,
                                                default.yml],
                                 paths=[role_path/vars])
       ├── vars/Debian.yml   → apt world (Debian/Ubuntu)
       ├── vars/RedHat.yml   → dnf/yum world (RHEL/Rocky/Alma/Fedora)
       └── vars/default.yml  → safety net (facts missing / exotic OS)
```

Extend it: add `vars/Suse.yml`, `vars/Arch.yml` — no task changes needed.
Service/package **names** belong in `defaults/` (overridable), OS **facts**
belong in `vars/<family>.yml` (high priority, non-negotiable truth).

---

## 6. Portability checklist for your own automation

- [ ] no absolute paths outside the repo in `ansible.cfg` (use `./`, `~`)
- [ ] every playbook uses FQCN (`ansible.builtin.*`, `my.ns.module`)
- [ ] roles are self-contained (own `become`, own defaults) — see playbook 18
- [ ] secrets via Vault, password supplied by flag/env/CI secret — never committed
- [ ] `scripts/doctor.sh`-style health check in CI
- [ ] `ansible-playbook --syntax-check` over every playbook (see `validate.sh`)
- [ ] documented control-node requirements in the README
