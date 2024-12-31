#!/bin/bash

# Read configuration
CONFIG_FILE="config/sources.json"
RAW_DIR="data/raw"
PROCESSED_DIR="data/processed"

# Process each source
for source in $(jq -r '.sources[].name' "$CONFIG_FILE"); do
    echo "Processing $source..."
    
    # Get Access file path
    ACCESS_FILE="$RAW_DIR/$source/*.mdb"
    OUTPUT_DIR="$PROCESSED_DIR/$source"
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Get and export tables
    tables=$(mdb-tables "$ACCESS_FILE")
    for table in $tables; do
        echo "Exporting $table..."
        mdb-export "$ACCESS_FILE" "$table" > "$OUTPUT_DIR/${table}.csv"
    done
done