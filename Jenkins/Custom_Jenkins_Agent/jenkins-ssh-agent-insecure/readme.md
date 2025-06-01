# Jenkins SSH-Enabled Amazon Linux Docker Image

This Dockerfile builds a Docker image based on **Amazon Linux 2023** with Java 17, SSH server, and essential tools pre-installed. It is designed for scenarios where you need SSH access (including root) to a container, such as for Jenkins agents or remote administration in CI/CD pipelines.

---

## What This Dockerfile Does

1. **Base Image**  
   Uses `amazonlinux:2023` as the starting point.

2. **System Update & Package Installation**  
   - Updates all system packages.
   - Installs `git`, `wget`, `openssh-server`, `shadow-utils`, and `python3`.

3. **Java 17 Installation**  
   - Downloads and installs Oracle JDK 17.

4. **Root Password Setup**  
   - Sets the root password to `redhat` (for demonstration/testing).

5. **SSH Server Configuration**  
   - Generates SSH host keys.
   - Enables password authentication.
   - Allows root login via SSH.

6. **Expose SSH Port**  
   - Exposes port 22 for SSH access.

7. **Container Startup**  
   - Starts the SSH daemon in the foreground when the container runs.

---

## How to Build and Run

### 1. Build the Image

```sh
docker build -t jenkinsworker . 
```

### 2. Run the Container

```sh
docker run -d --name my-jenkins-agent  jenkins-ssh-agent
```
- This maps container port 22 to host port 2222.

### 3. SSH into the Container

```sh
ssh root@localhost -p 2222
```
- Password: `redhat`

---

## Where to Use

- **Jenkins SSH agents** (for testing or internal CI/CD).
- **Development and debugging** environments where SSH access is needed.
- **Automated scripts** that require SSH into a container.

---

## Cautions & Security Notes

- **Root SSH Login Enabled:**  
  Root login is enabled and the password is hardcoded (`redhat`).  
  **Never use this image in production or on public networks.**

- **Password Authentication:**  
  Password authentication is enabled, which is less secure than SSH key authentication.

- **For Production:**  
  - Disable root login.
  - Use SSH keys instead of passwords.
  - Use a non-root user for SSH access.
  - Change or randomize passwords.

---

## Customization

To make this image more secure:
- Replace the root password with a strong, unique one or use SSH keys.
- Disable root login by changing `PermitRootLogin yes` to `no` in `/etc/ssh/sshd_config`.
- Create a dedicated user for SSH access.

---

## License

MIT

---