# Ansible Cheatsheet — one screen per topic

> Everything command-shaped in this project. `source scripts/env.sh` first
> (loads project settings into any shell).

---

## Environment & health

```bash
bash scripts/doctor.sh                 # diagnose machine + print fixes
source scripts/env.sh                  # ANSIBLE_CONFIG/ROLES/COLLECTIONS/INVENTORY
ansible-config dump --only-changed     # what is actually configured (must show CONFIG_FILE)
bash scripts/validate.sh               # syntax-check ALL playbooks + inventories + vault
ansible --version                      # control-node versions
```

## Ad-hoc commands

```bash
ansible <pattern> -m <module> -a '<args>' [-b]     # -b = become (root)
ansible local -m ping                               # connectivity test
ansible local -m command -a 'uname -s'
ansible local -m ansible.builtin.copy -a 'src=a dest=/tmp/a mode=0644' -b
ansible all -m setup | less                         # raw facts dump
```

## Playbooks

```bash
ansible-playbook <pb>                      # run
ansible-playbook --syntax-check <pb>       # parse only
ansible-playbook --list-tasks <pb>         # tasks in order
ansible-playbook --list-hosts <pb>         # targets
ansible-playbook --check --diff <pb>       # DRY RUN + show changes
ansible-playbook --start-at-task 'NAME' <pb>   # resume mid-play
ansible-playbook <pb> --limit host1        # subset of hosts
ansible-playbook <pb> -e key=value         # extra vars (highest priority)
ansible-playbook <pb> -vvv                 # verbose (up to -vvvvvv)
ansible-playbook <pb> --tags a,b           # only these tags
ansible-playbook <pb> --skip-tags a
ansible-playbook <pb> --step               # interactive y/n per task
```

## Vault

```bash
ansible-vault create|edit|view|rekey|encrypt|decrypt <file> \
    --vault-password-file scripts/vault_pass_demo.txt
ansible-vault encrypt_string 'secret' --name vault_new_key
ansible-playbook <pb> --ask-vault-pass             # interactive
# project demo:
ansible-playbook playbooks/16_vault.yml --vault-password-file scripts/vault_pass_demo.txt
```

## Inventory

```bash
ansible-inventory --graph                    # tree of default inventory
ansible-inventory --list | less              # everything, incl. merged vars
ansible-inventory -i inventory/dynamic/inventory.py --graph   # dynamic
python3 inventory/dynamic/inventory.py --list                 # raw contract
ansible-inventory -i inventory/hosts.example --graph           # template
```

## Roles & Galaxy

```bash
bash scripts/galaxy.sh init <name>      # scaffold roles/<name>  (--init-path!)
bash scripts/galaxy.sh install          # ansible-galaxy install -r requirements.yml
bash scripts/galaxy.sh list             # installed roles + collections
bash scripts/galaxy.sh info <ns.role>   # metadata
bash scripts/galaxy.sh build            # build local.demo tarball
ansible-galaxy role install <ns.role> --init-path? → role install <ns.role>
ansible-doc <role-or-module>            # docs of anything installed
```

## Collections & plugins

```bash
ansible-doc local.demo.host_summary          # our module's docstring
ansible-doc -t filter -l                     # list filters
ansible-doc -t callback -l                   # list output callbacks
ansible-doc -t lookup ansible.builtin.env
ansible localhost -i inventory/hosts -m local.demo.host_summary   # ad-hoc
ansible-galaxy collection build collections/ansible_collections/local/demo
```

## Lint & style

```bash
yamllint -c .yamllint.yml .     # YAML style (config: .yamllint.yml)
ansible-lint                    # Ansible rules (config: .ansible-lint)
ansible-lint playbooks/11_complete_webserver.yml
```

## Idempotence & debugging

```bash
# second run must be changed=0:
ansible-playbook playbooks/05_copy_files.yml && ansible-playbook playbooks/05_copy_files.yml
ansible-playbook <pb> --check --diff      # see changes without making them
ansible-playbook <pb> -vvvv               # connection-level debugging
ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook <pb>   # pretty one-off output
```

## Facts & variables

```bash
ansible local -m setup -a 'filter=ansible_os_family'
ansible-inventory --host localhost        # merged vars for one host
ansible localhost -m debug -a 'msg={{ ansible_facts | default("no facts") }}'
```

## Exit codes to script against

| Code | Meaning |
|---|---|
| 0 | success (ok/changed/skipped only) |
| 1 | at least one task failed / unreachable |
| 2 | usage or YAML parse error (syntax-check catches these) |
