@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================
REM AstronRPA - Stop Services Script
REM Version: 1.0.0
REM Description: Gracefully stops all AstronRPA services
REM ============================================

color 0C
title AstronRPA - Stopping Services

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║              🛑 Stopping AstronRPA Services 🛑            ║
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
set "LOG_FILE=%LOG_DIR%\stop.log"
set "INSTALL_DIR=C:\Program Files\astron-rpa"

REM Create logs directory
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Initialize log
echo [%date% %time%] Stopping services > "%LOG_FILE%"

REM Parse arguments
set "FORCE_STOP=0"
set "KEEP_DOCKER=0"
set "SILENT=0"

:parse_args
if "%~1"=="" goto end_parse_args
if /i "%~1"=="--force" (
    set FORCE_STOP=1
    shift
    goto parse_args
)
if /i "%~1"=="--keep-docker" (
    set KEEP_DOCKER=1
    shift
    goto parse_args
)
if /i "%~1"=="--silent" (
    set SILENT=1
    shift
    goto parse_args
)
shift
goto parse_args

:end_parse_args

REM ============================================
REM 2. Confirm Shutdown
REM ============================================

if !SILENT! equ 0 (
    if !FORCE_STOP! equ 0 (
        echo [WARNING] This will stop all AstronRPA services
        echo.
        choice /C YN /M "Continue with shutdown"
        if errorlevel 2 (
            echo [INFO] Shutdown cancelled
            exit /b 0
        )
    )
)

echo [INFO] Initiating graceful shutdown...
echo [%date% %time%] Shutdown initiated >> "%LOG_FILE%"

REM ============================================
REM 3. Stop Desktop Application
REM ============================================

echo.
echo [STEP 1/4] Stopping desktop application...
echo [%date% %time%] Stopping desktop app >> "%LOG_FILE%"

REM Check if application is running
tasklist /FI "IMAGENAME eq astron-rpa.exe" | findstr "astron-rpa.exe" >nul
if not errorlevel 1 (
    echo [INFO] Closing AstronRPA Desktop...
    
    if !FORCE_STOP! equ 1 (
        REM Force close
        taskkill /IM astron-rpa.exe /F >nul 2>&1
        echo [OK] Desktop application force closed
    ) else (
        REM Graceful close
        taskkill /IM astron-rpa.exe >nul 2>&1
        
        REM Wait for graceful shutdown
        timeout /t 5 /nobreak >nul
        
        REM Check if still running
        tasklist /FI "IMAGENAME eq astron-rpa.exe" | findstr "astron-rpa.exe" >nul
        if not errorlevel 1 (
            echo [WARNING] Application did not close gracefully, forcing...
            taskkill /IM astron-rpa.exe /F >nul 2>&1
        )
        
        echo [OK] Desktop application closed
    )
) else (
    echo [INFO] Desktop application not running
)

echo [%date% %time%] Desktop app stopped >> "%LOG_FILE%"

REM ============================================
REM 4. Stop RPA Engine
REM ============================================

echo.
echo [STEP 2/4] Stopping RPA Engine...
echo [%date% %time%] Stopping RPA engine >> "%LOG_FILE%"

REM Find Python processes related to AstronRPA
echo [INFO] Searching for RPA Engine processes...

for /f "tokens=2" %%p in ('tasklist /FI "IMAGENAME eq python.exe" /FO CSV /NH 2^>nul ^| findstr "python.exe"') do (
    set "PID=%%~p"
    
    REM Check if this is our engine process
    wmic process where "ProcessId=!PID!" get CommandLine 2>nul | findstr "astronverse" >nul
    if not errorlevel 1 (
        echo [INFO] Found RPA Engine (PID: !PID!)
        
        if !FORCE_STOP! equ 1 (
            taskkill /PID !PID! /F >nul 2>&1
            echo [OK] Engine process force terminated
        ) else (
            taskkill /PID !PID! >nul 2>&1
            
            REM Wait for graceful shutdown
            timeout /t 5 /nobreak >nul
            
            REM Check if still running
            tasklist /FI "PID eq !PID!" | findstr "!PID!" >nul
            if not errorlevel 1 (
                echo [WARNING] Engine did not stop gracefully, forcing...
                taskkill /PID !PID! /F >nul 2>&1
            )
            
            echo [OK] Engine process stopped
        )
    )
)

REM Double-check no python processes remain
tasklist /FI "IMAGENAME eq python.exe" | findstr "astronverse" >nul
if not errorlevel 1 (
    echo [WARNING] Some engine processes may still be running
    if !FORCE_STOP! equ 1 (
        echo [INFO] Force killing all Python processes...
        taskkill /IM python.exe /F >nul 2>&1
    )
) else (
    echo [OK] RPA Engine stopped
)

echo [%date% %time%] RPA engine stopped >> "%LOG_FILE%"

REM ============================================
REM 5. Stop Docker Services
REM ============================================

echo.
echo [STEP 3/4] Stopping Docker services...
echo [%date% %time%] Stopping Docker services >> "%LOG_FILE%"

if !KEEP_DOCKER! equ 1 (
    echo [INFO] Keeping Docker services running (--keep-docker flag)
    goto skip_docker_stop
)

cd /d "%PROJECT_ROOT%\docker"

REM Check if Docker is running
docker ps >nul 2>&1
if errorlevel 1 (
    echo [INFO] Docker not running or not accessible
    goto skip_docker_stop
)

REM Check if services are running
docker compose ps | findstr "Up" >nul
if errorlevel 1 (
    echo [INFO] Docker services not running
    goto skip_docker_stop
)

echo [INFO] Stopping Docker containers...

if !FORCE_STOP! equ 1 (
    REM Force stop with kill
    docker compose kill
    docker compose down
    echo [OK] Docker services force stopped
) else (
    REM Graceful stop
    docker compose stop
    
    REM Wait for services to stop
    echo [INFO] Waiting for services to shut down gracefully (10 seconds)...
    timeout /t 10 /nobreak >nul
    
    REM Check if still running
    docker compose ps | findstr "Up" >nul
    if not errorlevel 1 (
        echo [WARNING] Some services did not stop gracefully
        echo [INFO] Force stopping remaining services...
        docker compose kill
    )
    
    echo [OK] Docker services stopped
)

REM Display final status
echo [INFO] Docker service status:
docker compose ps

:skip_docker_stop
echo [%date% %time%] Docker services stopped >> "%LOG_FILE%"

REM ============================================
REM 6. Cleanup & Summary
REM ============================================

echo.
echo [STEP 4/4] Cleaning up...
echo [%date% %time%] Cleanup started >> "%LOG_FILE%"

REM Clean temporary files
if exist "%TEMP%\astronrpa-*" (
    echo [INFO] Removing temporary files...
    del /Q "%TEMP%\astronrpa-*" >nul 2>&1
)

REM Clean engine cache
if exist "%INSTALL_DIR%\cache" (
    echo [INFO] Clearing engine cache...
    rd /S /Q "%INSTALL_DIR%\cache" >nul 2>&1
)

REM Save current state
echo [INFO] Saving application state...
if exist "%INSTALL_DIR%\resources\state.json" (
    copy "%INSTALL_DIR%\resources\state.json" "%INSTALL_DIR%\resources\state.backup.json" >nul 2>&1
)

echo [OK] Cleanup completed
echo [%date% %time%] Cleanup completed >> "%LOG_FILE%"

REM ============================================
REM 7. Display Shutdown Summary
REM ============================================

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║              ✅ Shutdown Complete ✅                       ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo [SHUTDOWN SUMMARY]
echo.
echo   Component                Status
echo   ────────────────────────────────────────
echo   Desktop Application      ✅ Stopped
echo   RPA Engine              ✅ Stopped

if !KEEP_DOCKER! equ 1 (
    echo   Docker Services         ⚠️  Kept Running
) else (
    echo   Docker Services         ✅ Stopped
)

echo   Temporary Files         ✅ Cleaned
echo.
echo ═══════════════════════════════════════════════════════════
echo.

REM Verify all processes stopped
set "ALL_STOPPED=1"

tasklist /FI "IMAGENAME eq astron-rpa.exe" | findstr "astron-rpa.exe" >nul
if not errorlevel 1 (
    echo [WARNING] Desktop application still running
    set "ALL_STOPPED=0"
)

tasklist /FI "IMAGENAME eq python.exe" | findstr "astronverse" >nul
if not errorlevel 1 (
    echo [WARNING] RPA Engine processes still running
    set "ALL_STOPPED=0"
)

if !KEEP_DOCKER! equ 0 (
    docker compose ps 2>nul | findstr "Up" >nul
    if not errorlevel 1 (
        echo [WARNING] Some Docker services still running
        set "ALL_STOPPED=0"
    )
)

if !ALL_STOPPED! equ 1 (
    echo [✅] All services stopped successfully
) else (
    echo [⚠️] Some services may still be running
    echo [INFO] Use --force flag to force stop all services
    echo [INFO] Command: STOP.bat --force
)

echo.
echo ═══════════════════════════════════════════════════════════
echo.
echo [INFORMATION]
echo.
echo   To start services again:
echo   • Double-click: Start AstronRPA (Desktop shortcut)
echo   • Or run: %SCRIPT_DIR%\START.bat
echo.

if !KEEP_DOCKER! equ 1 (
    echo [NOTE] Docker services were kept running
    echo [INFO] To stop Docker services: docker compose down
    echo.
)

echo   Log file: %LOG_FILE%
echo.
echo ═══════════════════════════════════════════════════════════
echo.

echo [%date% %time%] Shutdown completed successfully >> "%LOG_FILE%"

if !SILENT! equ 0 pause

exit /b 0

