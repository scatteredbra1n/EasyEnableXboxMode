@echo off
setlocal

set "KEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\OEM"
set "VAL=DeviceForm"

:: Query the registry
for /f "tokens=3" %%A in ('reg query "%KEY%" /v %VAL% 2^>nul ^| findstr /i "%VAL%"') do (
    set "RESULT=%%A"
)

if defined RESULT (
    echo %KEY%\%VAL% = %RESULT%
) else (
    echo Value not found.
)

endlocal
pause
