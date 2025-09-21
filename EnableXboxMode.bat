@echo off
setlocal EnableExtensions EnableDelayedExpansion

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

echo ==== [%DATE% %TIME%] Script start ====>>"%LOG%"

:: -- Elevation check (launch admin window that stays open so errors are visible) --
openfiles >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','\"\"\"%~f0\"\"\"' -Verb RunAs"
  exit /b
)

if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%" || call :fail 100 "Could not create %DOWNLOAD_DIR%"
if exist "%EXTRACT_DIR%" rd /s /q "%EXTRACT_DIR%"
mkdir "%EXTRACT_DIR%" || call :fail 101 "Could not create %EXTRACT_DIR%"

echo Downloading zip...
powershell -NoProfile -Command "try{ Invoke-RestMethod -Uri '%URL%' -OutFile '%ZIP_PATH%' -UseBasicParsing; exit 0 } catch { Write-Error $_; exit 1 }"
if errorlevel 1 call :fail 1 "Download failed."

echo Extracting archive...
powershell -NoProfile -Command "try{ Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%EXTRACT_DIR%' -Force; exit 0 } catch { Write-Error $_; exit 2 }"
if errorlevel 1 call :fail 2 "Extraction failed."

:: remove the zip after successful extraction
if exist "%ZIP_PATH%" del /f /q "%ZIP_PATH%" 2>nul

:: -------- FIXED: find ViVeTool.exe without GOTO out of the FOR block --------
set "VIVEEXE="
for /r "%EXTRACT_DIR%" %%G in (ViVeTool.exe) do if not defined VIVEEXE set "VIVEEXE=%%~fG"
if not defined VIVEEXE call :fail 3 "ViVeTool.exe not found in extracted files."
echo Found ViVeTool: "%VIVEEXE%"

:: run first enable
call :run_and_check "%VIVEEXE%" "/enable /id:52580392" || call :fail 4 "First enable failed or missing success message."

:: run second enable
call :run_and_check "%VIVEEXE%" "/enable /id:50902630" || call :fail 5 "Second enable failed or missing success message."

echo Both ViVeTool commands succeeded.

:: -- Registry check/set (decimal 46)
echo Checking registry value %REG_KEY%\%REG_VAL% ...
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "try{ (Get-ItemProperty -Path 'Registry::%REG_KEY%' -Name '%REG_VAL%' -ErrorAction Stop).%REG_VAL% } catch { Write-Output '' }"`) do set "CURRENT_DEC=%%V"

if "%CURRENT_DEC%"=="" (
  reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %REG_DECIMAL% /f >nul 2>&1 || call :fail 6 "Failed to create registry value."
  echo Registry value created and set to %REG_DECIMAL%.
) else (
  set /a _cur=%CURRENT_DEC% 2>nul
  if not "%_cur%"=="%REG_DECIMAL%" (
    reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %REG_DECIMAL% /f >nul 2>&1 || call :fail 7 "Failed to update registry value."
    echo Registry updated to %REG_DECIMAL%.
  ) else (
    echo Registry already set to %REG_DECIMAL% (0x2e).
  )
)

:: delete extracted folder now that we’re done with it
echo Removing extracted folder "%EXTRACT_DIR%" ...
rd /s /q "%EXTRACT_DIR%" 2>nul || echo Warning: could not delete extracted folder (in use).

echo All steps completed successfully.>>"%LOG%"
echo All steps completed successfully.

:: -- Countdown with cancel (PowerShell)
echo Starting %COUNTDOWN_SECONDS%-second countdown. Press any key to cancel.
powershell -NoProfile -Command ^
  "$c=%COUNTDOWN_SECONDS%; Write-Host 'Restart will begin in ' $c ' seconds. Press any key to cancel.'; while($c -gt 0){ if([console]::KeyAvailable){ Write-Host 'Cancelled by keypress.'; exit 2 }; Write-Host $c; Start-Sleep -Seconds 1; $c-- }; exit 0"

if %errorlevel%==2 (
  echo Countdown cancelled. No restart.
) else if %errorlevel%==0 (
  echo Restarting now...
  shutdown /r /t 0
)

goto :eof

:: -------------------------
:: Subroutines
:: -------------------------
:run_and_check
:: %1 = exe path, %2 = full arg string (keep quoted)
set "EXE=%~1"
set "ARGS=%~2"
if not exist "%EXE%" (
  echo ERROR: %EXE% not found.>>"%LOG%"
  exit /b 1
)
echo Running: "%EXE%" %ARGS%
echo Running: "%EXE%" %ARGS%>>"%LOG%"
"%EXE%" %ARGS% > "%TEMP_OUT%" 2>&1
type "%TEMP_OUT%" >>"%LOG%"
:: SUCCESS_MSG has parentheses; /C makes findstr treat it literally.
findstr /c:"%SUCCESS_MSG%" "%TEMP_OUT%" >nul 2>&1 || (
  echo ---- command output ----
  type "%TEMP_OUT%"
  del /f /q "%TEMP_OUT%" >nul 2>&1
  exit /b 1
)
del /f /q "%TEMP_OUT%" >nul 2>&1
echo Command succeeded.
exit /b 0

:fail
set "CODE=%~1"
shift
echo ERROR(%CODE%): %*
echo ERROR(%CODE%): %* >>"%LOG%"
echo.
echo Last 50 log lines:
powershell -NoProfile -Command "if(Test-Path '%LOG%'){ Get-Content -Path '%LOG%' -Tail 50 }"
echo.
pause
exit /b %CODE%
