# Jenkins Pipeline Overview

This Jenkinsfile automates the Continuous Integration and Continuous Deployment (CI/CD) process for the Flask application using Docker. It streamlines the workflow of building, testing, and deploying the application.

## Pipeline Stages

1. **Checkout Code**: 
   - The pipeline begins by checking out the latest code from the main branch of the GitHub repository, ensuring that the most recent version is used for the build.

2. **Install Dependencies and Run Tests**: 
   - This stage upgrades `pip` and installs the required dependencies listed in the `requirements.txt` file. 
   - It also executes unit tests to verify that the application is functioning correctly before proceeding.

3. **Build Docker Image**: 
   - The pipeline builds a Docker image for the application using the Dockerfile located in the root directory. 
   - The image is tagged with the build number for version tracking.

4. **Deploy Application**: 
   - The pipeline stops and removes any existing container running the application, then deploys a new container using the newly built image. 
   - The application runs in detached mode and is accessible on port 80.

## Environment Variables

- `APP_NAME`: Specifies the name of the application container.
- `IMAGE_NAME`: Defines the name of the Docker image.

This Jenkinsfile provides a robust framework for automating the deployment of the Flask application, ensuring that the latest code is always tested and deployed efficiently.
