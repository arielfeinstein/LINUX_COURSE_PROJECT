# Use a Python base image
FROM python:3.9-slim-buster

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Copy the application code into the container
COPY plant.py .

# Create a virtual environment
RUN python3 -m venv venv

# Activate the virtual environment and install dependencies
RUN . venv/bin/activate && pip install -r requirements.txt

# Set entrypoint
ENTRYPOINT ["venv/bin/python", "plant.py"]

# Set the default command
CMD ["--plant", "Rose", "--height", "50", "55", "60", "65", "70", "--leaf_count", "35", "40", "45", "50", "55", "--dry_weight", "2.0", "2.0", "2.1", "2.1", "3.0"]