# Jenkins Pipeline Overview

This Jenkinsfile defines a Continuous Integration and Continuous Deployment (CI/CD) pipeline for the Flask application. The pipeline is designed to automate the process of building, testing, and deploying the application using Docker.

## Pipeline Stages

1. **Checkout Code**: 
   - The pipeline starts by checking out the code from the main branch of the GitHub repository. This ensures that the latest version of the code is used for the build process.

2. **Install Dependencies and Run Tests**: 
   - In this stage, the pipeline upgrades `pip` and installs the required dependencies specified in the `requirements.txt` file. 
   - It also runs unit tests to ensure that the application is functioning correctly before proceeding to the next stage.

3. **Build Docker Image**: 
   - The pipeline builds a Docker image for the application using the Dockerfile located in the root of the repository. 
   - The image is tagged with the build number to keep track of different versions.

4. **Deploy Application**: 
   - Finally, the pipeline stops and removes any existing container running the application and deploys a new container using the newly built image. 
   - The application is run in detached mode and is accessible on port 80.

## Environment Variables

- `APP_NAME`: The name of the application container.
- `IMAGE_NAME`: The name of the Docker image.

This Jenkinsfile provides a robust framework for automating the deployment of the Flask application, ensuring that the latest code is always tested and deployed efficiently.
