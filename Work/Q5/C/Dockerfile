# Use java base image
FROM openjdk:17-jdk-slim

# Set the working directory in the container
WORKDIR /app

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6 \
    libx11-6 \
    libxext6 \
    libxt6 \
    libxi6 \
    libxrender1 \
    libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

# Copy the application code into the container
COPY WatermarkPhotos.java .

# Copy Diagrams directory into the container
COPY Diagrams/ Diagrams/

# Compile the Java source file
RUN javac WatermarkPhotos.java

# Run the compiled Java application with an argument
CMD ["java", "WatermarkPhotos", "Diagrams/"]