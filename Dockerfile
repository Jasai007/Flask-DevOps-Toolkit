# Use the official Python image
FROM python:3.8-slim AS base


# Set the working directory
WORKDIR /app

# Copy the requirements file
COPY requirements.txt .

# Install dependencies
RUN pip install -r requirements.txt

# Copy the application code
COPY . .

# Set Flask environment variables
ENV FLASK_APP=routes.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=80

# Expose the port
EXPOSE 80

# Test Stage
FROM base AS test
RUN pip install --no-cache-dir -r requirements.txt
CMD ["python3", "-m", "unittest", "-v", "test.py"]

# Final Production Image
FROM base AS final
CMD ["python", "routes.py"]
