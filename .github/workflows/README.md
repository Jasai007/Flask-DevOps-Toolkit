# GitHub Workflows for CI/CD

This directory contains GitHub Actions workflows for Continuous Integration and Continuous Deployment (CI/CD) of the Flask application.

## Workflows

### 1. `main-selfhosted.yml`
This workflow is designed to run on a self-hosted runner. It triggers on:
- Push events to the `main` branch
- Pull requests targeting the `main` branch
- Manual triggers via the GitHub Actions interface

#### Steps:
- **Checkout Repository**: Clones the repository to the runner.
- **Install Dependencies**: Installs Python dependencies from `requirements.txt`.
- **Run Unit Tests**: Executes unit tests defined in `test.py`.
- **Set up Docker**: Prepares the Docker environment.
- **Build Docker Image**: Builds a Docker image using the Dockerfile in the repository.
- **Stop and Remove Existing Container**: Stops and removes any existing container with the specified name.
- **Run Docker Container**: Runs the newly built Docker container.
- **Verify Running Container**: Checks the status of the running container.
- **Show Container Logs**: Displays logs from the container for debugging purposes.

### 2. `main-githosted.yml`
This workflow is designed to run on GitHub-hosted runners. It triggers on:
- Push events to the `main` branch
- Pull requests targeting the `main` branch
- Manual triggers via the GitHub Actions interface

#### Steps:
- **Checkout Repository**: Clones the repository to the runner.
- **Set up Python**: Configures the Python environment with the specified version.
- **Install Dependencies**: Installs Python dependencies from `requirements.txt`.
- **Run Unit Tests**: Executes unit tests defined in `test.py`.
- **Set up Docker**: Prepares the Docker environment.
- **Build Docker Image**: Builds a Docker image using the Dockerfile in the repository.
- **Run Docker Container**: Stops and removes any existing container with the specified name, then runs the newly built Docker container.

This README provides an overview of the workflows and their respective steps to facilitate understanding and maintenance of the CI/CD processes.
