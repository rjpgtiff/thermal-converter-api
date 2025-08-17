#!/bin/bash

# DJI Thermal Image Converter
# Double-click to convert all thermal images in the 'input' folder
# Also copies RGB images to maintain folder structure

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="$SCRIPT_DIR/input"
OUTPUT_DIR="$SCRIPT_DIR/output"
# Check if backend is running locally, otherwise use production
if curl -s -f "http://localhost:8000/health" > /dev/null 2>&1; then
    API_URL="http://localhost:8000"
    echo "Using local backend at $API_URL"
else
    API_URL="https://www.rjpg2tiff.xyz"
    echo "Using production backend at $API_URL"
fi

# Clear screen and show header with ASCII art
clear
echo "rjpg2tiff - DJI Thermal Image Converter"
echo "========================================"
echo "Input folder: $INPUT_DIR"
echo "Output folder: $OUTPUT_DIR"
echo "API endpoint: $API_URL"
echo ""

# Check if input folder has files
if [ -z "$(ls -A "$INPUT_DIR")" ]; then
    echo "! No files found in input folder!"
    echo "! Please drop thermal images or folders into the 'input' folder and run again."
    exit 1
fi

# Find thermal images using find command
echo "Searching for thermal images..."
THERMAL_IMAGES=()
while read -r file; do
    THERMAL_IMAGES+=("$file")
done < <(find "$INPUT_DIR" -type f \( \
    -iname "*_t.jpg" -o -iname "*_t.jpeg" -o \
    -iname "*_r.jpg" -o -iname "*_r.jpeg" -o \
    -iname "*_ir.jpg" -o -iname "*_ir.jpeg" -o \
    -iname "*_thermal.jpg" -o -iname "*_thermal.jpeg" -o \
    -iname "*_xt1.jpg" -o -iname "*_xt1.jpeg" -o \
    -iname "*_xt2.jpg" -o -iname "*_xt2.jpeg" -o \
    -iname "*_h20t.jpg" -o -iname "*_h20t.jpeg" -o \
    -iname "*_h20n.jpg" -o -iname "*_h20n.jpeg" -o \
    -iname "*_h30t.jpg" -o -iname "*_h30t.jpeg" -o \
    -iname "*_m2ea.jpg" -o -iname "*_m2ea.jpeg" -o \
    -iname "*_m30t.jpg" -o -iname "*_m30t.jpeg" \
\) 2>/dev/null)

# Find RGB images (JPG/JPEG that are not thermal)
echo "Searching for RGB images..."
RGB_IMAGES=()
while read -r file; do
    RGB_IMAGES+=("$file")
done < <(find "$INPUT_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) \
    ! -iname "*_t.jpg" ! -iname "*_t.jpeg" \
    ! -iname "*_r.jpg" ! -iname "*_r.jpeg" \
    ! -iname "*_ir.jpg" ! -iname "*_ir.jpeg" \
    ! -iname "*_thermal.jpg" ! -iname "*_thermal.jpeg" \
    ! -iname "*_xt1.jpg" ! -iname "*_xt1.jpeg" \
    ! -iname "*_xt2.jpg" ! -iname "*_xt2.jpeg" \
    ! -iname "*_h20t.jpg" ! -iname "*_h20t.jpeg" \
    ! -iname "*_h20n.jpg" ! -iname "*_h20n.jpeg" \
    ! -iname "*_h30t.jpg" ! -iname "*_h30t.jpeg" \
    ! -iname "*_m2ea.jpg" ! -iname "*_m2ea.jpeg" \
    ! -iname "*_m30t.jpg" ! -iname "*_m30t.jpeg" \
    2>/dev/null)

echo "Found ${#THERMAL_IMAGES[@]} thermal images and ${#RGB_IMAGES[@]} RGB images"
echo ""

if [ ${#THERMAL_IMAGES[@]} -eq 0 ] && [ ${#RGB_IMAGES[@]} -eq 0 ]; then
    echo "! No images found!"
    echo "! Please drop thermal or RGB images into the 'input' folder."
    exit 1
fi

# Process all images
echo "Processing all images..."
SUCCESSFUL=0
FAILED=0
COPIED_RGB=0
FAILED_RGB=0
TOTAL_IMAGES=$((${#THERMAL_IMAGES[@]} + ${#RGB_IMAGES[@]}))

# Process thermal images in batch
if [ ${#THERMAL_IMAGES[@]} -gt 0 ]; then
    echo "Sending ${#THERMAL_IMAGES[@]} files to $API_URL/api/convert-batch"
    
    # Prepare form data for curl - using indexed field names and relative paths
    CURL_FORM_DATA=()
    for i in "${!THERMAL_IMAGES[@]}"; do
        IMAGE_PATH="${THERMAL_IMAGES[$i]}"
        # Calculate relative path to preserve folder structure
        RELATIVE_PATH="${IMAGE_PATH#$INPUT_DIR/}"
        
        # Use indexed field names and send relative path for each file
        CURL_FORM_DATA+=(--form "file${i}=@$IMAGE_PATH")
        CURL_FORM_DATA+=(--form "relativePath${i}=$RELATIVE_PATH")
    done
    
    # Create a temporary directory for batch processing
    TEMP_DIR=$(mktemp -d)
    BATCH_OUTPUT="$TEMP_DIR/batch_output.zip"
    
    # Convert using curl batch endpoint with timeout to prevent hanging
    echo "Converting thermal images in batch..."
    
    # Start timer
    START_TIME=$(date +%s)
    
    # Save curl output for debugging
    CURL_OUTPUT=$(mktemp)
    
    # Run curl in background and show progress messages
    curl -s -S --fail --max-time 300 \
        "${CURL_FORM_DATA[@]}" \
        -o "$BATCH_OUTPUT" \
        "$API_URL/api/convert-batch" 2>"$CURL_OUTPUT" &
    
    CURL_PID=$!
    
    # Show progress messages while waiting
    MESSAGES=("Our servers are working hard..." "Processing thermal data..." "Almost there..." "Just a bit more...")
    MSG_INDEX=0
    
    while kill -0 $CURL_PID 2>/dev/null; do
        echo "${MESSAGES[$MSG_INDEX]}"
        MSG_INDEX=$(( (MSG_INDEX + 1) % ${#MESSAGES[@]} ))
        sleep 5
    done
    
    # Wait for curl to complete
    wait $CURL_PID
    CURL_EXIT_CODE=$?
    
    # Calculate elapsed time
    END_TIME=$(date +%s)
    ELAPSED_TIME=$((END_TIME - START_TIME))
    
    # Check if curl succeeded
    if [ $CURL_EXIT_CODE -eq 0 ] && [ -f "$BATCH_OUTPUT" ] && [ -s "$BATCH_OUTPUT" ]; then
        # Extract the zip file to output directory
        mkdir -p "$OUTPUT_DIR"
        unzip -q "$BATCH_OUTPUT" -d "$OUTPUT_DIR" 2>/dev/null
        SUCCESSFUL=${#THERMAL_IMAGES[@]}
        echo "✅ Batch conversion completed in $(($ELAPSED_TIME / 60))m $(($ELAPSED_TIME % 60))s"
    else
        FAILED=${#THERMAL_IMAGES[@]}
        echo "❌ Batch conversion failed after $(($ELAPSED_TIME / 60))m $(($ELAPSED_TIME % 60))s"
        echo "Curl error: $(cat "$CURL_OUTPUT")"
    fi
    
    # Clean up temp file
    rm -f "$CURL_OUTPUT"
    
    # Clean up temporary files
    rm -f "$BATCH_OUTPUT" 2>/dev/null
    rmdir "$TEMP_DIR" 2>/dev/null
fi

# Process RGB images (copy them individually)
if [ ${#RGB_IMAGES[@]} -gt 0 ]; then
    echo "Copying RGB images..."
    for i in "${!RGB_IMAGES[@]}"; do
        IMAGE_PATH="${RGB_IMAGES[$i]}"
        
        # Calculate relative path to preserve folder structure
        RELATIVE_PATH="${IMAGE_PATH#$INPUT_DIR/}"
        OUTPUT_PATH="$OUTPUT_DIR/$RELATIVE_PATH"
        OUTPUT_DIR_FOR_FILE=$(dirname "$OUTPUT_PATH")
        
        # Create output directory
        mkdir -p "$OUTPUT_DIR_FOR_FILE" 2>/dev/null
        
        # Copy the file (completely silent)
        if cp "$IMAGE_PATH" "$OUTPUT_PATH" 2>/dev/null; then
            ((COPIED_RGB++))
        else
            ((FAILED_RGB++))
        fi
    done
fi

# Show results
echo ""
echo "=============================="
echo "✅ Processing complete!"
echo "Thermal images converted: $SUCCESSFUL successful, $FAILED failed"
echo "RGB images copied: $COPIED_RGB successful, $FAILED_RGB failed"
echo "Output files are in: $OUTPUT_DIR"
echo ""
echo "=============================="
echo "☕️ Like this tool? Support the project!"
echo "   Scan bmc_qr.png or visit: https://www.buymeacoffee.com/rjpgtiff"
echo ""