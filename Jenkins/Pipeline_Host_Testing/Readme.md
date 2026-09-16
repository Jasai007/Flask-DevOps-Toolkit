# Jenkins Pipeline: Host-Based Testing Pattern

This directory contains a Declarative Jenkins Pipeline demonstrating the **Host-Based Testing Pattern**. 

In this pattern, dependency installation and unit testing execute directly within the Jenkins agent's host operating system environment before building and deploying the final application using the project's root `Dockerfile`.

---

## Key Characteristics

- **Host-Level Execution:** Dependencies (`requirements.txt`) and test suites (`unittest`) run directly on the Jenkins worker node using the agent's installed Python 3 runtime and pip package manager.
- **Sequential Validation:** The pipeline verifies code correctness at the host level first; Docker packaging only triggers if all unit tests pass.
- **Agent Prerequisites:** The build agent must have `python3`, `pip`, and necessary build libraries pre-installed in its environment.
- **Root Dockerfile Context:** Builds the runtime container directly from the application's root `Dockerfile` once host-level validation succeeds.

---

## Directory Structure

```text
└── Jenkins/
    └── Pipeline_Host_Testing/
        ├── Jenkinsfile         # Declarative Jenkins pipeline script
        └── README.md           # Documentation for this pipeline pattern
```

---

## Pipeline Workflow & Stages

```text
[Checkout Code]
       │
       ▼
[Install Dependencies & Run Tests] ──► pip install & python3 -m unittest (on host)
       │
       ▼
[Build Docker Image] ──► docker build -t $IMAGE_NAME . (uses root Dockerfile)
       │
       ▼
[Run Container] ──► docker run -d -p 80:80 --name $CONTAINER_NAME $IMAGE_NAME
```

### 1. Checkout Code
- Clones the latest commit from the repository:  
  `https://github.com/Jasai007/Flask-DevOps-Toolkit.git` on the `main` branch.

### 2. Install Dependencies and Run Tests
- Installs application requirements directly onto the agent host:
  ```bash
  pip install --no-cache-dir -r requirements.txt
  ```
- Executes unit tests using Python's native test runner:
  ```bash
  python3 -m unittest -v test.py
  ```
- **Fails fast:** If any test fails, execution halts immediately, preventing an untested or broken image from being built.

### 3. Build Docker Image
- Packages the verified application using the root `Dockerfile`:
  ```bash
  docker build -t $IMAGE_NAME .
  ```

### 4. Run Container
- Stops and removes any previously running container sharing the same name to prevent port collisions:
  ```bash
  docker stop $CONTAINER_NAME || true
  docker rm $CONTAINER_NAME || true
  ```
- Deploys the freshly built container in detached mode, binding host port `80` to container port `80`:
  ```bash
  docker run -d -p 80:80 --name $CONTAINER_NAME $IMAGE_NAME
  ```

---

## Environment Variables

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `IMAGE_NAME` | `dockerimg` | Tag assigned to the generated Docker image. |
| `CONTAINER_NAME` | `MyApp` | Identifier for the running Docker container instance. |

---

## Architectural Trade-offs

| Factor | Host-Based Testing (This Setup) | Containerized Multi-Stage Testing |
| :--- | :--- | :--- |
| **Agent Setup** | Heavy (Agent requires Python 3, Pip, and dependencies) | Lean (Agent only requires the Docker CLI) |
| **Dependency Isolation** | Low (Packages install into the agent host environment) | Complete (Tests run inside disposable container layers) |
| **Dockerfile Location** | References the standard root `Dockerfile` | Uses a dedicated multi-stage `Dockerfile` with build targets |
| **Failure Point** | Host shell step (`sh`) | Docker build step (`--target test`) |
| **Best Used For** | Simple pipelines, rapid local validation, static agent pools | Production CI/CD, ephemeral nodes, heterogeneous runtimes |
