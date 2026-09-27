# 00 — First Steps: zero to running automation

> **Goal:** a working control node, a healthy environment, and your first
> successful Ansible command.
> **Template used in every guide:** Goal → Why → Concepts → Steps → Verify →
> Try it yourself → Troubleshoot.

---

## Why this guide exists

Ansible runs on the **control node** and touches **managed nodes**. Your
control node can be Linux, WSL, macOS or a container — and each has quirks.
Five minutes here saves an afternoon later.

## Concepts (glossary)

| Term | Plain English |
|---|---|
| control node | the machine where you run `ansible-playbook` |
| managed node / target | the machine being configured |
| inventory | the list of machines + their variables |
| ad-hoc command | a one-off `ansible <host> -m <module>` (not a playbook) |
| module | a small program Ansible runs on the target (e.g. `package`) |
| plugin | code that runs on the *control node* (callbacks, lookups...) |
| FQCN | Fully Qualified Collection Name, e.g. `ansible.builtin.copy` |

---

## Step 1 — Install Ansible (pick ONE)

| You are on | Recommended | Command |
|---|---|---|
| Ubuntu/Debian | distro package | `sudo apt update && sudo apt install -y ansible-core` |
| Any Linux, isolated | **pipx** (best practice) | `sudo apt install pipx && pipx install ansible-core` |
| Any Linux, isolated | venv | `python3 -m venv ~/venvs/ansible && ~/venvs/ansible/bin/pip install ansible-core` |
| **Windows** | **WSL** (this project) | install WSL2 + Ubuntu, then apt as above |
| CI / throwaway | Docker | `docker run -it --rm -v $PWD:/w -w /w quay.io/ansible/ansible:latest bash` |

⚠️ **Avoid `pip install --user ansible` into the system Python** — it mixes
with your other Python tools and (as documented in [wsl-notes.md](wsl-notes.md))
is exactly how this machine's `ansible-galaxy` broke once already.

**Verify:**

```bash
ansible --version          # must print "ansible [core 2.x.y]"
ansible-playbook --version
```

## Step 2 — Diagnose your environment

```bash
cd ansible                  # project root (this repository)
bash scripts/doctor.sh
```

Expected: green `[ OK ]` lines for ansible/python/git, and **actionable
`-> fix:` lines** for anything missing. Exit code 0 = healthy enough to work.

Key checks it performs:

- is `ansible.cfg` actually loaded? (this decides whether project settings apply)
- does `ansible-galaxy` run without crashing?
- is the directory world-writable? (WSL `/mnt/*` symptom → [wsl-notes.md](wsl-notes.md))
- sudo mode, linters, PyYAML

## Step 3 — Load the project environment

```bash
source scripts/env.sh       # MUST be `source`, not `./env.sh`
ansible-config dump --only-changed
```

**Verify:** the dump must show `CONFIG_FILE() = .../ansible/ansible.cfg` plus
your inventory/roles/collections paths. If you skip this on a normal Linux
box it still works (auto-discovery finds `./ansible.cfg`); on world-writable
dirs it is mandatory — see [environments.md](environments.md).

## Step 4 — Prove connectivity (ad-hoc)

```bash
ansible local -m ping
```

**Verify:**

```text
localhost | SUCCESS => {
    "ansible_facts": {"discovered_interpreter_python": "..."},
    "ping": "pong"
}
```

`ping` is not ICMP — it ships a tiny Python module to the target and runs it.
Green `pong` = inventory + connection + Python interpreter all work.

Ad-hoc pattern to memorise:

```bash
ansible <host-pattern> -m <module> -a '<args>' [-b]
#        who             what        args       become(root)
ansible local -m command -a 'uname -s'
ansible local -m ansible.builtin.command -a 'date'     # FQCN form
```

## Step 5 — Run your first playbooks

```bash
ansible-playbook playbooks/01_basic_command.yml        # simplest playbook
ansible-playbook playbooks/06_variables.yml            # variables + debug
ansible-playbook playbooks/22_selftest.yml             # full environment check
```

**Verify:** each ends with `PLAY RECAP` showing `failed=0`.

Then preview instead of executing (dry run):

```bash
ansible-playbook --check --diff playbooks/05_copy_files.yml
```

## Try it yourself

1. Run `ansible local -m command -a 'whoami'` — change the module to `shell`.
2. Open `playbooks/01_basic_command.yml`, add a fourth task (`hostname`),
   re-run it.
3. Run `ansible-playbook playbooks/12_tags.yml --list-tags` and predict which
   tasks `--tags cleanup` would execute — then prove it.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Ansible is being run in a world writable directory` | `/mnt/*` in WSL is mode 777 | `source scripts/env.sh` — permanent fix in [wsl-notes.md](wsl-notes.md) |
| `ansible-galaxy` crashes with `AttributeError ... MutableMapping` | stale `packaging`/`pyparsing` in `~/.local` | [wsl-notes.md](wsl-notes.md) §2 |
| `sudo: a password is required` | `become` needs your password | run from a real terminal and type it; check with `sudo -n true` |
| `ERROR! conflicting action statements` | two action keywords on one task | one action per task (see playbook 19 for `apply:` placement) |
| `mapping values are not allowed` | unquoted `name:` containing `: ` | quote the value: `name: "Step 1 (tag: setup)"` |
| `couldn't resolve module/filter` | collections_path not loaded | `source scripts/env.sh`, verify `ansible-config dump` |

**Next:** [01-foundations.md](01-foundations.md) — playbooks 01–11 explained.
