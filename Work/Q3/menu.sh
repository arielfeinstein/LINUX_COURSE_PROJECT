#!/bin/bash

# Menu option strings
CREATE_CSV_AND_MARK_AS_CURRENT="Create a csv file and mark as current"
SELECT_FILE_AS_CURRENT="Select file as current"
SHOW_CURRENT_FILE="Show current file"
ADD_LINE_FOR_PLANT="Add a line for a plant"
RUN_PYTHON_SCRIPT_FOR_PLANT="Run improved python script for a plant to create plant diagrams"
MODIFY_PLANT_DATA="Modify a plant's data"
REMOVE_LINE="Remove a line by an index or by a plant name"
PRINT_HIGHEST_AVG_LEAF_COUNT="Print the plant with the highest average leaf count"
QUIT="Quit script"

# Gretting string
GREETTING_MSG="Select option by pressing the corresponding number"

# Global variables
current_filename=""
filenames_arr=()

# Function to find CSV files and populate filenames_arr
get_csv_files() {
  local i=1
  while [[ -f "$i.csv" ]]; do
    filenames_arr+=("$i.csv")
    i=$((i + 1))
  done
}

# Function to select current filename based on index
select_current_filename() {
  local index="$1"
  if [[ "$index" -ge 0 && "$index" -lt "${#filenames_arr[@]}" ]]; then
    current_filename="${filenames_arr[$index]}"
  else
    echo "Index out of range."
  fi
}

# Function to add a new CSV file and set it as current_filename
add_file() {
  local new_index=$(( ${#filenames_arr[@]} + 1 ))
  local new_filename="$new_index.csv"
  touch "$new_filename"
  echo "Plant,Height,Leaf Count,Dry Weight" >> "$new_filename"
  filenames_arr+=("$new_filename")
  current_filename="$new_filename"
}

# Function to validate CSV line data
validate_csv_line_data() {
  local height_str="$1"
  local leaf_count_str="$2"
  local dry_weight_str="$3"

  # Check if number strings are valid and have the same length
  local height_arr=($(echo "$height_str" | tr ' ' '\n'))
  local leaf_count_arr=($(echo "$leaf_count_str" | tr ' ' '\n'))
  local dry_weight_arr=($(echo "$dry_weight_str" | tr ' ' '\n'))

  local height_count=${#height_arr[@]}
  local leaf_count_count=${#leaf_count_arr[@]}
  local dry_weight_count=${#dry_weight_arr[@]}

  if [[ "$height_count" -ne "$leaf_count_count" || "$height_count" -ne "$dry_weight_count" ]]; then
    echo "Error: Number strings have different lengths."
    return 1
  fi

  # Check height_arr and dry_weight_arr for non-negative floats
  for num in "${height_arr[@]}" "${dry_weight_arr[@]}"; do
    if ! [[ "$num" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      echo "Error: Non-numeric or negative value found in height_arr or dry_weight_arr: $num"
      return 1
    fi
  done

  # Check leaf_count_arr for non-negative integers
  for num in "${leaf_count_arr[@]}"; do
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
      echo "Error: Non-integer or negative value found in leaf_count_arr: $num"
      return 1
    fi
  done
  return 0 # success
}

# Function to add a line to the CSV file
add_csv_line() {
  local plant_name="$1"
  local height_str="$2"
  local leaf_count_str="$3"
  local dry_weight_str="$4"

  if [[ -z "$current_filename" ]]; then
    echo "Error: Current filename is not set."
    return 1
  fi

  if grep -q "^$plant_name," "$current_filename"; then
    echo "Error: Plant '$plant_name' already exists in the file."
    return 1
  fi

  if ! validate_csv_line_data "$height_str" "$leaf_count_str" "$dry_weight_str"; then
    return 1
  fi

  # Add the line to the CSV file
  echo "$plant_name,$height_str,$leaf_count_str,$dry_weight_str" >> "$current_filename"
  echo "Line added"
}

# Function to modify a line in the CSV file
modify_csv_line() {
  local current_plant_name="$1"
  local height_str="$2"
  local leaf_count_str="$3"
  local dry_weight_str="$4"

  if [[ -z "$current_filename" ]]; then
    echo "Error: Current filename is not set."
    return 1
  fi

  if ! grep -q "^$current_plant_name," "$current_filename"; then
    echo "Error: Plant '$current_plant_name' does not exist in the file."
    return 1
  fi

  if ! validate_csv_line_data "$height_str" "$leaf_count_str" "$dry_weight_str"; then
    return 1
  fi

  # Modify the line in the CSV file
  sed -i "s/^$current_plant_name,.*$/$current_plant_name,$height_str,$leaf_count_str,$dry_weight_str/" "$current_filename"
  echo "Line modified"
}

# Function to remove a line from the CSV file
remove_csv_line() {
  local id="$1"
  local line_index=-1

  if [[ -z "$current_filename" ]]; then
    echo "Error: Current filename is not set."
    return 1
  fi

  if [[ "$id" =~ ^[0-9]+$ ]]; then
    # id is a number (line index)
    local line_count=$(wc -l < "$current_filename")
    if [[ "$id" -gt 0 && "$id" -lt "$line_count" ]]; then
      line_index="$((id+1))"
    else
      echo "Error: Line index out of range."
      return 1
    fi
  else
    # id is a plant name
    local found_line=$(grep -n "^$id," "$current_filename")
    if [[ -n "$found_line" ]]; then
      line_index=$(echo "$found_line" | cut -d':' -f1)
    else
      echo "Error: Plant '$id' not found."
      return 1
    fi
  fi

  if [[ "$line_index" -ne -1 ]]; then
    # Remove the line using sed
    sed -i "${line_index}d" "$current_filename"
    echo "Line removed"
  fi
}

# Function to print the plant with the highest average leaf count
print_plant_with_highest_average_leaf_count() {
  # Check current_filename is set
  if [[ -z "$current_filename" ]]; then
    echo "Error: Current filename is not set."
    return 1
  fi

  # Check file contains data
  local line_count=$(wc -l < "$current_filename")
  if [[ "$line_count" -lt 2 ]]; then
    echo "Error: File contains no data."
    return 1
  fi

  # Max variables
  local highest_average=0.0
  local highest_plant=""

  # Read data from current csv file
  while IFS=',' read -r plant_name height_str leaf_count_str dry_weight_str; do
    local leaf_count_arr=($(echo "$leaf_count_str" | tr ' ' '\n')) # Convert to array
    local total_leaf_count=0
    local leaf_count_arr_length=${#leaf_count_arr[@]} 

    if [[ "$leaf_count_arr_length" -eq 0 ]]; then
      continue # Skip if no leaf count data
    fi

    # Summing leaf_count_arr
    for leaf_count in "${leaf_count_arr[@]}"; do
      total_leaf_count=$((total_leaf_count + leaf_count))
    done

    # Calculate average
    local average=$(bc <<< "scale=2; $total_leaf_count / $leaf_count_arr_length")

    # Update max variables if current average is bigger than current highest_average
    if [[ $(echo "$average > $highest_average" | bc) -eq 1 ]]; then
      highest_average="$average"
      highest_plant="$plant_name"
    fi
  done < <(tail -n +2 "$current_filename") # <-- Process substitution avoids subshell issue

  if [[ -n "$highest_plant" ]]; then
    echo "Plant with highest average leaf count: $highest_plant (Average: $highest_average)"
  else
    echo "No plant found."
  fi
}


# Function to execute the python script
execute_python_script() {
  local plant_name="$1"

  if [[ -z "$current_filename" ]]; then
    echo "Error: Current filename is not set."
    return 1
  fi

  local line=$(grep "^$plant_name," "$current_filename")
  if [[ -z "$line" ]]; then
    echo "Error: Plant '$plant_name' not found."
    return 1
  fi

  local height_str=$(echo "$line" | cut -d',' -f2)
  local leaf_count_str=$(echo "$line" | cut -d',' -f3)
  local dry_weight_str=$(echo "$line" | cut -d',' -f4)

  # Split the strings into individual words
  local height_arr=($height_str)
  local leaf_count_arr=($leaf_count_str)
  local dry_weight_arr=($dry_weight_str)

  # Pass the individual words as separate arguments
  python3 plant.py --plant "$plant_name" --height "${height_arr[@]}" --leaf_count "${leaf_count_arr[@]}" --dry_weight "${dry_weight_arr[@]}"
}

# Main function to handle menu and script flow
main() {
    # Check for existing CSV files
    get_csv_files

    # If no CSV files exist, create a new one
    if [[ ${#filenames_arr[@]} -eq 0 ]]; then
        echo "No CSV files found. Creating a new file."
        add_file
    fi

    # Greet the user
    echo "Welcome to Plant Tracking System!"
    echo "$GREETTING_MSG"

    # Main menu loop
    while true; do
        # Display menu options with numbers
        echo ""
        echo "1) $CREATE_CSV_AND_MARK_AS_CURRENT"
        echo "2) $SELECT_FILE_AS_CURRENT"
        echo "3) $SHOW_CURRENT_FILE"
        echo "4) $ADD_LINE_FOR_PLANT"
        echo "5) $RUN_PYTHON_SCRIPT_FOR_PLANT"
        echo "6) $MODIFY_PLANT_DATA"
        echo "7) $REMOVE_LINE"
        echo "8) $PRINT_HIGHEST_AVG_LEAF_COUNT"
        echo "9) $QUIT"

        # Prompt for user input
        read -p "Enter your choice (1-9): " choice

        echo ""

        # Handle menu options
        case $choice in
            1)  # Create CSV and mark as current
                add_file
                echo "New CSV file created and set as current: $current_filename"
                ;;
            2)  # Select file as current
                if [[ ${#filenames_arr[@]} -eq 0 ]]; then
                    echo "No CSV files available."
                    continue
                fi
                echo "Available CSV files:"
                for i in "${!filenames_arr[@]}"; do
                    echo "$i) ${filenames_arr[$i]}"
                done
                read -p "Enter file index: " file_index
                select_current_filename "$file_index"
                echo "Current file set to: $current_filename"
                ;;
            3)  # Show current file
                if [[ -z "$current_filename" ]]; then
                    echo "No current file selected."
                else
                    echo "Current file contents:"
                    cat "$current_filename"
                fi
                ;;
            4)  # Add line for a plant
                read -p "Enter plant name: " plant_name
                read -p "Enter height (space-separated): " height
                read -p "Enter leaf count (space-separated): " leaf_count
                read -p "Enter dry weight (space-separated): " dry_weight
                add_csv_line "$plant_name" "$height" "$leaf_count" "$dry_weight"
                ;;
            5)  # Run Python script for a plant
                read -p "Enter plant name to generate diagram: " plant_name
                execute_python_script "$plant_name"
                ;;
            6)  # Modify plant data
                read -p "Enter plant name: " current_plant
                read -p "Enter new height (space-separated): " height
                read -p "Enter new leaf count (space-separated): " leaf_count
                read -p "Enter new dry weight (space-separated): " dry_weight
                modify_csv_line "$current_plant" "$height" "$leaf_count" "$dry_weight"
                ;;
            7)  # Remove line
                read -p "Enter plant name or line index to remove: " remove_id
                remove_csv_line "$remove_id"
                ;;
            8)  # Print plant with highest average leaf count
                print_plant_with_highest_average_leaf_count
                ;;
            9)  # Quit
                echo "Exiting Plant Tracking System. Goodbye!"
                exit 0
                ;;
            *)  # Invalid option
                echo "Invalid option. Please enter a number between 1 and 9."
                ;;
        esac
    done
}

# Call the main function
main