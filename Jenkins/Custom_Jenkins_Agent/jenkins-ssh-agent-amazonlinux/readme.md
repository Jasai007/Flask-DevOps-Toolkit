# Jenkins SSH Agent Docker Image

This Docker image provides a secure, isolated Jenkins build agent environment using Amazon Linux 2023, Java 17, and key-based SSH authentication. **No passwords or credentials are hardcoded.**

---

## Features

- **Base Image:** Amazon Linux 2023
- **Tooling:** Installs OpenJDK 17 (required for Jenkins Remoting), Git, Python 3, and OpenSSH server
- **Dedicated User:** Creates a non-root `jenkins` user (`UID/GID 1000`)
- **Hardened SSH:** 
  - Key-based authentication only (password authentication disabled)
  - Direct root login via SSH is disabled
  - Inbound SSH access is restricted exclusively to the `jenkins` user

---

## Where to Run Each Step

When configuring a multi-server setup (such as Jenkins on AWS EC2), ensure each command is executed on the intended machine:

| Step | Action | Execution Target |
| :--- | :--- | :--- |
| **Step 1** | Generate SSH Key Pair | **Jenkins Controller (Master)** or local admin machine |
| **Step 2** | Build Docker Image | **Worker EC2 Instance** (or build and push to a private registry) |
| **Step 3** | Run Docker Container | **Worker EC2 Instance** |
| **Step 4** | Configure Node in UI | **Jenkins Web UI** (Controller) |

---

## Deployment Options: Which Approach Should You Choose?

| Approach | Best For | Pros & Cons |
| :--- | :--- | :--- |
| **Method A: Build locally with `--build-arg`** *(Recommended)* | Production & CI/CD Pipelines | **Pros:** Self-contained, immutable artifact; pushable to private registries (e.g., AWS ECR).<br>**Cons:** Requires Docker build tools on the host. |
| **Method B: Prebuilt Image with Volume Mount** | Quick setups & local evaluation | **Pros:** No build time; instant startup from Docker Hub.<br>**Cons:** Requires maintaining the key file path on the host OS. |

---

## Step-by-Step Setup

### 1. Generate an SSH Key Pair

On your **Jenkins Controller (Master)** or local machine, generate a dedicated SSH key pair:

```bash
ssh-keygen -t rsa -b 2048 -f id_jenkins_agent
```

- Generates `id_jenkins_agent` (private key) and `id_jenkins_agent.pub` (public key).
- Leave the passphrase empty for automated logins.
- Copy `id_jenkins_agent.pub` over to your **Worker EC2 instance** (e.g., into `/home/ec2-user/id_jenkins_agent.pub`).

---

### 2 & 3. Choose How to Run the Agent on the Worker Node

#### Method A: Build Image Locally (Recommended for Production)

Run this on the **Worker EC2 instance** inside the directory containing the `Dockerfile`:

```bash
# Build the image and bake in your public key
docker build --build-arg JENKINS_PUB_KEY="$(cat /home/ec2-user/id_jenkins_agent.pub)" -t jenkins-agent:latest .

# Run the container
docker run -d \
  --name my-jenkins-agent \
  --restart unless-stopped \
  -p 2222:22 \
  jenkins-agent:latest
```

> **Why Port 2222?** Mapping container port `22` to host port `2222` prevents binding conflicts with the EC2 host's own OpenSSH daemon running on default port `22`.

---

#### Method B: Use Prebuilt Image from Docker Hub (Fastest)

If you prefer not to build the Dockerfile and want to pull `jasai/jenkins-agent:latest` directly:

```bash
# 1. Pull the image
docker pull jasai/jenkins-agent:latest

# 2. Run container and bind-mount your public key over authorized_keys
docker run -d \
  --name my-jenkins-agent \
  --restart unless-stopped \
  -p 2222:22 \
  -v /home/ec2-user/id_jenkins_agent.pub:/home/jenkins/.ssh/authorized_keys:ro \
  jasai/jenkins-agent:latest
```

> **How this works:** The `-v /host/path:/container/path:ro` flag overrides the baked-in key inside the container with your own public key in read-only mode, allowing your controller to authenticate immediately without rebuilding.

---

### 4. Configure Jenkins Master to Connect

1. Navigate to **Manage Jenkins** > **Nodes** > **New Node**.
2. Set **Node Name** (e.g., `ec2-docker-agent-01`) and choose **Permanent Agent**.
3. Configure the following fields:
   * **Remote root directory:** `/home/jenkins`
   * **Labels:** Assign appropriate pipeline tags (e.g., `linux`, `docker-agent`)
   * **Launch method:** Launch agents via SSH
   * **Host:** The **Private IP** of the Worker EC2 instance (if Controller and Worker are in the same VPC/Subnet) or its Public IP.
   * **Credentials:** Add a new **SSH Username with private key** credential:
     - **Scope:** Global
     - **ID:** `jenkins-agent-key`
     - **Username:** `jenkins`
     - **Private Key:** Select *Enter directly* and paste the entire content of `id_jenkins_agent` (generated in Step 1).
   * **Host Key Verification Strategy:** Select *Non-verifying Verification Strategy* or *Manually trusted key verification strategy*.
   * **Advanced > Port:** Change port to `2222` (matching your `-p 2222:22` mapping).
4. Save and click **Launch Agent**.

---

## AWS Security Group & Network Requirements

To allow the Jenkins Controller to communicate with the containerized agent:

1. **Worker EC2 Security Group:**
   * **Type:** Custom TCP
   * **Port Range:** `2222`
   * **Source:** The Private IP of the Jenkins Controller EC2 instance (or the Security Group ID of the Controller).
2. **Controller Outbound Rules:**
   * Ensure outbound traffic on port `2222` to the worker subnet is permitted.
3. **VPC Routing:**
   * Both instances should ideally reside in the same VPC (or peered VPCs) with private subnets for enhanced security.
  
---

## Security Notes

- **No passwords used or stored:** Password authentication is completely disabled in `sshd_config`.
- **Least-privilege execution:** The SSH session authenticates directly as the non-root `jenkins` user.
- **Root login disabled:** `PermitRootLogin no` is enforced at the daemon level.
- **Surface exposure minimization:** Host port `2222` should only accept inbound connections originating from the Jenkins Controller's IP address.

---

## How the Dockerfile Works (Step by Step)

1. **Base Image**  
   Uses Amazon Linux 2023 minimal base for a secure, lean operating system.

2. **Package Installation**  
   Installs OpenJDK 17, Git, Python 3, OpenSSH server, and shadow-utils 

3. **Non-Root User Creation**  
   Sets up the `jenkins` user with `/home/jenkins` as its home directory.

4. **SSH Directory Initialization**  
   Generates `/home/jenkins/.ssh` with POSIX permissions `700`.

5. **Key Injection**  
   Reads `JENKINS_PUB_KEY` build argument and creates `/home/jenkins/.ssh/authorized_keys` with permissions `600`.

6. **Daemon Hardening**  
   Generates host keys (`ssh-keygen -A`) and writes security directives to `/etc/ssh/sshd_config`.

7. **Port & Entrypoint**  
   Exposes container port `22` and executes `/usr/sbin/sshd -D` in the foreground to keep the container active.

8. **Start SSH Server**  
   Runs the SSH server in the foreground when the container starts.

---

## Typical Workflow

1. **Generate SSH Key Pair**  
   Create a key pair on your Jenkins master.

2. **Build the Docker Image**  
   Pass the public key as a build argument and tag the image.

3. **Run the Container**  
   Start the container and map port 22.

4. **Configure Jenkins Master**  
   Add a new agent node in Jenkins, set the remote root directory to `/home/jenkins`, and use the private key for SSH authentication.

---

## Example Dockerfile

See [`Dockerfile`](./Dockerfile) for the full setup.

---
