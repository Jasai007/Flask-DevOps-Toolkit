# Reusable Automation — entry points, pull mode, CI

> **Goal:** turn "a pile of playbooks" into something a machine (not a human)
> can invoke reliably: one entry point, tags as the API, pull mode for
> unreachable fleets, CI as the quality gate.
> Files: `site.yml`, `playbooks/pull.yml`, `playbooks/22_selftest.yml`,
> `.github/workflows/ansible.yml`.

---

## 1. One entry point: `site.yml`

Humans should never type long commands. Everything converges on:

```bash
ansible-playbook site.yml                     # apply everything
ansible-playbook site.yml --tags validate     # fast, root-free gate
ansible-playbook site.yml --limit web1        # one host of many
ansible-playbook site.yml --check --diff      # dry run + diffs
ansible-playbook site.yml --list-hosts        # who is targeted
```

Composition uses `import_playbook` — whole files stitched in order, each
keeping its own plays/tags:

```yaml
- import_playbook: playbooks/22_selftest.yml   # 1) fail fast if env broken
- import_playbook: playbooks/18_roles.yml      # 2) apply the stack
# - import_playbook: playbooks/23_database_tier.yml   # 3) future tiers
```

**Design rules that keep it reusable:**

1. **Self-test first** — `22_selftest.yml` needs no root and touches no
   state: ping, inventory vars, vault presence. If it fails, nothing else
   should run.
2. **Grow by importing, not editing** — new tier = new file + one line here.
3. **Tags are the public API** — `--tags validate` is what CI calls; treat
   tag names like interface names (rename = breaking change).
4. **Roles stay self-contained** (own `become`) so tagged/root-free subsets
   actually work — that is why play 18 has no play-level `become`.

Verified recap for `site.yml --tags validate`:

```text
localhost : ok=8 changed=0 failed=0 skipped=0 rescued=0 ignored=0
```

## 2. Reusable patterns checklist

| Pattern | Where demonstrated | Benefit |
|---|---|---|
| roles + defaults | `roles/` | parameterised, portable |
| tags as API | 12, 18, 22, site.yml | partial runs, CI subsets |
| `--limit` | any playbook | targeted rollout/rollback |
| self-test gate | 22 + site.yml order | fail fast, no blind changes |
| vault secrets | 16, `vault/` | code+secrets co-located safely |
| `--check --diff` | everywhere | preview before damage |
| env profile | `scripts/env.sh` | works on broken mounts/CI |
| health check | `scripts/doctor.sh` | onboarding + support in one command |

## 3. Push vs Pull

```text
PUSH (default):  control node  ──SSH──▶  hosts     you initiate
PULL:            each host ──git──▶ repo, applies ITSELF   host initiates
```

Use pull when hosts are behind NAT/firewalls, or when bootstrap should be
self-contained (cloud-init, edge devices).

```bash
# on the target machine:
ansible-pull -U https://github.com/YOUR_ORG/YOUR_REPO.git \
             -d /opt/ansible site.yml

# make it self-healing (cron):
*/15 * * * * ansible-pull -U <git-url> -d /opt/ansible site.yml >/dev/null 2>&1
```

`playbooks/pull.yml` demonstrates the pattern (stamps
`/tmp/ansible-pull-stamp` with `ansible_date_time` so monitoring can alert
on stale configuration). Safety requirement: **the repo must be idempotent**
— running it every 15 minutes must be a no-op when nothing changed.

## 4. CI: the same checks, everywhere

`.github/workflows/ansible.yml` runs on every push/PR:

```text
yamllint -c .yamllint.yml .          style
ansible-lint                         best practice rules
ansible-playbook --syntax-check ...  all playbooks parse
ansible-inventory --graph            inventories resolve (static + dynamic)
```

Local equivalents — run these before every commit:

```bash
bash scripts/doctor.sh        # environment healthy?
bash scripts/validate.sh      # project healthy? (25 playbooks + inventories + vault)
yamllint -c .yamllint.yml .   # if installed
ansible-lint                  # if installed (.ansible-lint ships configured)
```

## 5. Exercise: wire it all together

1. Break a playbook deliberately (bad indent) → run `validate.sh` → read the
   `FAILED at:` line → fix → green.
2. Add a new play file `playbooks/23_monitoring.yml` (a debug task is
   enough) and import it in `site.yml`.
3. Push the repo to GitHub and watch the workflow in action (Actions tab).
4. On a second machine: `git clone`, `bash scripts/doctor.sh`,
   `ansible-playbook site.yml --tags validate` — that is "reusable" proven.

**Next:** [cheatsheet.md](cheatsheet.md) — everything on fewer pages.
