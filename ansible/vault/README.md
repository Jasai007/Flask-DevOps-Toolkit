# `vault/` — encrypted secrets

Files here are encrypted with **ansible-vault** (AES256) so they can live in
git next to the playbooks that use them, without exposing plaintext.

| File | Committed? | Content |
|---|---|---|
| `secrets.yml` | ✅ (encrypted) | `vault_demo_*` variables |
| `../scripts/vault_pass_demo.txt` | ✅ **on purpose** | public **demo** password |

> ⚠️ The demo password is public by design — this is a learning project.
> In real life the password lives on the control node only
> (`/etc/ansible/vault.pass`, mode 600, owner = the ansible user) and is
> **never** committed. CI reads it from a secret store.

## The vault lifecycle

```bash
source scripts/env.sh   # from the project root

# 1. VIEW the decrypted content (never writes to disk)
ansible-vault view vault/secrets.yml \
    --vault-password-file scripts/vault_pass_demo.txt

# 2. EDIT in place (opens $EDITOR on the plaintext, re-encrypts on save)
ansible-vault edit vault/secrets.yml \
    --vault-password-file scripts/vault_pass_demo.txt

# 3. CREATE new secrets
ansible-vault encrypt_string 'my-new-secret' \
    --name vault_new_key --vault-password-file scripts/vault_pass_demo.txt

# 4. REKEY (change the password - re-encrypts with a new one)
ansible-vault rekey vault/secrets.yml \
    --vault-password-file scripts/vault_pass_demo.txt \
    --new-vault-password-file <new-password-file>

# 5. DECRYPT permanently (never do this for real secrets in a repo!)
ansible-vault decrypt vault/secrets.yml \
    --vault-password-file scripts/vault_pass_demo.txt
```

## Running playbooks that need the secrets

```bash
ansible-playbook playbooks/16_vault.yml \
    --vault-password-file scripts/vault_pass_demo.txt

# shortcut: uncomment this line in ansible.cfg
#   vault_password_file = scripts/vault_pass_demo.txt
```

## Rules of the road

1. **Never** commit plaintext secrets, not even "temporary" ones.
2. Give every task that touches secrets `no_log: true`.
3. Rotate (`rekey`) passwords when someone leaves the project.
4. `vault/*.decrypted` and `vault_pass.txt` are gitignored as a safety net.
