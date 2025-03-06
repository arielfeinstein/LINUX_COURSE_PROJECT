# Use the official Python image as a base image
FROM python:3.9-slim-buster

# Update package lists and install necessary packages
RUN apt-get update && apt-get install -y python3-pip

# Install matplotlib and numpy using pip
RUN pip install matplotlib numpy

# Set the working directory
WORKDIR /app

# Command to run when the container starts
CMD ["bash"]