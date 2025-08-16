<<<<<<< HEAD
# DJI Thermal Image Converter

A simple offline tool for converting DJI thermal images to radiometric TIFF format while preserving RGB images and folder structure.

## How to Use

1. Drop your thermal images AND RGB images into the `input` folder
2. Run the converter:
   - **macOS**: Double-click `run.command`
   - **Windows**: Double-click `convert.bat`
   - **Linux**: Make executable with `chmod +x convert.sh` then run `./convert.sh`
3. Find your converted `.tiff` files and copied RGB images in the `output` folder

## Supported Formats

- **Thermal images**: Files ending with `_T.JPG`, `_R.JPG`, `_IR.JPG`, `_THERMAL.JPG`, etc.
- **RGB images**: All other `.JPG`/`.JPEG` files
- **DJI camera specific**: `_H20T.JPG`, `_M30T.JPG`, etc.

## Requirements

- **macOS**: Built-in (no installation needed)
- **Windows**: Install Git Bash from https://git-scm.com/
- **Linux**: Built-in bash shell (no installation needed)

## Quick Start

### macOS
1. Extract this folder anywhere
2. Drop thermal AND RGB images into `input` folder
3. Double-click `run.command`

### Windows
1. Install Git Bash from https://git-scm.com/
2. Extract this folder anywhere
3. Drop thermal AND RGB images into `input` folder
4. Double-click `convert.bat`

### Linux
1. Extract this folder anywhere
2. Drop thermal AND RGB images into `input` folder
3. Make the script executable: `chmod +x convert.sh`
4. Run the converter: `./convert.sh`

## Features

- Automatically converts thermal images to `.tiff` format
- Automatically copies RGB images to maintain folder structure
- Preserves original folder structure in output
- No additional software installation required
- Works on Windows, macOS, and Linux
- Automatically opens output folder when complete

## Troubleshooting

If double-click doesn't work, open terminal and run:
```bash
cd /path/to/thermal_converter
bash convert.sh
```
=======
# thermal-converter-api
DJI Thermal Image Converter - API for converting R-JPG      thermal images to radiometric TIFF format
>>>>>>> f5dd50d8c2df8fe350d0d9f44f6602ae6c07f1da
