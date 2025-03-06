#!/bin/bash

# Set up logging
LOG_FILE="out.log"
ERROR_LOG="error.log"

# Log function
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> $LOG_FILE
}

log "Script started"

# Parse arguments
CSV_FILE=""
if [ $# -eq 1 ]; then
    CSV_FILE=$1
    log "CSV file provided as argument: $CSV_FILE"
else
    # Find first CSV file in current directory if no argument provided
    FIRST_CSV=$(find . -maxdepth 1 -name "*.csv" | head -n 1)
    if [ -n "$FIRST_CSV" ]; then
        CSV_FILE=$FIRST_CSV
        log "No CSV file provided. Using found CSV file: $CSV_FILE"
    else
        log "ERROR: No CSV file provided or found in current directory"
        echo "ERROR: No CSV file provided or found in current directory" >> $ERROR_LOG
        exit 1
    fi
fi

# Check if CSV file exists
if [ ! -f "$CSV_FILE" ]; then
    log "ERROR: CSV file not found at $CSV_FILE"
    echo "ERROR: CSV file not found at $CSV_FILE" >> $ERROR_LOG
    exit 1
fi
log "CSV file found: $CSV_FILE"

# Check if requirements.txt exists
REQUIREMENTS_FILE=""
if [ -f "./requirements.txt" ]; then
    REQUIREMENTS_FILE="./requirements.txt"
    log "Requirements file found: $REQUIREMENTS_FILE"
else
    log "No requirements.txt file found in current directory"
fi

# Check if .gitignore exists two directories up and create if needed
GITIGNORE_PATH="../../.gitignore"
if [ -f "$GITIGNORE_PATH" ]; then
    log ".gitignore file found at $GITIGNORE_PATH"
    
    # Check if Work/Q4/venv exists in .gitignore
    if ! grep -q "Work/Q4/venv" "$GITIGNORE_PATH"; then
        log "Adding Work/Q4/venv to .gitignore"
        echo "Work/Q4/venv" >> "$GITIGNORE_PATH"
    else
        log "Work/Q4/venv already exists in .gitignore"
    fi
else
    log ".gitignore file not found at $GITIGNORE_PATH, creating it"
    # Create parent directories if needed
    mkdir -p "../../"
    echo "Work/Q4/venv" > "$GITIGNORE_PATH"
    log "Created .gitignore and added Work/Q4/venv"
fi

# Check if plant.py exists
if [ ! -f "./plant.py" ]; then
    log "ERROR: plant.py script not found"
    echo "ERROR: plant.py script not found" >> $ERROR_LOG
    exit 1
fi
log "plant.py found"

# Create and activate virtual environment
if [ ! -d "./venv" ]; then
    log "Creating virtual environment"
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to create virtual environment"
        echo "ERROR: Failed to create virtual environment" >> $ERROR_LOG
        exit 1
    fi
else
    log "Virtual environment already exists"
fi

log "Activating virtual environment"
source venv/bin/activate
if [ $? -ne 0 ]; then
    log "ERROR: Failed to activate virtual environment"
    echo "ERROR: Failed to activate virtual environment" >> $ERROR_LOG
    exit 1
fi

# Install requirements if present
if [ -n "$REQUIREMENTS_FILE" ]; then
    log "Installing requirements from $REQUIREMENTS_FILE"
    pip install -r "$REQUIREMENTS_FILE" >> $LOG_FILE 2>> $ERROR_LOG
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to install requirements"
        echo "ERROR: Failed to install requirements" >> $ERROR_LOG
        exit 1
    fi
fi

# Process CSV file
log "Processing CSV file: $CSV_FILE"

# Using tail to skip the header line
tail -n +2 "$CSV_FILE" | while IFS=, read -r plant height leaf_count dry_weight; do
    log "Processing plant: $plant"
    
    # Create plant directory
    mkdir -p "./Diagrams/$plant"
    
    # Run plant.py script with arguments

    # Delete double quotes characters - because my python script needs data seperatly
    height=$(echo "$height" | tr -d '"')
    leaf_count=$(echo "$leaf_count" | tr -d '"')
    dry_weight=$(echo "$dry_weight" | tr -d '"')
    
    # Split the strings into individual words
    height_arr=($height)
    leaf_count_arr=($leaf_count)
    dry_weight_arr=($dry_weight)

    log "Running plant.py for $plant with height="${height_arr[@]}", leaf_count="${leaf_count_arr[@]}", dry_weight="${dry_weight_arr[@]}""
    OUTPUT=$(python plant.py --plant "$plant" --height "${height_arr[@]}" --leaf_count "${leaf_count_arr[@]}" --dry_weight "${dry_weight_arr[@]}" 2>> $ERROR_LOG)
    EXIT_CODE=$?

    # Move png files
    mv *.png "./Diagrams/$plant/"
    log "PNG files moved to ./Diagrams/$plant/"
    
    # Log the output and status
    log "Script output:\n$OUTPUT\n"
    if [ $EXIT_CODE -eq 0 ]; then
        log "Script executed successfully for plant: $plant"
    else
        log "ERROR: Script failed for plant: $plant with exit code: $EXIT_CODE"
    fi
done

log "Deactivating virtual environment"
deactivate

log "Script completed successfully"
exit 0