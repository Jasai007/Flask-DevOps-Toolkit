# Jenkins Pipeline for Multi-Stage Dockerfile

This repository contains a Jenkins pipeline configuration for automating the build and deployment of a Flask application using a multi-stage Dockerfile. The pipeline is defined in the `jenkinsfile` located in the `Pipelines/Multi-Stage_Dockerfile` directory and consists of several stages to ensure a smooth CI/CD process.

## Pipeline Stages

1. **Checkout Code**
   - The pipeline begins by checking out the code from the main branch of the GitHub repository.
   - Repository URL: `https://github.com/Jasai007/Flask-DevOps-Toolkit.git`

2. **Install Dependencies and Run Tests**
   - In this stage, the pipeline installs the required Python dependencies specified in the `requirements.txt` file.
   - It runs unit tests using Python's unittest framework to ensure that the application is functioning correctly.

3. **Build Docker Image**
   - The pipeline builds a Docker image for the application using the multi-stage Dockerfile located in the same directory.
   - The image is tagged with the name specified in the environment variable `IMAGE_NAME`.

4. **Run Container**
   - Finally, the pipeline stops and removes any existing container with the name specified in the environment variable `CONTAINER_NAME`.
   - It then runs a new container from the built image, mapping port 80 of the container to port 80 of the host.

## Environment Variables
- `IMAGE_NAME`: The name of the Docker image to be built (default: `dockerimg`).
- `CONTAINER_NAME`: The name of the Docker container to be run (default: `MyApp`).

This Jenkins pipeline automates the process of building, testing, and deploying the Flask application using a multi-stage Dockerfile, ensuring that the latest changes are always reflected in the deployed version.
