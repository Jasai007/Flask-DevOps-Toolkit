# SonarQube Docker Compose Setup

This file provides instructions and information about the Docker Compose configuration for running SonarQube, a popular platform for continuous inspection of code quality.

## Overview

SonarQube performs automatic static code analysis to detect bugs, code smells, and security vulnerabilities in your projects. This Docker Compose setup allows you to quickly start a SonarQube server locally for code quality inspection and integration with your CI/CD pipelines.

## Files

- `sonarqube_docker-compose.yml`: Docker Compose file to start SonarQube and its dependencies.

## Prerequisites

- Docker and Docker Compose installed on your machine.
- Sufficient system resources (at least 2GB RAM recommended for SonarQube).

## Usage

1. Navigate to this folder:
   ```bash
   cd docker-compose
   ```

2. Start SonarQube using Docker Compose:
   ```bash
   docker-compose up -d
   ```

3. Access the SonarQube web interface by opening your browser and navigating to:
   ```
   http://<your-ip>:9000
   ```

4. To stop SonarQube, run:
   ```bash
   docker-compose down
   ```

## Additional Information

- Default login credentials are usually:
  - Username: `admin`
  - Password: `admin`

- For more details on configuring and using SonarQube, visit the [official SonarQube documentation](https://docs.sonarqube.org/latest/).

## License

This setup is provided as-is under the project license.
