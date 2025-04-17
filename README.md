# Flask DevOps Toolkit

A web app built with Flask, providing tools and features for automating DevOps practices, including CI/CD integration and AWS deployment management.

## Installation Instructions

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/flask-devops-toolkit.git
   cd flask-devops-toolkit
   ```

2. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Usage

To run the application, use the following command:
```bash
flask run
```
Make sure to set the `FLASK_APP` environment variable to the main application file if necessary.

## Features

- CI/CD integration for automated deployments.
- AWS deployment management tools.
- User-friendly interface for managing DevOps tasks.

## Project Structure

- `templates/`: Contains HTML templates for rendering views.
- `static/`: Contains static files such as CSS and images.
- `routes.py`: Defines the application routes.
- `test.py`: Contains tests for the application.
- `Dockerfile`: Instructions for building a Docker image for the application.

## Other Projects

### Jenkins Pipeline Projects
All Jenkins pipeline scripts have been consolidated into the `Pipelines` folder, which contains the following subfolders:

1. **Freestyle Pipeline**
   - Located in the [`Pipelines/Freestyle_pipeline/`](./Pipelines/Freestyle_pipeline/) folder.
   - This project is designed to streamline CI/CD workflows using Jenkins Jobs.

2. **Multi-Stage Dockerfile**
   - Located in the [`Pipelines/Multi-Stage_Dockerfile/`](./Pipelines/Multi-Stage_Dockerfile/) folder.
   - This project contains a Jenkins pipeline configuration for automating the build and deployment of a Flask application using a multi-stage Dockerfile.

3. **Test Jenkins Through Docker Agent**
   - Located in the [`Pipelines/Test_Jenkinsfile/`](./Pipelines/Test_Jenkinsfile/) folder.
   - This project focuses on testing Jenkins using a Docker agent for a flexible and isolated environment to run your CI/CD pipelines.

## GitHub Workflows

This project includes GitHub Actions workflows for Continuous Integration and Continuous Deployment (CI/CD) located in the `.github/workflows` directory. For detailed descriptions of each workflow, please refer to the [README file in the workflows directory](./.github/workflows/README.md).
