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

:: Elevation check (open admin cmd that stays open)
openfiles >nul 2>&1 || (
  powershell -NoProfile -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','\"\"\"%~f0\"\"\"' -Verb RunAs"
  exit /b
)

if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%" || goto :fail
if exist "%EXTRACT_DIR%" rd /s /q "%EXTRACT_DIR%"
mkdir "%EXTRACT_DIR%" || goto :fail

echo Downloading zip...
powershell -NoProfile -Command "try{ Invoke-RestMethod -Uri '%URL%' -OutFile '%ZIP_PATH%' -UseBasicParsing; exit 0 } catch { exit 1 }" || goto :fail

echo Extracting archive...
powershell -NoProfile -Command "try{ Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%EXTRACT_DIR%' -Force; exit 0 } catch { exit 1 }" || goto :fail

:: Clean up zip
if exist "%ZIP_PATH%" del /f /q "%ZIP_PATH%" >nul 2>&1

:: Find ViVeTool.exe (no GOTO out of FOR)
set "VIVEEXE="
for /r "%EXTRACT_DIR%" %%G in (ViVeTool.exe) do if not defined VIVEEXE set "VIVEEXE=%%~fG"
if not defined VIVEEXE (
  echo ERROR: ViVeTool.exe not found.
  goto :fail
)
echo Found ViVeTool: "%VIVEEXE%"

:: Run ViVeTool commands and check output
call :run_and_check "%VIVEEXE%" "/enable /id:52580392" || goto :fail
call :run_and_check "%VIVEEXE%" "/enable /id:50902630" || goto :fail
echo Both ViVeTool commands succeeded.

:: ============================
:: REGISTRY SECTION (FIXED)
:: ============================
echo Checking registry value %REG_KEY%\%REG_VAL% ...
reg query "%REG_KEY%" /v %REG_VAL% >nul 2>&1
if errorlevel 1 (
  echo Value not found. Creating as REG_DWORD %REG_DECIMAL% ...
  reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %REG_DECIMAL% /f >nul 2>&1 || goto :fail
  echo Registry value created.
) else (
  :: Parse the existing DWORD (comes back as hex like 0x0000002e)
  for /f "tokens=3" %%A in ('reg query "%REG_KEY%" /v %REG_VAL% ^| findstr /i "%REG_VAL%"') do set "CURRENT_HEX=%%A"
  set "CURRENT_HEX=%CURRENT_HEX%"
  :: Convert to decimal for comparison (set /a understands 0x... hex)
  set /a CURRENT_DEC=%CURRENT_HEX% 2>nul
  if not "%CURRENT_DEC%"=="%REG_DECIMAL%" (
    echo Current is %CURRENT_DEC% (hex %CURRENT_HEX%). Updating to %REG_DECIMAL% ...
    reg add "%REG_KEY%" /v %REG_VAL% /t REG_DWORD /d %REG_DECIMAL% /f >nul 2>&1 || goto :fail
    echo Registry updated.
  ) else (
    echo Registry already set to %REG_DECIMAL% (0x2e).
  )
)

:: Remove extracted folder
echo Removing extracted folder "%EXTRACT_DIR%" ...
rd /s /q "%EXTRACT_DIR%" 2>nul || echo Warning: could not delete extracted folder.

echo All steps completed successfully.

:: Countdown with cancel
echo Starting %COUNTDOWN_SECONDS%-second countdown. Press any key to cancel.
powershell -NoProfile -Command ^
  "$c=%COUNTDOWN_SECONDS%; while($c -gt 0){ if([console]::KeyAvailable){ exit 2 }; Write-Host $c; Start-Sleep 1; $c-- }"

if %errorlevel%==2 (
  echo Cancelled. No restart.
) else (
  echo Restarting now...
  shutdown /r /t 0
)
goto :eof

:: -------------------------
:: Helpers
:: -------------------------
:run_and_check
set "EXE=%~1"
set "ARGS=%~2"
"%EXE%" %ARGS% > "%TEMP_OUT%" 2>&1
findstr /c:"%SUCCESS_MSG%" "%TEMP_OUT%" >nul 2>&1 || (
  type "%TEMP_OUT%"
  del /f /q "%TEMP_OUT%" >nul 2>&1
  exit /b 1
)
del /f /q "%TEMP_OUT%" >nul 2>&1
exit /b 0

:fail
echo ERROR: A step failed. Review the messages above.
pause
exit /b 1
