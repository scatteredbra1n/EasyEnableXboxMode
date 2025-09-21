@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Config
set "REG_KEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\OEM"
set "REG_VAL=DeviceForm"
set "TARGET_DEC=46"    :: 0x2e
set "TMP_OUT=%TEMP%\regq_%RANDOM%.tmp"

echo Checking %REG_KEY%\%REG_VAL% ...

:: --- Elevation check (create/delete a temp value). Relaunch with Admin /K if needed.
reg add "%REG_KEY%" /v __PermCheck /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (
  echo Needs Administrator rights. Relaunching elevated...
  powershell -NoProfile -Command "Start-Process 'cmd.exe' -ArgumentList '/k','\"\"\"%~f0\"\"\"' -Verb RunAs"
  goto :end
)
reg delete "%REG_KEY%" /v __PermCheck /f >nul 2>&1

:: --- Query the current value (write to a file; no pipes to avoid parser quirks)
reg query "%REG_KEY%" /v %REG_VAL% > "%TMP_OUT%" 2>&1
if errorlevel 1 (
  echo %REG_VAL% not found. Creating with %TARGET_DEC% ...
  reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %TARGET_DEC% /f >nul
  if errorlevel 1 (
    echo ERROR: Failed to create %REG_VAL%.
    goto :show
  )
  goto :show
)

:: --- Parse the line that contains "DeviceForm"
set "CURRENT_HEX="
for /f "usebackq tokens=1,2,3,*" %%A in ("%TMP_OUT%") do (
  if /i "%%A"=="%REG_VAL%" set "CURRENT_HEX=%%C"
)

if not defined CURRENT_HEX (
  echo Could not parse existing value. Forcing to %TARGET_DEC% ...
  reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %TARGET_DEC% /f >nul
  goto :show
)

:: --- Convert hex (e.g., 0x0000002e) to decimal and compare
set /a CURRENT_DEC=%CURRENT_HEX% 2>nul
if not "!CURRENT_DEC!"=="%TARGET_DEC%" (
  echo Current is !CURRENT_DEC! (hex %CURRENT_HEX%). Updating to %TARGET_DEC% ...
  reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %TARGET_DEC% /f >nul
  if errorlevel 1 (
    echo ERROR: Failed to update %REG_VAL%.
    goto :show
  )
) else (
  echo Value already correct.
)

:show
:: Re-query to display final hex value
reg query "%REG_KEY%" /v %REG_VAL% | findstr /i "%REG_VAL%"
goto :cleanup

:cleanup
if exist "%TMP_OUT%" del /f /q "%TMP_OUT%" >nul 2>&1

:end
echo.
pause
exit /b
