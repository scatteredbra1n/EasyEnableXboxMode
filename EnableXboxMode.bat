@echo off
setlocal enabledelayedexpansion

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
set "REG_DECIMAL=46"    :: 0x2e == decimal 46
set "COUNTDOWN_SECONDS=10"
set "TEMP_OUT=%DOWNLOAD_DIR%\vive_out.txt"
:: -------------------------

:: -- Elevation check --
openfiles >nul 2>&1
if %errorlevel% neq 0 (
  echo Requesting elevation...
  powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

:: Prepare dirs
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"
if exist "%EXTRACT_DIR%" rd /s /q "%EXTRACT_DIR%"
mkdir "%EXTRACT_DIR%"

echo Downloading zip...
powershell -NoProfile -Command "try{ Invoke-RestMethod -Uri '%URL%' -OutFile '%ZIP_PATH%' -UseBasicParsing; exit 0 } catch { Write-Error $_; exit 1 }"
if %errorlevel% neq 0 (
  echo ERROR: Download failed.
  exit /b 1
)

echo Extracting archive...
powershell -NoProfile -Command "try{ Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%EXTRACT_DIR%' -Force; exit 0 } catch { Write-Error $_; exit 2 }"
if %errorlevel% neq 0 (
  echo ERROR: Extraction failed.
  exit /b 2
)

:: remove the zip after successful extraction
if exist "%ZIP_PATH%" (
  del /f /q "%ZIP_PATH%" 2>nul
  if %errorlevel% equ 0 ( echo Deleted downloaded ZIP. ) else ( echo Warning: could not delete ZIP. )
)

:: find ViVeTool.exe
set "VIVEEXE="
for /r "%EXTRACT_DIR%" %%G in (ViVeTool.exe) do (
  set "VIVEEXE=%%~fG"
  goto :found_vive
)
:found_vive
if "%VIVEEXE%"=="" (
  echo ERROR: ViVeTool.exe not found in extracted files.
  exit /b 3
)
echo Found ViVeTool: "%VIVEEXE%"

:: helper: run and check for success string
:run_and_check
rem %1 = exe path, %2 = args
if not exist "%~1" (
  echo ERROR: "%~1" not found.
  exit /b 10
)
echo Running: "%~1" %~2
"%~1" %~2 > "%TEMP_OUT%" 2>&1
findstr /c:"%SUCCESS_MSG%" "%TEMP_OUT%" >nul 2>&1
if %errorlevel% neq 0 (
  echo ERROR: Command did not report expected success message.
  type "%TEMP_OUT%"
  del /f /q "%TEMP_OUT%" >nul 2>&1
  exit /b 11
)
del /f /q "%TEMP_OUT%" >nul 2>&1
echo Command succeeded.
exit /b 0

:: run first enable
call :run_and_check "%VIVEEXE%" "/enable /id:52580392"
if %errorlevel% neq 0 exit /b 4

:: run second enable
call :run_and_check "%VIVEEXE%" "/enable /id:50902630"
if %errorlevel% neq 0 exit /b 5

echo Both ViVeTool commands succeeded.

:: -- Registry check/set (use PowerShell to read decimal value)
echo Checking registry value %REG_KEY%\%REG_VAL% ...
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "try{ (Get-ItemProperty -Path 'Registry::%REG_KEY%' -Name '%REG_VAL%' -ErrorAction Stop).%REG_VAL% } catch { Write-Output '' }"`) do set "CURRENT_DEC=%%V"

if "%CURRENT_DEC%"=="" (
  echo Registry value not found. Creating and setting to %REG_DECIMAL% ...
  reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %REG_DECIMAL% /f >nul 2>&1
  if %errorlevel% neq 0 (
    echo ERROR: Failed to create registry value.
    exit /b 6
  )
  echo Registry value created and set to %REG_DECIMAL%.
) else (
  rem CURRENT_DEC should be decimal; compare numerically
  set /a _cur=%CURRENT_DEC% 2>nul
  if "%_cur%"=="%REG_DECIMAL%" (
    echo Registry already set to decimal %REG_DECIMAL% (0x2e).
  ) else (
    echo Registry value is %CURRENT_DEC% (decimal). Updating to %REG_DECIMAL% ...
    reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %REG_DECIMAL% /f >nul 2>&1
    if %errorlevel% neq 0 (
      echo ERROR: Failed to update registry value.
      exit /b 7
    )
    echo Registry updated to %REG_DECIMAL%.
  )
)

:: -- Delete extracted folder now that commands + registry are done
echo Attempting to remove extracted folder "%EXTRACT_DIR%" ...
rd /s /q "%EXTRACT_DIR%" 2>nul
if %errorlevel% equ 0 (
  echo Deleted extracted folder.
) else (
  echo Warning: could not delete "%EXTRACT_DIR%". It may be in use or permissions prevented deletion.
)

echo All steps completed successfully.

:: -- Countdown with cancel (PowerShell)
echo Starting %COUNTDOWN_SECONDS%-second countdown. Press any key to cancel.
powershell -NoProfile -Command ^
  "$c=%COUNTDOWN_SECONDS%; Write-Host 'Restart will begin in ' $c ' seconds. Press any key to cancel.'; while($c -gt 0){ if([console]::KeyAvailable){ Write-Host 'Cancelled by keypress.'; exit 2 }; Write-Host $c; Start-Sleep -Seconds 1; $c-- }; exit 0"

set "PS_EXIT=%ERRORLEVEL%"
if "%PS_EXIT%_
