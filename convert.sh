#!/bin/bash

# DJI Thermal Image Converter
# Double-click to convert all thermal images in the 'input' folder
# Also copies RGB images to maintain folder structure

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="$SCRIPT_DIR/input"
OUTPUT_DIR="$SCRIPT_DIR/output"
API_URL="https://rjpg2tiff.xyz"

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
    osascript -e 'display alert "DJI Thermal Converter" message "No files found in input folder! Please drop thermal images or folders into the \"input\" folder and run again."'
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
    osascript -e 'display alert "DJI Thermal Converter" message "No images found! Please drop thermal or RGB images into the \"input\" folder."'
    exit 1
fi

# Process all images with continuously updating counter
echo "Processing all images..."
SUCCESSFUL=0
FAILED=0
COPIED_RGB=0
FAILED_RGB=0
TOTAL_IMAGES=$((${#THERMAL_IMAGES[@]} + ${#RGB_IMAGES[@]}))
PROCESSED=0

# Show initial progress on same line
printf "%d/%d" 0 $TOTAL_IMAGES

# Process thermal images
for i in "${!THERMAL_IMAGES[@]}"; do
    IMAGE_PATH="${THERMAL_IMAGES[$i]}"
    
    # Calculate relative path to preserve folder structure
    RELATIVE_PATH="${IMAGE_PATH#$INPUT_DIR/}"
    OUTPUT_PATH="$OUTPUT_DIR/${RELATIVE_PATH%.*}.tiff"
    OUTPUT_DIR_FOR_FILE=$(dirname "$OUTPUT_PATH")
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR_FOR_FILE" 2>/dev/null
    
    # Convert using curl (completely silent)
    if curl -s -S --fail \
        --data-binary "@$IMAGE_PATH" \
        -H "Content-Type: image/jpeg" \
        -o "$OUTPUT_PATH" \
        "$API_URL/api/convert" 2>/dev/null; then
        
        if [ -f "$OUTPUT_PATH" ] && [ -s "$OUTPUT_PATH" ]; then
            ((SUCCESSFUL++))
        else
            rm -f "$OUTPUT_PATH" 2>/dev/null
            ((FAILED++))
        fi
    else
        rm -f "$OUTPUT_PATH" 2>/dev/null
        ((FAILED++))
    fi
    
    ((PROCESSED++))
    
    # Update progress display continuously on same line
    printf "\r%d/%d" $PROCESSED $TOTAL_IMAGES
    
    # Small delay to be nice to the API
    sleep 1
done

# Process RGB images
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
    
    ((PROCESSED++))
    
    # Update progress display continuously on same line
    printf "\r%d/%d" $PROCESSED $TOTAL_IMAGES
done

# Finish progress and show results
printf "\r%d/%d - Complete!              \n" $TOTAL_IMAGES $TOTAL_IMAGES
echo ""
echo "=============================="
echo "✅ Processing complete!"
echo "Thermal images converted: $SUCCESSFUL successful, $FAILED failed"
echo "RGB images copied: $COPIED_RGB successful, $FAILED_RGB failed"
echo "Output files are in: $OUTPUT_DIR"
echo ""
echo "=============================="

# Show completion dialog
osascript -e "display alert \"DJI Thermal Converter\" message \"Processing complete!\\n\\nThermal images converted: $SUCCESSFUL successful, $FAILED failed\\nRGB images copied: $COPIED_RGB successful, $FAILED_RGB failed\\n\\nOutput files are in the 'output' folder.\""

# Open output folder
open "$OUTPUT_DIR" 2>/dev/null