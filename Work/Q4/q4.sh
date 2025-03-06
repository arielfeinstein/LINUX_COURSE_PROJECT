#!/bin/bash

# Set up logging
LOG_FILE="out.log"
ERROR_LOG="error.log"

# Log function
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> $LOG_FILE
}

# Usage function
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -c, -csv FILE       Specify the CSV file path"
    echo "  -p, -python FILE    Specify the Python script path"
    exit 1
}

log "Script started"

# Initialize variables
CSV_FILE=""
PYTHON_SCRIPT="./plant.py"  # Default python script path

# Parse arguments manually to support both short and long options
i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        -c|-csv)
            i=$((i+1))
            if [ $i -le $# ]; then
                CSV_FILE="${!i}"
                log "CSV file provided with $arg flag: $CSV_FILE"
            else
                log "ERROR: No value provided for $arg flag"
                echo "ERROR: No value provided for $arg flag" >&2
                usage
            fi
            ;;
        -p|-python)
            i=$((i+1))
            if [ $i -le $# ]; then
                PYTHON_SCRIPT="${!i}"
                log "Python script path provided with $arg flag: $PYTHON_SCRIPT"
            else
                log "ERROR: No value provided for $arg flag"
                echo "ERROR: No value provided for $arg flag" >&2
                usage
            fi
            ;;
        -h|-help|--help)
            usage
            ;;
        *)
            log "ERROR: Unknown option: $arg"
            echo "ERROR: Unknown option: $arg" >&2
            usage
            ;;
    esac
    i=$((i+1))
done

# If CSV file is not provided with flag, try to find one
if [ -z "$CSV_FILE" ]; then
    # Find first CSV file in current directory if no argument provided
    FIRST_CSV=$(find . -maxdepth 1 -name "*.csv" | head -n 1)
    if [ -n "$FIRST_CSV" ]; then
        CSV_FILE=$FIRST_CSV
        log "No CSV file provided with flag. Using found CSV file: $CSV_FILE"
    else
        log "ERROR: No CSV file provided or found in current directory"
        echo "ERROR: No CSV file provided or found in current directory" >&2
        usage
    fi
fi

# Check if CSV file exists
if [ ! -f "$CSV_FILE" ]; then
    log "ERROR: CSV file not found at $CSV_FILE"
    echo "ERROR: CSV file not found at $CSV_FILE" >> $ERROR_LOG
    exit 1
fi
log "CSV file found: $CSV_FILE"

# Check if Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    log "ERROR: Python script not found at $PYTHON_SCRIPT"
    echo "ERROR: Python script not found at $PYTHON_SCRIPT" >> $ERROR_LOG
    exit 1
fi
log "Python script found: $PYTHON_SCRIPT"

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
    
    # Run PYTHON_SCRIPT script with arguments

    # Delete double quotes characters - because my python script needs data seperatly
    height=$(echo "$height" | tr -d '"')
    leaf_count=$(echo "$leaf_count" | tr -d '"')
    dry_weight=$(echo "$dry_weight" | tr -d '"')
    
    # Split the strings into individual words
    height_arr=($height)
    leaf_count_arr=($leaf_count)
    dry_weight_arr=($dry_weight)

    log "Running "$PYTHON_SCRIPT" for $plant with height="${height_arr[@]}", leaf_count="${leaf_count_arr[@]}", dry_weight="${dry_weight_arr[@]}""
    OUTPUT=$(python "$PYTHON_SCRIPT" --plant "$plant" --height "${height_arr[@]}" --leaf_count "${leaf_count_arr[@]}" --dry_weight "${dry_weight_arr[@]}" 2>> $ERROR_LOG)
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