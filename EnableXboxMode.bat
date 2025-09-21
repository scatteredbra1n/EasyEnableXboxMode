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
set "LOG=%DOWNLOAD_DIR%\vivetool_run.log"
:: -------------------------

:: --- Always log basic progress (append) ---
echo ==== [%DATE% %TIME%] Script start ====>>"%LOG%"

:: -- Elevation check --
openfiles >nul 2>&1
if %errorlevel% neq 0 (
  echo Requesting elevation...
  :: Relaunch in an ADMIN cmd window that stays open (/k) so errors are visible
  powershell -NoProfile -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','\"\"\"%~f0\"\"\"' -Verb RunAs"
  exit /b
)

:: Prepare dirs
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"
if errorlevel 1 call :fail 100 "Could not create %DOWNLOAD_DIR%"

if exist "%EXTRACT_DIR%" rd /s /q "%EXTRACT_DIR%"
mkdir "%EXTRACT_DIR%"
if errorlevel 1 call :fail 101 "Could not create %EXTRACT_DIR%"

echo Downloading zip...
powershell -NoProfile -Command "try{ Invoke-RestMethod -Uri '%URL%' -OutFile '%ZIP_PATH%' -UseBasicParsing; exit 0 } catch { Write-Error $_; exit 1 }"
if errorlevel 1 call :fail 1 "Download failed." 

echo Extracting archive...
powershell -NoProfile -Command "try{ Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%EXTRACT_DIR%' -Force; exit 0 } catch { Write-Error $_; exit 2 }"
if errorlevel 1 call :fail 2 "Extraction failed."

:: remove the zip after successful extraction
if exist "%ZIP_PATH%" (
  del /f /q "%ZIP_PATH%" 2>nul
  if errorlevel 1 echo Warning: could not delete downloaded ZIP.>>"%LOG%"
  echo Cleaned up downloaded ZIP.
)

:: find ViVeTool.exe
set "VIVEEXE="
for /r "%EXTRACT_DIR%" %%G in (ViVeTool.exe) do (
  set "VIVEEXE=%%~fG"
  goto :found_vive
)
:found_vive
if "%VIVEEXE%"=="" call :fail 3 "ViVeTool.exe not found in extracted files."
echo Found ViVeTool: "%VIVEEXE%"

:: run first enable
call :run_and_check "%VIVEEXE%" "/enable /id:52580392" || call :fail 4 "First enable failed or missing success message."

:: run second enable
call :run_and_check "%VIVEEXE%" "/enable /id:50902630" || call :fail 5 "Second enable failed or missing success message."

echo Both ViVeTool commands succeeded.

:: -- Registry check/set
echo Checking registry value %REG_KEY%\%REG_VAL% ...
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "try{ (Get-ItemProperty -Path 'Registry::%REG_KEY%' -Name '%REG_VAL%' -ErrorAction Stop).%REG_VAL% } catch { Write-Output '' }"`) do set "CURRENT_DEC=%%V"

if "%CURRENT_DEC%"=="" (
  echo Registry value not found. Creating and setting to %REG_DECIMAL% ...
  reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %REG_DECIMAL% /f >nul 2>&1
  if errorlevel 1 call :fail 6 "Failed to create registry value."
  echo Registry value created and set to %REG_DECIMAL%.
) else (
  set /a _cur=%CURRENT_DEC% 2>nul
  if "%_cur%"=="%REG_DECIMAL%" (
    echo Registry already set to %REG_DECIMAL% (0x2e).
  ) else (
    echo Registry value is %CURRENT_DEC% (decimal). Updating to %REG_DECIMAL% ...
    reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %REG_DECIMAL% /f >nul 2>&1
    if errorlevel 1 call :fail 7 "Failed to update registry value."
    echo Registry updated to %REG_DECIMAL%.
  )
)

:: -- Delete extracted folder now that commands + registry are done
echo Removing extracted folder "%EXTRACT_DIR%" ...
rd /s /q "%EXTRACT_DIR%" 2>nul
if errorlevel 1 (
  echo Warning: could not delete "%EXTRACT_DIR%".>>"%LOG%"
  echo Warning: could not delete extracted folder (in use or permissions).
) else (
  echo Deleted extracted folder.
)

echo All steps completed successfully.>>"%LOG%"
echo All steps completed successfully.

:: -- Countdown with cancel (PowerShell)
echo Starting %COUNTDOWN_SECONDS%-second countdown. Press any key to cancel.
powershell -NoProfile -Command ^
  "$c=%COUNTDOWN_SECONDS%; Write-Host 'Restart will begin in ' $c ' seconds. Press any key to cancel.'; while($c -gt 0){ if([console]::KeyAvailable){ Write-Host 'Cancelled by keypress.'; exit 2 }; Write-Host $c; Start-Sleep -Seconds 1; $c-- }; exit 0"

set "PS_EXIT=%ERRORLEVEL%"
if "%PS_EXIT%"=="2" (
  echo Countdown cancelled by keypress. No restart will occur.
  echo Cancelled by user during countdown.>>"%LOG%"
  goto :eof
) else if "%PS_EXIT%"=="0" (
  echo Countdown finished. Restarting now...
  echo Restarting after countdown.>>"%LOG%"
  shutdown /r /t 0
  goto :eof
) else (
  echo Unexpected result from countdown (exit code %PS_EXIT%). Not restarting.
  echo Unexpected PS exit %PS_EXIT% during countdown.>>"%LOG%"
  goto :eof
)

:: -------------------------
:: Subroutines
:: -------------------------
:run_and_check
:: %1 = path to exe, %2 = arguments string
set "EXE=%~1"
set "ARGS=%~2"
if not exist "%EXE%" (
  echo ERROR: %EXE% not found.
  echo ERROR: %EXE% not found.>>"%LOG%"
  exit /b 1
)
echo Running: "%EXE%" %ARGS%
echo Running: "%EXE%" %ARGS%>>"%LOG%"
"%EXE%" %ARGS% > "%TEMP_OUT%" 2>&1
type "%TEMP_OUT%" >>"%LOG%"
findstr /c:"%SUCCESS_MSG%" "%TEMP_OUT%" >nul 2>&1
if errorlevel 1 (
  echo ERROR: Expected success message not found.
  echo ---- Command output (for debugging) ----
  type "%TEMP_OUT%"
  del /f /q "%TEMP_OUT%" >nul 2>&1
  exit /b 1
)
del /f /q "%TEMP_OUT%" >nul 2>&1
echo Command succeeded.
exit /b 0

:fail
:: %1 = code, %2... = message
set "CODE=%~1"
shift
echo ERROR(%CODE%): %* 
echo ERROR(%CODE%): %* >>"%LOG%"
echo.
echo Last 50 log lines for context:
powershell -NoProfile -Command "if(Test-Path '%LOG%'){ Get-Content -Path '%LOG%' -Tail 50 }"
echo.
pause
exit /b %CODE%
