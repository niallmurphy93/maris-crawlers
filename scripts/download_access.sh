#!/bin/bash

# Set up error handling
set -e  # Exit on any error
set -u  # Error on undefined variables

# Define paths
CONFIG_FILE="config/sources.json"
RAW_DIR="data/raw"

# Ensure raw directory exists
mkdir -p "$RAW_DIR"

# Function to download a file with some basic error handling
download_file() {
    local url="$1"
    local output_dir="$2"
    local source_name="$3"
    
    echo "Downloading from $url..."
    
    # Create source-specific directory
    mkdir -p "$output_dir/$source_name"
    
    # Get filename from URL or use default
    filename=$(basename "$url")
    
    # Download with curl, showing progress bar
    if curl -L --fail \
            --retry 3 \
            --retry-delay 5 \
            --connect-timeout 30 \
            --progress-bar \
            "$url" \
            -o "$output_dir/$source_name/$filename"; then
        echo "Successfully downloaded $filename"
    else
        echo "Failed to download $url" >&2
        return 1
    fi
}

# Read and process each source from config
echo "Reading configuration from $CONFIG_FILE..."
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found!" >&2
    exit 1
fi

# Process each source using jq
jq -c '.sources[]' "$CONFIG_FILE" | while read -r source; do
    name=$(echo "$source" | jq -r '.name')
    url=$(echo "$source" | jq -r '.url')
    type=$(echo "$source" | jq -r '.type')
    
    echo "Processing source: $name"
    
    # Only process Access databases
    if [ "$type" = "access" ]; then
        if download_file "$url" "$RAW_DIR" "$name"; then
            echo "Successfully processed $name"
        else
            echo "Failed to process $name" >&2
            # Continue with other sources even if one fails
            continue
        fi
    else
        echo "Skipping non-Access source: $name"
    fi
done

echo "Download process completed"
