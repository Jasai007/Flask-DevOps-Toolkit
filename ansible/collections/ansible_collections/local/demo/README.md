# Collection: `local.demo`

A minimal, fully commented Ansible **collection** — the packaging unit for
modules, plugins, roles and variables. Ships with this project so you can
study a *real* collection layout and build/install it yourself.

## Layout

```text
collections/ansible_collections/local/demo/   <- directory path IS the identity
├── galaxy.yml                    build/publish metadata (version, license...)
├── README.md                     this file
├── meta/
│   └── runtime.yml               runtime contract (requires_ansible...)
└── plugins/
    ├── modules/
    │   └── host_summary.py       custom MODULE  -> local.demo.host_summary
    └── filter/
        └── human_size.py         custom FILTER  -> local.demo.human_size
```

The path `ansible_collections/<namespace>/<name>` is not decoration: Ansible
derives the FQCN (`local.demo.*`) from it. `collections_path` in
`ansible.cfg` points at `./collections`, which is how it gets discovered.

## Using it

```bash
# after: source scripts/env.sh   (loads collections_path into your shell)

# from a playbook (playbooks/20_collections.yml):
#     - local.demo.host_summary: {}
#     - {{ 1536000 | local.demo.human_size }}

# ad-hoc:
ansible localhost -i inventory/hosts -m local.demo.host_summary

# documentation of our own plugin:
ansible-doc local.demo.host_summary
```

## Build & distribute (offline)

```bash
bash scripts/galaxy.sh build
# -> collections/ansible_collections/local/demo/local-demo-1.0.0.tar.gz

ansible-galaxy collection install local-demo-1.0.0.tar.gz -p ~/.ansible/collections
```

## Namespace rules

- `local.*` = your own private namespace — never publish it to Galaxy.
- Published namespaces must be claimed on galaxy.ansible.com and must be
  unique (e.g. `acme.corp`).
