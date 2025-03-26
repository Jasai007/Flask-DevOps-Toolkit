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

### Jenkins Freestyle Project
Located in the `Freestyle_pipeline` folder, this project is designed to streamline CI/CD workflows using Jenkins.

### Test Jenkins Through Docker Agent
Located in the `Test_Jenkinsfile` folder, this project focuses on testing Jenkins using a Docker agent for a flexible and isolated environment.

