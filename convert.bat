@echo off
title DJI Thermal Converter
cls
echo DJI Thermal Image Converter
echo ==============================
echo.
echo Converting thermal images...
echo.
cd /d "%~dp0"
bash "convert.sh"
echo.
echo Press any key to exit...
pause >nul