# Role: `common`

**What it does:** the baseline every node gets — OS-specific packages, an
application user/group, and a writable base directory.

**Depends on:** nothing.

## Variables

| Variable | Default (defaults/main.yml) | Priority | Purpose |
|---|---|---|---|
| `app_user` | `appuser` | low (override freely) | application login user |
| `app_group` | `appuser` | low (override freely) | owning group |
| `app_base_dir` | `/opt/demoapp` | low | base directory for app files |
| `common_packages_extra` | `[]` | low | operator-added packages (any OS) |
| `common_packages` | see `vars/<family>.yml` | **high** (role vars) | OS baseline packages |

Override examples:

```bash
ansible-playbook playbooks/18_roles.yml -e app_user=alice
ansible-playbook playbooks/18_roles.yml -e '{"common_packages_extra":["git","rsync"]}'
```

## OS awareness

`tasks/main.yml` loads `vars/{{ ansible_os_family }}.yml` through a
`first_found` lookup, with `vars/default.yml` as a safety net:

```text
ansible_os_family = Debian  -> vars/Debian.yml   (apt world: Debian, Ubuntu)
ansible_os_family = RedHat  -> vars/RedHat.yml   (dnf/yum world: RHEL, Rocky...)
anything else / no facts    -> vars/default.yml  (empty package list)
```

## Usage

```yaml
- hosts: all
  become: true
  roles:
    - common
```

## Files

```text
defaults/main.yml   overridable variables (lowest priority)
vars/Debian.yml     packages for the Debian/Ubuntu family
vars/RedHat.yml     packages for the RHEL family
vars/default.yml    fallback when the OS family is unknown
tasks/main.yml      the actual work, top-to-bottom
meta/main.yml       Galaxy metadata + dependencies
README.md           this file
```
