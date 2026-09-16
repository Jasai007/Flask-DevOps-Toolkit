# Multi-stage Dockerfile for a Flask application
# This Dockerfile uses multi-stage builds to optimize the final image size
# by separating the build environment from the production environment.
# The first stage installs dependencies and runs tests, while the final stage
# only includes the necessary files to run the application.

# Use the official Python image
FROM python:3.8-slim AS base

# Set the working directory to /app
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install the Python dependencies specified in requirements.txt
RUN pip install -r requirements.txt

# Copy the entire application code into the container
COPY . .

# Set environment variables for Flask application
ENV FLASK_APP=routes.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=80

# Expose port 80 for the Flask application
EXPOSE 80

# Test Stage: Create a separate stage for running tests
FROM base AS test
# Install dependencies again for the test stage
RUN pip install --no-cache-dir -r requirements.txt
# Command to run the unit tests
CMD ["python3", "-m", "unittest", "-v", "test.py"]

# Final Production Image: Create the final image for production
FROM base AS final
# Command to run the Flask application
CMD ["python", "routes.py"]
