# Role: `webserver`

**What it does:** installs a web server package, renders a demo page from a
Jinja2 template, and keeps the service started/enabled. Restart is
event-driven: only when the rendered page actually changes (handler).

**Depends on:** [`common`](../common/README.md) — declared in `meta/main.yml`.

## Variables

| Variable | Default | Priority | Purpose |
|---|---|---|---|
| `webserver_package` | `nginx` | low | package to install (try `apache2`) |
| `webserver_service` | `nginx` | low | service to manage |
| `webserver_docroot` | `/var/www/html` | low | where the page lands |
| `app_name` | `Ansible Demo Application` | low | page heading |
| `webserver_port` | `8080` | low | port shown on the page |
| `app_user` / `app_group` | `appuser` | from `common` | page owner |

## Usage

```yaml
- hosts: webservers
  become: true
  roles:
    - webserver          # 'common' runs first, automatically
```

Override for a different web server:

```bash
ansible-playbook playbooks/18_roles.yml \
  -e webserver_package=apache2 -e webserver_service=httpd
```

## The notify → handler flow (what to observe)

```text
template task detects a difference
        │ notify: Restart web server
        ▼
handler queued (still not run)
        │ all tasks in the play finish
        ▼
handler runs ONCE  ->  nginx restarted
```

Re-run the playbook without changing anything → `changed=0`, handler never
fires. That is idempotence + event-driven restarts in one picture.

## Files

```text
defaults/main.yml       overridable variables
tasks/main.yml          install / deploy / ensure running
handlers/main.yml       'Restart web server'
templates/index.html.j2 the rendered page
meta/main.yml           galaxy_info + dependency on common
tests/test.yml          standalone smoke test
```
