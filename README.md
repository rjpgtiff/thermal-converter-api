# DJI Thermal Image Converter

A simple tool for converting DJI thermal images to radiometric TIFF format while preserving RGB images and folder structure through the rjpg2tiff API service.

## How to Use

1. Drop your thermal images AND RGB images into the `input` folder
2. Run the converter:
   - **macOS**: Double-click `run.command`
   - **Windows**: Double-click `convert.bat`
   - **Linux**: Make executable with `chmod +x convert.sh` then run `./convert.sh`
3. Find your converted `.tiff` files and copied RGB images in the `output` folder

## Supported DJI Products

This tool supports R-JPEG thermal images from the following DJI products (based on DJI Thermal SDK v1.7):

- **Zenmuse H20T**
- **Zenmuse H20N**
- **Zenmuse XT S**
- **Mavic 2 Enterprise Advanced (M2EA)**
- **M30T**

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
```# Test line
