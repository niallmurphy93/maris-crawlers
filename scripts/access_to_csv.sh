#!/bin/bash

# Read configuration
CONFIG_FILE="config/sources.json"
RAW_DIR="data/raw"
PROCESSED_DIR="data/processed"

# Process each source
jq -c '.sources[]' "$CONFIG_FILE" | while read -r source; do
    name=$(echo "$source" | jq -r '.name')
    type=$(echo "$source" | jq -r '.type')

    # Only process Access databases
    if [ "$type" != "access" ]; then
        echo "Skipping non-Access source: $name"
        continue
    fi

    echo "Processing $source..."
    
    # Look for both .mdb and .accdb files
    ACCESS_FILE=""
    for ext in "mdb" "accdb"; do
        found_file=$(find "$RAW_DIR/$name" -name "*.$ext" -print -quit)
        if [ -n "$found_file" ]; then
            ACCESS_FILE="$found_file"
            break
        fi
    done

    if [ -z "$ACCESS_FILE" ]; then
        echo "No Access database file found for $name"
        continue
    fi

    OUTPUT_DIR="$PROCESSED_DIR/$name"
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Get and export tables
    echo "Found database: $ACCESS_FILE"
    tables=$(mdb-tables "$ACCESS_FILE")
    for table in $tables; do
        echo "Exporting $table..."
        mdb-export "$ACCESS_FILE" "$table" > "$OUTPUT_DIR/${table}.csv"
    done
done