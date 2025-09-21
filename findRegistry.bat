@echo off
setlocal EnableExtensions

:: -------------------------
:: Config
:: -------------------------
set "URL=https://github.com/thebookisclosed/ViVe/releases/download/v0.3.4/ViVeTool-v0.3.4-IntelAmd.zip"
set "DOWNLOAD_DIR=C:\temp"
set "ZIP_PATH=%DOWNLOAD_DIR%\ViVeTool.zip"
set "EXTRACT_DIR=%DOWNLOAD_DIR%\ViVeToolExtract"
set "SUCCESS_MSG=Successfully set feature configuration(s)"
set "REG_KEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\OEM"
set "REG_VAL=DeviceForm"
set "REG_DECIMAL=46"    :: 0x2e
set "COUNTDOWN_SECONDS=10"
set "TEMP_OUT=%DOWNLOAD_DIR%\vive_out.txt"
set "LOG=%DOWNLOAD_DIR%\vivetool_run.log"
:: -------------------------

echo Checking registry: %REG_KEY%\%REG_VAL% ...

set "CURRENT_HEX="

:: Does the value exist?
reg query "%REG_KEY%" /v %REG_VAL% >nul 2>&1
if errorlevel 1 (
    echo Value not found. Creating with %REG_DECIMAL% ...
    reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %REG_DECIMAL% /f >nul
    if errorlevel 1 (
        echo ERROR: Failed to create value.
        exit /b 1
    )
    echo Created %REG_VAL% = %REG_DECIMAL% (0x2e).
    goto :done
)

:: Parse current value (reg query output has: Name  Type  Data)
for /f "tokens=3" %%A in ('reg query "%REG_KEY%" /v %REG_VAL% ^| findstr /i "%REG_VAL%"') do set "CURRENT_HEX=%%A"

if not defined CURRENT_HEX (
    echo Could not parse existing value. Forcing update to %REG_DECIMAL% ...
    reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %REG_DECIMAL% /f >nul
    goto :done
)

:: Convert hex to decimal
set /a CURRENT_DEC=%CURRENT_HEX% 2>nul

if "%CURRENT_DEC%"=="%REG_DECIMAL%" (
    echo Value already set to %REG_DECIMAL% (hex %CURRENT_HEX%).
) else (
    echo Current value is %CURRENT_DEC% (hex %CURRENT_HEX%). Updating...
    reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %REG_DECIMAL% /f >nul
    if errorlevel 1 (
        echo ERROR: Failed to update value.
        exit /b 1
    )
    echo Updated to %REG_DECIMAL% (0x2e).
)

:done
echo Done.
endlocal
pause
