# 02 — Advanced Fundamentals: playbooks 12–17

> These six playbooks turn "I can write tasks" into "I can run automation
> safely in production". Each section: what it teaches, how to run it, what
> to observe. All outputs below were captured from real runs on this project.

---

## 12 · Tags — `12_tags.yml`

**Concept:** select subsets of a playbook instead of maintaining many files.

```bash
ansible-playbook playbooks/12_tags.yml --list-tags
ansible-playbook playbooks/12_tags.yml --tags setup
ansible-playbook playbooks/12_tags.yml --tags config,cleanup
ansible-playbook playbooks/12_tags.yml --skip-tags cleanup
```

**Observe:**

- play-level tags are inherited by every task;
- the `always` tag executes in **every** tagged run;
- **tags have dependencies**: `--tags config` alone fails on a clean machine
  because the directory (tagged `setup`) never got created — real life is the
  same; run `--tags setup` first.

## 13 · Blocks (try/except/finally) — `13_blocks.yml`

**Concept:** one error handler for a group of tasks.

```bash
ansible-playbook playbooks/13_blocks.yml
```

**Observe in PLAY RECAP:** `rescued=1`, `failed=0` — the deliberate failure
was *recovered*, not fatal. Structure:

| Block section | Python equivalent | Runs when |
|---|---|---|
| `block:` | `try:` | always first |
| `rescue:` | `except:` | a block task failed |
| `always:` | `finally:` | success **or** failure |

Use `always` for cleanup/locking/unlocking; use `rescue` for rollback +
alerting.

## 14 · Error handling — `14_error_handling.yml`

**Concept:** you decide what failure/change means.

| Tool | Question it answers | Seen in recap as |
|---|---|---|
| `failed_when:` | "which exit codes are acceptable?" | normal ok/fail |
| `changed_when:` | "did state really change, or did we just read?" | `changed=0` for reads |
| `ignore_errors:` | "log it, keep going" | `ignored=1` |
| `retries:` + `until:` | "try until true (service waits)" | attempts in task output |

Real example demonstrated: `grep` rc=1 (no match) tolerated, rc≥2 fails.

## 15 · Filters & lookups — `15_filters_lookups.yml`

**The distinction to memorise:**

```jinja
{{ app_name | upper }}                     {# filter: TRANSFORMS a value #}
{{ lookup('file', '../files/x.txt') }}     {# lookup: FETCHES from outside #}
```

Filters demonstrated: `default`, `ternary`, `upper`, `length`, `int`,
`selectattr` + `map` + `join` chain, `to_json`.
Lookups demonstrated: `env`, `file`, and `query()` (list-returning modern
form). All outputs verified — e.g. `selectattr('enabled')` chain produced
exactly `healthcheck, caching`.

**Try it yourself:** add `-e app_debug=true` and watch `default` become
irrelevant; break a var name and watch `default` save the play.

## 16 · Vault — `16_vault.yml`

**Concept:** encrypt secrets in-repo; decrypt only in memory.

```bash
ansible-playbook playbooks/16_vault.yml \
    --vault-password-file scripts/vault_pass_demo.txt
```

**Observe:** assert passes → decrypted value usable → the same value hidden
by `no_log: true` (output reads `censored due to no_log`).

The full vault lifecycle (view/edit/encrypt_string/rekey/decrypt) is in
[vault/README.md](../vault/README.md). Rules of the road:

1. never commit plaintext, 2. `no_log: true` on every task touching secrets,
3. rotate with `rekey` when people leave, 4. `vault/*.decrypted` is gitignored
as a seatbelt.

## 17 · Execution control — `17_advanced_execution.yml`

**Concept:** *where* and *how often* tasks run.

| Keyword | Scope | Question it answers |
|---|---|---|
| `delegate_to:` | task | "run this somewhere else (jump host, control node)" |
| `run_once:` | task | "only the first host of the batch" |
| `serial:` | **play** | "process N hosts at a time" (rolling deploys) |
| `throttle:` | task | "max N simultaneous executions" (protect services) |
| `check_mode: false` | task | "run even during `--check`" (read-only probes) |

```bash
ansible-playbook playbooks/17_advanced_execution.yml --check
```

**Observe:** the `check_mode: false` task executes even in dry-run mode.

---

## How these combine in real pipelines

```text
site.yml
 ├─ --tags validate        fast, root-free gate  (blocks 12 + selftest)
 ├─ serial: 20%             rolling canary        (block 17)
 │   └─ block/rescue        rollback on failure   (block 13)
 │        └─ retries/until  wait for health       (block 14)
 └─ no_log + vault          secrets stay secret   (block 16)
```

## Try it yourself

1. Change 14's `failed_when: grep_out.rc > 1` to `> 0` — watch "no match"
   become fatal.
2. Add `--tags always` only runs to 12 — which tasks print?
3. In 17, set `throttle: 1` and add two hosts to the inventory (use
   `hosts.example`) — observe batching with `serial: 1`.

**Next:** [roles.md](roles.md) — packaging all of this for reuse.
