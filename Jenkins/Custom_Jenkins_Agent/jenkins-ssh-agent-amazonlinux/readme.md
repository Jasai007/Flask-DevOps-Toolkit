# Jenkins SSH Agent Docker Image

This Docker image provides a secure Jenkins agent environment using Amazon Linux, Java 17, and SSH key-based authentication. **No passwords or credentials are hardcoded.**

---

## Features

- Amazon Linux 2023 base image
- Installs Java 17, Git, Python3, and SSH server
- Creates a non-root `jenkins` user
- SSH access is allowed **only** for the `jenkins` user, using SSH keys (no passwords)
- Root SSH login is disabled

---

## Quick Start

### Use Prebuilt Image from Docker Hub

You can pull and run the prebuilt image directly from Docker Hub:

```sh
docker pull jasai/jenkins-agent:latest
```

When running the container, you must provide your public key as a build argument if you build locally, but the Docker Hub image already expects the key to be present at build time.  
If you need a custom key, build your own image as shown below.

---

## How to Use

### 1. Generate an SSH Key Pair

On your Jenkins master or local machine, run:

```sh
ssh-keygen -t rsa -b 2048 -f id_jenkins_agent
```

- This creates `id_jenkins_agent` (private key) and `id_jenkins_agent.pub` (public key).
- Leave the passphrase empty for automation.

---

### 2. Build the Docker Image (with Tag and Public Key)

```sh
docker build --build-arg JENKINS_PUB_KEY="$(cat id_jenkins_agent.pub)" -t jenkins-agent:latest .
```

- The public key is injected at build time; **no need to copy it manually into the container**.

---

### 3. Run the Container

```sh
docker run -d --name my-jenkins-agent jenkins-agent:latest
```

---

### 4. Configure Jenkins Master to Connect

- In Jenkins, add a new node.
- Set the **Remote root directory** to `/home/jenkins`.
- Set the **host** to your container’s IP or hostname. (`docker inspect my-jenkins-agent` will show the IP address).
- Set the **Credentials** to use the private key you generated (`id_jenkins_agent`) with no passphrase and username `jenkins`.
- Set the **Host Key Verification Strategy** to "Manually trusted key verification strategy" or "Non-verifying Verification Strategy" if you want to skip host key checking.
- Save the configuration.


---

## Security Notes

- **No passwords are used or stored.**
- Only the `jenkins` user can SSH in, and only with the correct private key.
- Root login is disabled.
- SSH key is injected at build time for automation and security.

---

## How the Dockerfile Works (Step by Step)

1. **Base Image**  
   Uses Amazon Linux 2023 for a stable, secure environment.

2. **Install Packages**  
   Installs Java 17 (required for Jenkins), Git, Python3, and OpenSSH server.

3. **Create Jenkins User**  
   Adds a non-root `jenkins` user for security.

4. **Prepare SSH for Jenkins User**  
   Creates the `.ssh` directory with correct permissions for the `jenkins` user.

5. **Add Public Key for Authentication**  
   Accepts your public key as a build argument and adds it to `authorized_keys` so only your Jenkins master can connect.

6. **Harden SSH Configuration**  
   - Disables password authentication (only key-based login allowed).
   - Disables root login.
   - Allows only the `jenkins` user to connect via SSH.

7. **Expose SSH Port**  
   Opens port 22 for SSH access.

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
