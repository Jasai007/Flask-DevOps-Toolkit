# Jenkins SSH Agent: Insecure / Demonstration Build

> ⚠️ **SECURITY WARNING: FOR LAB & EDUCATIONAL USE ONLY**  
> This image contains intentionally insecure defaults, including hardcoded credentials (`root:redhat`), enabled root SSH access, and password authentication. **Do not deploy this container in production environments or expose it to public networks.**

---

## Overview

This setup demonstrates a minimal SSH-enabled container based on **Amazon Linux 2023** configured to accept Jenkins SSH connections. 

It serves as an introductory baseline to understand how Jenkins interacts with remote agents over SSH before transitioning to hardened, key-based, non-root agent architectures.

---

## Technical Specifications

- **Base Image:** Amazon Linux 2023
- **JDK Runtime:** Oracle JDK 17 (RPM build)
- **Tooling:** Git, Wget, Python 3, OpenSSH Server
- **Authentication Model:** Password-based (`root` / `redhat`)
- **Daemon:** OpenSSH Server (`sshd`) running in foreground mode (`-D`)

---

## Container Build & Run

### 1. Build the Docker Image

Run the build command from inside the `jenkins-ssh-agent-insecure` directory:

```bash
docker build -t jenkins-ssh-agent-insecure:latest .
```

---

### 2. Run the Container

Start the agent container and bind the SSH daemon to host port `2222`:

```bash
docker run -d \
  --name jenkins-agent-insecure \
  --restart unless-stopped \
  -p 2222:22 \
  jenkins-ssh-agent-insecure:latest
```

*Note: Port `2222` is used on the host to avoid port collisions with the host machine's own SSH daemon on port `22`.*

---

### 3. Verify Connection Locally

Test the SSH connection from your local terminal or host instance:

```bash
ssh root@localhost -p 2222
```

- **Password:** `redhat`

---

## Configuring the Node in Jenkins

1. Navigate to **Manage Jenkins** > **Nodes** > **New Node**.
2. Configure the following node settings:
   - **Node Name:** `insecure-demo-agent`
   - **Remote root directory:** `/root`
   - **Launch method:** Launch agents via SSH
   - **Host:** IP address of the worker host
   - **Port:** `2222`
   - **Credentials:** Username with password (`Username: root`, `Password: redhat`)
   - **Host Key Verification Strategy:** *Non-verifying Verification Strategy* (Lab use only)
3. Save and click **Launch Agent**.

---

## Identified Security Vulnerabilities

| Insecure Configuration | Risk / Impact | Production Best Practice |
| :--- | :--- | :--- |
| **Hardcoded Root Password** | Anyone with network access can compromise root. | Remove passwords entirely; use asymmetric SSH key pairs. |
| **Direct Root Login (`PermitRootLogin yes`)** | Complete container takeover; risk of container escapes. | Run SSH under a dedicated, non-root user (e.g., `jenkins` UID 1000). |
| **Password Authentication Enabled** | Susceptible to credential leaks and brute-force attacks. | Disable password authentication (`PasswordAuthentication no`). |
| **Broad User Access** | Unrestricted access across system accounts. | Explicitly restrict access via `AllowUsers jenkins`. |

---

## Hardened Alternative

For an enterprise-ready, hardened version of this build agent, refer to the sibling directory:

👉 **[Hardened SSH Agent (Amazon Linux 2023)](../jenkins-ssh-agent-amazonlinux)**

The hardened version introduces:
- SSH public/private key authentication (zero passwords)
- Dedicated non-root `jenkins` user
- Complete lockdown of root SSH logins
- Minimal privilege boundaries matching production standards
