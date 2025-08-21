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

REM Find thermal images
echo Searching for thermal images...
set "THERMAL_COUNT=0"
set "RGB_COUNT=0"

REM Count thermal images
for /r "%INPUT_DIR%" %%f in (*_t.jpg *_t.jpeg *_r.jpg *_r.jpeg *_ir.jpg *_ir.jpeg *_thermal.jpg *_thermal.jpeg *_xt1.jpg *_xt1.jpeg *_xt2.jpg *_xt2.jpeg *_h20t.jpg *_h20t.jpeg *_h20n.jpg *_h20n.jpeg *_h30t.jpg *_h30t.jpeg *_m2ea.jpg *_m2ea.jpeg *_m30t.jpg *_m30t.jpeg) do (
    set /a THERMAL_COUNT+=1
)

REM Count RGB images (JPG/JPEG that are not thermal)
for /r "%INPUT_DIR%" %%f in (*.jpg *.jpeg) do (
    set "filename=%%~nf"
    set "ext=%%~xf"
    echo !filename! | findstr /i /c:"_t" /c:"_r" /c:"_ir" /c:"_thermal" /c:"_xt1" /c:"_xt2" /c:"_h20t" /c:"_h20n" /c:"_h30t" /c:"_m2ea" /c:"_m30t" >nul
    if !errorlevel! neq 0 (
        set /a RGB_COUNT+=1
    )
)

echo Found %THERMAL_COUNT% thermal images and %RGB_COUNT% RGB images
echo.

if %THERMAL_COUNT% equ 0 if %RGB_COUNT% equ 0 (
    echo ! No images found!
    echo ! Please drop thermal or RGB images into the 'input' folder.
    pause
    exit /b 1
)

REM Process thermal images
if %THERMAL_COUNT% gtr 0 (
    echo Sending %THERMAL_COUNT% files to %API_URL%/api/convert-batch
    echo.
    echo Converting thermal images in batch...
    
    REM Create output directory
    if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
    
    REM Use PowerShell for more advanced functionality
    powershell -Command "& {
        $inputDir = '%INPUT_DIR%'
        $outputDir = '%OUTPUT_DIR%'
        $apiUrl = '%API_URL%'
        
        # Find thermal images
        $thermalImages = Get-ChildItem -Path $inputDir -Recurse -Include '*_t.jpg','*_t.jpeg','*_r.jpg','*_r.jpeg','*_ir.jpg','*_ir.jpeg','*_thermal.jpg','*_thermal.jpeg','*_xt1.jpg','*_xt1.jpeg','*_xt2.jpg','*_xt2.jpeg','*_h20t.jpg','*_h20t.jpeg','*_h20n.jpg','*_h20n.jpeg','*_h30t.jpg','*_h30t.jpeg','*_m2ea.jpg','*_m2ea.jpeg','*_m30t.jpg','*_m30t.jpeg'
        
        if ($thermalImages.Count -eq 0) {
            Write-Host 'No thermal images found!'
            return
        }
        
        # Prepare form data
        $form = @{}
        for ($i = 0; $i -lt $thermalImages.Count; $i++) {
            $form['file' + $i] = $thermalImages[$i].FullName
            $relativePath = $thermalImages[$i].FullName.Substring($inputDir.Length + 1)
            $form['relativePath' + $i] = $relativePath
        }
        
        # Convert using Invoke-RestMethod
        try {
            Write-Host 'Processing thermal data...'
            $response = Invoke-RestMethod -Uri '$apiUrl/api/convert-batch' -Method Post -Form $form -OutFile '$outputDir\batch_output.zip'
            
            if (Test-Path '$outputDir\batch_output.zip') {
                # Extract zip file
                Expand-Archive -Path '$outputDir\batch_output.zip' -DestinationPath $outputDir -Force
                Remove-Item '$outputDir\batch_output.zip'
                Write-Host '✅ Batch conversion completed successfully!'
            }
        }
        catch {
            Write-Host '❌ Batch conversion failed: ' + $_.Exception.Message
        }
    }"
)

REM Process RGB images (copy them)
if %RGB_COUNT% gtr 0 (
    echo.
    echo Copying RGB images...
    
    REM Use PowerShell for copying with folder structure preservation
    powershell -Command "& {
        $inputDir = '%INPUT_DIR%'
        $outputDir = '%OUTPUT_DIR%'
        
        # Find RGB images
        $rgbImages = Get-ChildItem -Path $inputDir -Recurse -Include '*.jpg','*.jpeg' | Where-Object {
            $name = $_.Name.ToLower()
            $name -notmatch '_t\.|_r\.|_ir\.|_thermal\.|_xt1\.|_xt2\.|_h20t\.|_h20n\.|_h30t\.|_m2ea\.|_m30t\.'
        }
        
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
    }"
)

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