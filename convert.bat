@echo off
title DJI Thermal Converter
cls
echo rjpg2tiff - DJI Thermal Image Converter
echo ========================================
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "INPUT_DIR=%SCRIPT_DIR%input"
set "OUTPUT_DIR=%SCRIPT_DIR%output"

REM Check if backend is running locally, otherwise use production
curl -s -f "http://localhost:8000/health" >nul 2>&1
if %errorlevel% equ 0 (
    set "API_URL=http://localhost:8000"
    echo Using local backend at %API_URL%
) else (
    set "API_URL=https://www.rjpg2tiff.xyz"
    echo Using production backend at %API_URL%
)

echo Input folder: %INPUT_DIR%
echo Output folder: %OUTPUT_DIR%
echo API endpoint: %API_URL%
echo.

REM Check if input folder has files
dir /b "%INPUT_DIR%\*" >nul 2>&1
if %errorlevel% neq 0 (
    echo ! No files found in input folder!
    echo ! Please drop thermal images or folders into the 'input' folder and run again.
    pause
    exit /b 1
)

echo Searching for thermal images...
echo.

REM Create output directory
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Use PowerShell for all the heavy lifting - much more reliable
powershell -Command "& {
    $inputDir = '%INPUT_DIR%'
    $outputDir = '%OUTPUT_DIR%'
    $apiUrl = '%API_URL%'
    
    Write-Host 'Scanning for thermal images...'
    
    # Find thermal images
    $thermalImages = Get-ChildItem -Path $inputDir -Recurse -Include '*_t.jpg','*_t.jpeg','*_r.jpg','*_r.jpeg','*_ir.jpg','*_ir.jpeg','*_thermal.jpg','*_thermal.jpeg','*_xt1.jpg','*_xt1.jpeg','*_xt2.jpg','*_xt2.jpeg','*_h20t.jpg','*_h20t.jpeg','*_h20n.jpg','*_h20n.jpeg','*_h30t.jpg','*_h30t.jpeg','*_m2ea.jpg','*_m2ea.jpeg','*_m30t.jpg','*_m30t.jpeg'
    
    # Find RGB images (JPG/JPEG that are not thermal)
    $rgbImages = Get-ChildItem -Path $inputDir -Recurse -Include '*.jpg','*.jpeg' | Where-Object {
        $name = $_.Name.ToLower()
        $name -notmatch '_t\.|_r\.|_ir\.|_thermal\.|_xt1\.|_xt2\.|_h20t\.|_h20n\.|_h30t\.|_m2ea\.|_m30t\.'
    }
    
    Write-Host 'Found ' $thermalImages.Count ' thermal images and ' $rgbImages.Count ' RGB images'
    Write-Host ''
    
    if ($thermalImages.Count -eq 0 -and $rgbImages.Count -eq 0) {
        Write-Host '! No images found!'
        Write-Host '! Please drop thermal or RGB images into the input folder.'
        return
    }
    
    # Process thermal images
    if ($thermalImages.Count -gt 0) {
        Write-Host 'Sending ' $thermalImages.Count ' files to ' $apiUrl '/api/convert-batch'
        Write-Host ''
        Write-Host 'Converting thermal images in batch...'
        
        try {
            # Prepare form data
            $form = @{}
            for ($i = 0; $i -lt $thermalImages.Count; $i++) {
                $form['file' + $i] = $thermalImages[$i].FullName
                $relativePath = $thermalImages[$i].FullName.Substring($inputDir.Length + 1)
                $form['relativePath' + $i] = $relativePath
            }
            
            Write-Host 'Processing thermal data...'
            $response = Invoke-RestMethod -Uri ($apiUrl + '/api/convert-batch') -Method Post -Form $form -OutFile ($outputDir + '\batch_output.zip')
            
            if (Test-Path ($outputDir + '\batch_output.zip')) {
                # Extract zip file
                Expand-Archive -Path ($outputDir + '\batch_output.zip') -DestinationPath $outputDir -Force
                Remove-Item ($outputDir + '\batch_output.zip')
                Write-Host '✅ Batch conversion completed successfully!'
            }
        }
        catch {
            Write-Host '❌ Batch conversion failed: ' + $_.Exception.Message
        }
    }
    
    # Process RGB images (copy them)
    if ($rgbImages.Count -gt 0) {
        Write-Host ''
        Write-Host 'Copying RGB images...'
        
        foreach ($image in $rgbImages) {
            $relativePath = $image.FullName.Substring($inputDir.Length + 1)
            $outputPath = Join-Path $outputDir $relativePath
            $outputDirForFile = Split-Path $outputPath -Parent
            
            if (!(Test-Path $outputDirForFile)) {
                New-Item -ItemType Directory -Path $outputDirForFile -Force | Out-Null
            }
            
            Copy-Item $image.FullName $outputPath -Force
        }
        
        Write-Host 'RGB images copied successfully!'
    }
    
    Write-Host ''
    Write-Host '=============================='
    Write-Host '✅ Processing complete!'
    Write-Host 'Output files are in: ' $outputDir
    Write-Host ''
    Write-Host '=============================='
    Write-Host '☕️ Like this tool? Support the project!'
    Write-Host '   Scan bmc_qr.png or visit: https://www.buymeacoffee.com/rjpgtiff'
    Write-Host ''
}"

echo.
echo ==============================
echo ✅ Processing complete!
echo Output files are in: %OUTPUT_DIR%
echo.
echo ==============================
echo ☕️ Like this tool? Support the project!
echo    Scan bmc_qr.png or visit: https://www.buymeacoffee.com/rjpgtiff
echo.

pause