# 01 — Foundations: playbooks 01–11 explained

> Companion to the first eleven playbooks: what each one teaches, the exact
> command to run it, what to observe, and the concept that carries into
> everything else. Read in order — that *is* the curriculum.

---

## The mental model (applies to every playbook)

```text
Inventory  →  Play (hosts:)  →  Tasks  →  Modules  →  results
   who          where/root         what      how         ok/changed/failed
```

Every task answers three questions: **which host** (play), **what state**
(module args), **may it use root** (`become`).

---

## 01 · `01_basic_command.yml` — ad-hoc → playbook

**Concept:** a playbook is an ordered list of tasks; modules run commands.

```bash
ansible-playbook playbooks/01_basic_command.yml
```

**Observe:** three tasks, each `changed` (command module always claims a
change — remember this, playbook 14 fixes it). Compare with the ad-hoc form:
`ansible local -m command -a 'date'`.

## 02 · `02_create_user.yml` — idempotence

**Concept:** the `user` module describes *desired state*, not a command.
Run it twice: second run reports `changed=0`. This is the core promise of
configuration management.

```bash
ansible-playbook playbooks/02_create_user.yml     # needs sudo (become)
```

## 03 · `03_install_package.yml` — packages across distros

**Concept:** `package` picks the right tool (`apt`/`dnf`/`yum`) from the
target's `ansible_os_family`. Compare with `apt` module = Ubuntu-only.

```bash
ansible-playbook playbooks/03_install_package.yml
ansible-doc ansible.builtin.package          # always read the module docs
```

## 04 · `04_manage_service.yml` — service lifecycle

**Concept:** `state: started` + `enabled: true` = running *now* **and**
after reboot. Idempotent: only acts when the state actually differs.

## 05 · `05_copy_files.yml` — files & diff mode

**Concept:** `copy` ships control-node files to targets; `mode` sets
permissions as a **quoted string** (`'0644'` — YAML would read `0644` as
octal-with-leading-zero weirdness... quoting makes it a string Ansible
converts safely).

```bash
ansible-playbook --check --diff playbooks/05_copy_files.yml
```

**Observe:** `--check` = dry run, `--diff` = show what would change. The
single most useful safety habit in Ansible.

## 06 · `06_variables.yml` — where variables come from

**Concept:** the full precedence chain in miniature:

```text
-e extra vars  >  play vars  >  inventory group_vars  >  host_vars  >  role defaults
```

```bash
ansible-playbook playbooks/06_variables.yml -e app_port=9090
```

In this project:

| Where | File | Visible to |
|---|---|---|
| group vars (all) | `inventory/group_vars/all.yml` | every host |
| group vars | `inventory/group_vars/webservers.yml` | `[webservers]` |
| host vars | `inventory/host_vars/localhost.yml` | localhost only |

Verify with: `ansible-inventory --list | less`.

## 07 · `07_conditionals.yml` — `when`

**Concept:** `when:` is an expression (no `{{ }}` needed — Ansible wraps it).
Set `install_nginx: false` and watch the task skip. Combine:
`when: ansible_os_family == "Debian" and (enable_web | bool)`.

## 08 · `08_loops.yml` — repeat without copy-paste

**Concept:** `loop:` iterates a list; `item` is each element. Modern cousins:

```yaml
loop: "{{ users }}"                       # classic
loop: "{{ range(5) | list }}"             # numbered
with_items: ...                           # legacy form, avoid in new code
```

## 09 · `09_handlers.yml` — event-driven reactions

**Concept:** a changed task `notify:`s a handler; handlers run **once, at
end of play** — never on no-op runs.

```text
copy detects change → handler queued → play finishes → handler fires
```

Handlers also explain ordering: restarts happen *after* config is in place.

## 10 · `10_template.yml` — Jinja2 rendering

**Concept:** `template` renders `*.j2` on the control node, ships the result.
Compare to `copy` (no rendering). Try changing `app_port` and re-running with
`--diff` to see the rendered delta. Deeper Jinja: playbook 15.

## 11 · `11_complete_webserver.yml` — everything combined

**Concept:** install → user → template → service + handler = a real
role-shaped playbook. This is exactly what `roles/webserver` encapsulates
next — the reason roles exist (see [roles.md](roles.md)).

```bash
ansible-playbook --check --diff playbooks/11_complete_webserver.yml
ansible-playbook --list-tasks playbooks/11_complete_webserver.yml
```

---

## Daily-driver commands (used constantly from here on)

```bash
ansible-playbook --syntax-check <pb>     # parse only, milliseconds
ansible-playbook --list-tasks <pb>       # what would run, in order
ansible-playbook --list-hosts <pb>       # who it targets
ansible-playbook --check --diff <pb>     # dry run + show changes
ansible-playbook --start-at-task 'Install nginx' <pb>   # resume mid-play
ansible-playbook <pb> --limit web1       # subset of hosts
```

## Try it yourself

1. Add a second task to 05 that copies `index.html` — verify with `--diff`.
2. In 06, define the same variable in play `vars:` AND `group_vars` — run
   with `-vvv` or `ansible-inventory --list` to see who wins.
3. Convert `11_complete_webserver.yml` into two plays (`hosts: local`
   twice) and observe play boundaries in the output.

**Next:** [02-advanced-fundamentals.md](02-advanced-fundamentals.md) —
playbooks 12–17.
