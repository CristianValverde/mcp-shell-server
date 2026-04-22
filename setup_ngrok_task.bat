@echo off
setlocal

:: Auto-detects the project directory (where this script lives)
set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

echo =========================================
echo  ngrok MCP Tunnel -- Autostart Setup
echo =========================================
echo.
echo Project directory detected:
echo   %PROJECT_DIR%
echo.
echo Registering scheduled task...

schtasks /create /tn "ngrok-mcp-tunnel" ^
    /tr "ngrok start --all --config \"%PROJECT_DIR%\ngrok.yml\"" ^
    /sc ONLOGON /ru "%USERNAME%" /rl HIGHEST /f

echo.
if %ERRORLEVEL% == 0 (
    echo [OK]  Task created. ngrok will start automatically at each login.
    echo       Config: %PROJECT_DIR%\ngrok.yml
    echo.
    echo  IMPORTANT: ngrok is not running yet.
    echo  To start it now without logging out, run in PowerShell:
    echo.
    echo    schtasks /run /tn "ngrok-mcp-tunnel"
    echo.
    echo  Or launch it in the background directly:
    echo.
    echo    Start-Process ngrok -ArgumentList "start --all --config '%PROJECT_DIR%\ngrok.yml'" -WindowStyle Hidden
    echo.
) else (
    echo [ERROR]  Could not create the task.
    echo          Make sure you run this script as Administrator (right-click - Run as administrator^).
)
echo.
pause
