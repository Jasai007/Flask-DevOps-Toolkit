# WSL Notes — the three real problems on this machine (and their fixes)

> Everything in this file was **observed and verified on this project's
> machine**: WSL2, Ubuntu 24.04, `ansible-core 2.16.3`, repository living on
> `/mnt/d` (a Windows drive). Each section has: symptom → root cause → fix
> ladder (quick → permanent) → verification.

---

## 1. `ansible.cfg` is *silently ignored*

### Symptom

```text
[WARNING]: Ansible is being run in a world writable directory
(/mnt/d/.../ansible), ignoring it as an ansible.cfg source.
...
$ ansible-config dump --only-changed
CONFIG_FILE() = None          # <- nothing loaded, settings dead
```

Inventory, `roles_path`, `collections_path` — all ignored. Playbooks then
behave as if the project had no configuration at all.

### Root cause (verified in Ansible's source, `config/manager.py`)

Config **auto-discovery** skips `./ansible.cfg` when the working directory is
world-writable (`st_mode & S_IWOTH`). WSL mounts Windows drives through
DrvFs/9p **without the `metadata` option**, so every directory reports mode
`777` → auto-discovery refuses the file. `chmod` cannot help: without
`metadata`, permission changes on DrvFs are not persisted.

Note: an **explicit `ANSIBLE_CONFIG` pointing at the file DOES work** (the
world-writable check only blocks *discovery*, not an explicit path) — that is
what `scripts/env.sh` exploits.

### Fix ladder

| | Fix | Cost | How |
|---|---|---|---|
| **L1 (quick)** | export settings as env vars | none | `source scripts/env.sh` in every new shell (add to `~/.bashrc` if you like) |
| **L2 (permanent, recommended)** | enable POSIX metadata on `/mnt/*` | needs your sudo + one WSL restart | see below |
| **L3 (best performance)** | keep the repo on the WSL native filesystem | a clone | `git clone <url> ~/ansible-project` + VS Code *WSL: Open Folder* |

**L2 steps (you run these — the password is yours):**

```bash
sudo tee -a /etc/wsl.conf <<'EOF'
[automount]
enabled = true
options = "metadata,umask=22,fmask=11"
EOF

# from PowerShell (not WSL):
wsl --shutdown
```

Reopen WSL, then verify:

```bash
stat -c '%a' /mnt/d/Current_Working_Directory/CODE/Configuration\ Management/Ansible/ansible-project/ansible
# expect 755 (not 777)
cd <project> && ansible-config dump --only-changed | head -3
# expect CONFIG_FILE() = .../ansible.cfg
```

`metadata` also makes `chmod` work and improves ownership fidelity — usually
what you want for development.

### Verify anytime

```bash
bash scripts/doctor.sh | grep -E 'ansible.cfg|world-writable'
```

---

## 2. `ansible-galaxy` crashes

### Symptom

```text
File ".../site-packages/pyparsing.py", line 943
    collections.MutableMapping.register(ParseResults)
AttributeError: module 'collections' has no attribute 'MutableMapping'
```

### Root cause

`~/.local/lib/python3.12/site-packages` held **ancient leftovers of an old
pip-based Ansible install**: `packaging 16.8` (2016) and `pyparsing 2.2.0`.
User-site **shadows** system packages, so `ansible-galaxy` imported the broken
pair instead of the healthy system ones (`packaging 24.0`, `pyparsing 3.1.1`).
`collections.MutableMapping` was removed in Python 3.10 → crash.
Confirmed instantly because `PYTHONNOUSERSITE=1 ansible-galaxy --version`
worked perfectly.

### Fix applied on this machine (already done)

```bash
mkdir -p ~/.local_fix_backup_ansible
mv ~/.local/lib/python3.12/site-packages/{packaging,packaging-16.8.dist-info,pyparsing,pyparsing-2.2.0.dist-info,pyparsing.py} \
   ~/.local_fix_backup_ansible/
```

Moved (not deleted!) — everything is restorable from `~/.local_fix_backup_ansible/`.

**Verify:**

```bash
ansible-galaxy --version         # prints version, no traceback
python3 -c 'import packaging; print(packaging.__version__, packaging.__file__)'
# expect: 24.0 /usr/lib/python3/dist-packages/...
```

### Prevention (recommended practice)

1. **Never** mix system-Python tooling with `pip install --user`. Use:
   `sudo apt install ansible-core`, `pipx install ansible-core`, or a
   dedicated venv (`python3 -m venv ~/venvs/ansible`).
2. Ubuntu 24.04+ is **PEP 668 `EXTERNALLY-MANAGED`**: plain
   `pip3 install --user X` is refused; `--break-system-packages` works but
   papers over exactly this class of mess.
3. `bash scripts/doctor.sh` detects the `MutableMapping` signature and
   prints the fix.

---

## 3. Vault password file → "Exec format error"

### Symptom

```text
ERROR! Problem running vault password script .../vault_pass_demo.txt
([Errno 8] Exec format error: ...)
If this is not a script, remove the executable bit from the file.
```

### Root cause

On a 777 mount **every** file looks executable. Ansible treats any
executable `--vault-password-file` as a **password script** (run it, use
stdout as the password) — an official feature — and a plain text file with
no shebang cannot be executed.

### Fix applied

`scripts/vault_pass_demo.txt` **is** a real password script:

```bash
#!/usr/bin/env bash
echo ansible-demo-vault-password
```

It works in all three worlds:

| Environment | Why it works |
|---|---|
| WSL `/mnt/*` (777) | looks executable → Ansible runs it → prints the password |
| Linux checkout | committed with the executable bit → runs the same way |
| after the L2 metadata fix | git restores mode 755 → still runs |

Fallbacks if your copy ever loses `+x`:

```bash
chmod +x scripts/vault_pass_demo.txt
# or interactive, no file at all:
ansible-playbook playbooks/16_vault.yml --ask-vault-pass
```

---

## 4. Line endings: CRLF vs LF (Windows-editor gotcha)

Files created by Windows editors can arrive with CRLF endings. In WSL that
means `set: pipefail\r: invalid option name` or `$'\r': command not found`.

**Fixes in this project:**

- `.gitattributes` forces `eol=lf` for `*.sh *.py *.yml ...` on every checkout.
- If you ever see `\r` errors, run:

```bash
grep -rlI $'\r' --exclude-dir=.git --exclude-dir=.kilo . | xargs -r sed -i 's/\r$//'
```

---

## 5. Useful WSL/Ansible facts discovered along the way

- `sudo` requires a password here → `become: true` plays must run from a
  real terminal (you type it) — `scripts/doctor.sh` reports the mode.
- `ansible-core` is apt-installed at `/usr/bin/ansible`, Python 3.12.3.
- `community.general`, `ansible.posix`, `amazon.aws` already exist in
  `/usr/lib/python3/dist-packages/ansible_collections` (apt dependencies),
  which is why `ansible-doc -t callback -l` lists e.g. `community.general.yaml`.
- Run everything from the project root; relative paths in `ansible.cfg`
  resolve against your **current working directory**.
- This project's own tooling caught every bug above during its build —
  `scripts/validate.sh` + `scripts/doctor.sh` are the regression net.

