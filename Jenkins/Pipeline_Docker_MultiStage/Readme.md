# Jenkins Pipeline: Containerized Testing with Multi-Stage Dockerfile

This directory contains a Declarative Jenkins Pipeline demonstrating the **Containerized Testing & Multi-Stage Build Pattern**. 

Instead of installing runtime tools, package managers, and dependencies directly onto the Jenkins agent host, this pipeline shifts the entire testing and packaging lifecycle into isolated Docker stages.

---

## Key Highlights

- **Decoupled Agent Execution:** The Jenkins agent requires only the Docker CLI. It does not require Python, pip, or virtual environments installed on the host.
- **Isolated Testing (`--target test`):** Unit tests execute inside an ephemeral, throwaway container layer created directly from the multi-stage `Dockerfile`.
- **Zero Host Contamination:** Test dependencies and caches are discarded automatically upon completion (`docker run --rm`), eliminating workspace clutter and version drift.
- **Production-Lean Final Image:** Builds an optimized production artifact without leaking test frameworks or development libraries into the running application.

---

## Directory Structure

```text
Pipeline_Docker_MultiStage/
├── Dockerfile        # Multi-stage Dockerfile containing build, test, and production targets
├── Jenkinsfile       # Declarative Jenkins pipeline script
└── README.md         # Documentation for this pipeline pattern
```

---

## Pipeline Workflow & Stages

```text
[Checkout Code] 
       │
       ▼
[Run Tests in Docker] ──► docker build --target test ──► docker run --rm test-container
       │
       ▼
[Build Production Image] ──► docker build -t $IMAGE_NAME .
       │
       ▼
[Deploy / Run] ──► docker run -d -p 80:80 --name $CONTAINER_NAME $IMAGE_NAME
```

### 1. Checkout Code
- Pulls the latest source code from the repository:  
  `https://github.com/Jasai007/Flask-DevOps-Toolkit.git` on the `main` branch.

### 2. Run Tests in Docker
- Leverages Docker's target flag (`--target test`) to build only up to the testing stage defined in the `Dockerfile`.
- Executes unit tests inside an isolated container (`docker run --rm test-container`).
- If the unit tests fail, the container exits with a non-zero code, failing the Jenkins build before production packaging begins.

### 3. Build Docker Image
- Builds the final, hardened production Docker image using the full multi-stage target:
  ```bash
  docker build -t $IMAGE_NAME .
  ```
- Intermediate test layers, dev dependencies, and cache artifacts are omitted from this final production layer.

### 4. Run Container
- Safely cleans up any running or dead container matching `$CONTAINER_NAME`.
- Deploys the freshly built production container, mapping host port `80` to container port `80`:
  ```bash
  docker run -d -p 80:80 --name $CONTAINER_NAME $IMAGE_NAME
  ```

---

## Environment Variables

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `IMAGE_NAME` | `dockerimg` | Name and tag assigned to the final production Docker image. |
| `CONTAINER_NAME` | `MyApp` | Name assigned to the active deployment container. |

---

## Why Choose This Approach Over Host-Based Testing?

| Vector | Host-Based Testing | Multi-Stage Docker Testing (This Setup) |
| :--- | :--- | :--- |
| **Host Tool Requirements** | Must install and maintain Python 3, pip, and compilers | Only requires Docker installed on the host |
| **Workspace Cleanliness** | Pip caches and dependencies accumulate on the host | Completely clean; ephemeral container destroyed via `--rm` |
| **Reproducibility** | Sensitive to local host OS library updates | 100% reproducible; pinned via base Docker image |
| **Security Surface** | Tests execute with agent host user privileges | Tests execute in a confined container sandbox |
