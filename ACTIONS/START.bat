@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================
REM AstronRPA - Start Services Script
REM Version: 1.0.0
REM Description: Starts all AstronRPA services
REM ============================================

color 0B
title AstronRPA - Starting Services

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║              🚀 Starting AstronRPA Services 🚀            ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM ============================================
REM 1. Initialize Variables
REM ============================================

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "PROJECT_ROOT=%SCRIPT_DIR%\.."
set "LOG_DIR=%SCRIPT_DIR%\logs"
set "LOG_FILE=%LOG_DIR%\start.log"
set "INSTALL_DIR=C:\Program Files\astron-rpa"

REM Create logs directory
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Initialize log
echo [%date% %time%] Starting services > "%LOG_FILE%"

REM Parse arguments
set "DEV_MODE=0"
set "NO_BROWSER=0"
set "QUICK_START=0"

:parse_args
if "%~1"=="" goto end_parse_args
if /i "%~1"=="--dev" (
    set DEV_MODE=1
    shift
    goto parse_args
)
if /i "%~1"=="--no-browser" (
    set NO_BROWSER=1
    shift
    goto parse_args
)
if /i "%~1"=="--quick" (
    set QUICK_START=1
    shift
    goto parse_args
)
shift
goto parse_args

:end_parse_args

REM ============================================
REM 2. Pre-flight Checks
REM ============================================

echo [STEP 1/5] Running pre-flight checks...
echo [%date% %time%] Pre-flight checks started >> "%LOG_FILE%"

REM Check if Docker is running
echo [CHECK] Verifying Docker status...
docker ps >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running
    echo [INFO] Starting Docker Desktop...
    
    REM Try to start Docker Desktop
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    
    echo [INFO] Waiting for Docker to start (60 seconds)...
    timeout /t 60 /nobreak >nul
    
    REM Check again
    docker ps >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Docker failed to start
        echo [INFO] Please start Docker Desktop manually and try again
        goto error_exit
    )
)
echo [OK] Docker is running

REM Check if installation exists
if not exist "%INSTALL_DIR%" (
    echo [WARNING] AstronRPA installation not found
    echo [INFO] Please run SETUP.bat first
    if !QUICK_START! equ 0 (
        choice /C YN /M "Run SETUP.bat now"
        if not errorlevel 2 (
            call "%SCRIPT_DIR%\SETUP.bat"
            goto start_services
        )
    )
    goto error_exit
)
echo [OK] Installation directory found

REM Check configuration
set "CONFIG_FILE=%INSTALL_DIR%\resources\conf.yaml"
if not exist "%CONFIG_FILE%" (
    echo [WARNING] Configuration file not found
    echo [INFO] Creating default configuration...
    
    REM Create basic config
    (
        echo remote_addr: http://localhost:8040/
        echo skip_engine_start: false
        echo log_level: INFO
    ) > "%CONFIG_FILE%"
)
echo [OK] Configuration verified

echo [%date% %time%] Pre-flight checks completed >> "%LOG_FILE%"

REM ============================================
REM 3. Start Docker Services
REM ============================================

echo.
echo [STEP 2/5] Starting Docker services...
echo [%date% %time%] Starting Docker services >> "%LOG_FILE%"

cd /d "%PROJECT_ROOT%\docker"

REM Check if services are already running
docker compose ps | findstr "Up" >nul
if not errorlevel 1 (
    echo [INFO] Docker services already running
    
    choice /C YN /M "Restart services"
    if not errorlevel 2 (
        echo [INFO] Restarting services...
        docker compose restart
    )
) else (
    echo [INFO] Starting Docker containers...
    docker compose up -d
    
    if errorlevel 1 (
        echo [ERROR] Failed to start Docker services
        echo [INFO] Checking logs...
        docker compose logs --tail=50
        goto error_exit
    )
    
    echo [OK] Docker services started
    
    REM Wait for services to be ready
    echo [INFO] Waiting for services to initialize...
    timeout /t 15 /nobreak >nul
)

REM Verify services are running
echo [INFO] Verifying service health...

set "SERVICES_OK=1"
for %%s in (mysql redis minio ai-service openapi-service resource-service robot-service) do (
    docker compose ps %%s | findstr "Up" >nul
    if errorlevel 1 (
        echo [WARNING] Service not running: %%s
        set "SERVICES_OK=0"
    ) else (
        echo [OK] %%s
    )
)

if !SERVICES_OK! equ 0 (
    echo [WARNING] Some services failed to start
    echo [INFO] Check logs: docker compose logs
)

echo [%date% %time%] Docker services started >> "%LOG_FILE%"

REM ============================================
REM 4. Start RPA Engine
REM ============================================

echo.
echo [STEP 3/5] Starting RPA Engine...
echo [%date% %time%] Starting RPA engine >> "%LOG_FILE%"

REM Check if engine is already running
tasklist /FI "IMAGENAME eq python.exe" | findstr "astronverse" >nul
if not errorlevel 1 (
    echo [INFO] RPA Engine is already running
) else (
    echo [INFO] Launching RPA Engine...
    
    REM Start engine in background
    cd /d "%INSTALL_DIR%"
    
    if !DEV_MODE! equ 1 (
        REM Dev mode - visible console
        start "AstronRPA Engine" cmd /k "python_core\python.exe -m astronverse.scheduler --debug"
    ) else (
        REM Production mode - background
        start /min "" "python_core\python.exe" -m astronverse.scheduler
    )
    
    REM Wait for engine to initialize
    echo [INFO] Waiting for engine initialization (10 seconds)...
    timeout /t 10 /nobreak >nul
    
    REM Verify engine is running
    tasklist /FI "IMAGENAME eq python.exe" >nul 2>&1
    if errorlevel 1 (
        echo [WARNING] Engine may not be running
    ) else (
        echo [OK] RPA Engine started
    )
)

echo [%date% %time%] RPA engine started >> "%LOG_FILE%"

REM ============================================
REM 5. Launch Desktop Application
REM ============================================

echo.
echo [STEP 4/5] Launching desktop application...
echo [%date% %time%] Launching desktop app >> "%LOG_FILE%"

REM Check if app is already running
tasklist /FI "IMAGENAME eq astron-rpa.exe" | findstr "astron-rpa.exe" >nul
if not errorlevel 1 (
    echo [INFO] Desktop application is already running
    
    if !QUICK_START! equ 0 (
        choice /C YN /M "Restart application"
        if not errorlevel 2 (
            echo [INFO] Restarting application...
            taskkill /IM astron-rpa.exe /F >nul 2>&1
            timeout /t 2 /nobreak >nul
            start "" "%INSTALL_DIR%\astron-rpa.exe"
        )
    )
) else (
    echo [INFO] Starting AstronRPA Desktop...
    
    if exist "%INSTALL_DIR%\astron-rpa.exe" (
        start "" "%INSTALL_DIR%\astron-rpa.exe"
        echo [OK] Desktop application launched
    ) else (
        echo [WARNING] Desktop application not found
        echo [INFO] Location: %INSTALL_DIR%\astron-rpa.exe
    )
)

echo [%date% %time%] Desktop app launched >> "%LOG_FILE%"

REM ============================================
REM 6. Open Web Browser
REM ============================================

echo.
echo [STEP 5/5] Opening web interface...

REM Get server address from config
set "SERVER_URL=http://localhost:8040"

if !NO_BROWSER! equ 0 (
    echo [INFO] Opening web browser...
    
    REM Wait a moment for services to be ready
    timeout /t 3 /nobreak >nul
    
    REM Open default browser
    start "" "%SERVER_URL%"
    
    echo [OK] Web interface opened: %SERVER_URL%
) else (
    echo [INFO] Web interface available at: %SERVER_URL%
)

echo [%date% %time%] Web interface opened >> "%LOG_FILE%"

REM ============================================
REM 7. Display Status Dashboard
REM ============================================

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║              ✅ AstronRPA Services Started ✅              ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo [SERVICE STATUS]
echo.

REM Docker Services
echo 🐳 Docker Services:
docker compose ps --format "table {{.Service}}\t{{.Status}}" 2>nul

echo.
echo 🖥️  Desktop Application:
tasklist /FI "IMAGENAME eq astron-rpa.exe" | findstr "astron-rpa.exe" >nul
if not errorlevel 1 (
    echo   Status: ✅ Running
) else (
    echo   Status: ⚠️  Not Running
)

echo.
echo 🤖 RPA Engine:
tasklist /FI "IMAGENAME eq python.exe" | findstr "python.exe" >nul
if not errorlevel 1 (
    echo   Status: ✅ Running
) else (
    echo   Status: ⚠️  Not Running
)

echo.
echo ═══════════════════════════════════════════════════════════
echo.
echo [ACCESS POINTS]
echo.
echo   🌐 Web UI:          %SERVER_URL%
echo   📡 API Gateway:     http://localhost:32742
echo   🔐 Auth Service:    http://localhost:8000
echo   💾 MinIO Console:   http://localhost:9001
echo.
echo [DEFAULT CREDENTIALS]
echo.
echo   Username: admin
echo   Password: admin123
echo.
echo ═══════════════════════════════════════════════════════════
echo.
echo [USEFUL COMMANDS]
echo.
echo   • Stop services:    %SCRIPT_DIR%\STOP.bat
echo   • View logs:        docker compose logs -f
echo   • Check status:     docker compose ps
echo   • Restart service:  docker compose restart [service-name]
echo.
echo ═══════════════════════════════════════════════════════════
echo.

if !DEV_MODE! equ 1 (
    echo [DEV MODE] Services started in development mode
    echo [INFO] Frontend hot-reload enabled
    echo [INFO] Debug logging enabled
    echo.
)

echo [INFO] AstronRPA is ready for automation!
echo [INFO] Press any key to exit this window...
echo [INFO] Services will continue running in the background
echo.

echo [%date% %time%] All services started successfully >> "%LOG_FILE%"

pause
exit /b 0

REM ============================================
REM Error Handler
REM ============================================

:error_exit
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║              ❌ Startup Failed ❌                          ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo [ERROR] Failed to start AstronRPA services
echo [INFO] Check logs: %LOG_FILE%
echo.
echo [TROUBLESHOOTING]
echo.
echo   1. Verify Docker Desktop is running
echo   2. Check if ports are available (8040, 32742, etc.)
echo   3. Ensure installation completed successfully
echo   4. Review logs for specific errors
echo   5. Try running SETUP.bat again
echo.
echo [SUPPORT]
echo.
echo   GitHub: https://github.com/iflytek/astron-rpa/issues
echo   Email: cbg_rpa_ml@iflytek.com
echo.
echo [%date% %time%] Startup failed >> "%LOG_FILE%"
pause
exit /b 1

