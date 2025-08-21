# DJI Thermal Image Converter for Windows
# Double-click to convert all thermal images in the 'input' folder
# Also copies RGB images to maintain folder structure

# Get script directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$INPUT_DIR = Join-Path $SCRIPT_DIR "input"
$OUTPUT_DIR = Join-Path $SCRIPT_DIR "output"

# Check if backend is running locally, otherwise use production
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5 -ErrorAction Stop
    $API_URL = "http://localhost:8000"
    Write-Host "Using local backend at $API_URL" -ForegroundColor Green
} catch {
    $API_URL = "https://www.rjpg2tiff.xyz"
    Write-Host "Using production backend at $API_URL" -ForegroundColor Yellow
}

# Clear screen and show header
Clear-Host
Write-Host "rjpg2tiff - DJI Thermal Image Converter" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Input folder: $INPUT_DIR" -ForegroundColor White
Write-Host "Output folder: $OUTPUT_DIR" -ForegroundColor White
Write-Host "API endpoint: $API_URL" -ForegroundColor White
Write-Host ""

# Check if input folder has files
if (-not (Test-Path $INPUT_DIR) -or -not (Get-ChildItem $INPUT_DIR -File | Select-Object -First 1)) {
    Write-Host "! No files found in input folder!" -ForegroundColor Red
    Write-Host "! Please drop thermal images or folders into the 'input' folder and run again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Find thermal images using Get-ChildItem
Write-Host "Searching for thermal images..." -ForegroundColor Yellow
$THERMAL_IMAGES = Get-ChildItem -Path $INPUT_DIR -Recurse -Include @(
    "*_t.jpg", "*_t.jpeg", "*_r.jpg", "*_r.jpeg", 
    "*_ir.jpg", "*_ir.jpeg", "*_thermal.jpg", "*_thermal.jpeg",
    "*_xt1.jpg", "*_xt1.jpeg", "*_xt2.jpg", "*_xt2.jpeg",
    "*_h20t.jpg", "*_h20t.jpeg", "*_h20n.jpg", "*_h20n.jpeg",
    "*_h30t.jpg", "*_h30t.jpeg", "*_m2ea.jpg", "*_m2ea.jpeg",
    "*_m30t.jpg", "*_m30t.jpeg"
) | Where-Object { $_.PSIsContainer -eq $false }

# Find RGB images (JPG/JPEG that are not thermal)
Write-Host "Searching for RGB images..." -ForegroundColor Yellow
$RGB_IMAGES = Get-ChildItem -Path $INPUT_DIR -Recurse -Include "*.jpg", "*.jpeg" | Where-Object {
    $_.PSIsContainer -eq $false -and 
    $_.Name -notmatch "_t\.|_r\.|_ir\.|_thermal\.|_xt1\.|_xt2\.|_h20t\.|_h20n\.|_h30t\.|_m2ea\.|_m30t\."
}

Write-Host "Found $($THERMAL_IMAGES.Count) thermal images and $($RGB_IMAGES.Count) RGB images" -ForegroundColor Green
Write-Host ""

if ($THERMAL_IMAGES.Count -eq 0 -and $RGB_IMAGES.Count -eq 0) {
    Write-Host "! No images found!" -ForegroundColor Red
    Write-Host "! Please drop thermal or RGB images into the 'input' folder." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Process all images
Write-Host "Processing all images..." -ForegroundColor Yellow
$SUCCESSFUL = 0
$FAILED = 0
$COPIED_RGB = 0
$FAILED_RGB = 0
$TOTAL_IMAGES = $THERMAL_IMAGES.Count + $RGB_IMAGES.Count

# Process thermal images in batch
if ($THERMAL_IMAGES.Count -gt 0) {
    Write-Host "Sending $($THERMAL_IMAGES.Count) files to $API_URL/api/convert-batch" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Converting thermal images in batch..." -ForegroundColor Yellow
    
    # Create output directory
    if (-not (Test-Path $OUTPUT_DIR)) {
        New-Item -ItemType Directory -Path $OUTPUT_DIR -Force | Out-Null
    }
    
    # Prepare form data for batch conversion
    $form = @{}
    for ($i = 0; $i -lt $THERMAL_IMAGES.Count; $i++) {
        $form["file$i"] = $THERMAL_IMAGES[$i].FullName
        $relativePath = $THERMAL_IMAGES[$i].FullName.Substring($INPUT_DIR.Length + 1)
        $form["relativePath$i"] = $relativePath
    }
    
    # Create a temporary directory for batch processing
    $TEMP_DIR = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
    $BATCH_OUTPUT = Join-Path $TEMP_DIR "batch_output.zip"
    
    # Convert using batch endpoint with timeout to prevent hanging
    Write-Host "Converting thermal images in batch..." -ForegroundColor Yellow
    
    # Start timer
    $START_TIME = Get-Date
    
    # Show progress messages while waiting
    $MESSAGES = @("Our servers are working hard...", "Processing thermal data...", "Almost there...", "Just a bit more...")
    $MSG_INDEX = 0
    
    try {
        # Convert using Invoke-RestMethod
        Write-Host "Processing thermal data..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri "$API_URL/api/convert-batch" -Method Post -Form $form -OutFile $BATCH_OUTPUT -TimeoutSec 300
        
        if (Test-Path $BATCH_OUTPUT -and (Get-Item $BATCH_OUTPUT).Length -gt 0) {
            # Extract the zip file to output directory
            Expand-Archive -Path $BATCH_OUTPUT -DestinationPath $OUTPUT_DIR -Force
            $SUCCESSFUL = $THERMAL_IMAGES.Count
            
            # Calculate elapsed time
            $END_TIME = Get-Date
            $ELAPSED_TIME = ($END_TIME - $START_TIME).TotalSeconds
            Write-Host "✅ Batch conversion completed in $([math]::Floor($ELAPSED_TIME / 60))m $([math]::Floor($ELAPSED_TIME % 60))s" -ForegroundColor Green
        } else {
            $FAILED = $THERMAL_IMAGES.Count
            Write-Host "❌ Batch conversion failed - no output file received" -ForegroundColor Red
        }
    } catch {
        $FAILED = $THERMAL_IMAGES.Count
        $END_TIME = Get-Date
        $ELAPSED_TIME = ($END_TIME - $START_TIME).TotalSeconds
        Write-Host "❌ Batch conversion failed after $([math]::Floor($ELAPSED_TIME / 60))m $([math]::Floor($ELAPSED_TIME % 60))s" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Clean up temporary files
    if (Test-Path $BATCH_OUTPUT) { Remove-Item $BATCH_OUTPUT -Force }
    if (Test-Path $TEMP_DIR) { Remove-Item $TEMP_DIR -Recurse -Force }
}

# Process RGB images (copy them individually)
if ($RGB_IMAGES.Count -gt 0) {
    Write-Host ""
    Write-Host "Copying RGB images..." -ForegroundColor Yellow
    foreach ($image in $RGB_IMAGES) {
        # Calculate relative path to preserve folder structure
        $relativePath = $image.FullName.Substring($INPUT_DIR.Length + 1)
        $outputPath = Join-Path $OUTPUT_DIR $relativePath
        $outputDirForFile = Split-Path $outputPath -Parent
        
        # Create output directory
        if (-not (Test-Path $outputDirForFile)) {
            New-Item -ItemType Directory -Path $outputDirForFile -Force | Out-Null
        }
        
        # Copy the file
        try {
            Copy-Item $image.FullName $outputPath -Force
            $COPIED_RGB++
        } catch {
            $FAILED_RGB++
        }
    }
}

# Show results
Write-Host ""
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "✅ Processing complete!" -ForegroundColor Green
Write-Host "Thermal images converted: $SUCCESSFUL successful, $FAILED failed" -ForegroundColor White
Write-Host "RGB images copied: $COPIED_RGB successful, $FAILED_RGB failed" -ForegroundColor White
Write-Host "Output files are in: $OUTPUT_DIR" -ForegroundColor White
Write-Host ""
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "☕️ Like this tool? Support the project!" -ForegroundColor Yellow
Write-Host "   Scan bmc_qr.png or visit: https://www.buymeacoffee.com/rjpgtiff" -ForegroundColor Yellow
Write-Host ""

Read-Host "Press Enter to exit"
