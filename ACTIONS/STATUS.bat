@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================
REM AstronRPA - Service Status Check
REM Version: 1.0.0
REM ============================================

color 0E
title AstronRPA - Service Status

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║              📊 AstronRPA Service Status 📊              ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

set "PROJECT_ROOT=%~dp0\.."
set "INSTALL_DIR=C:\Program Files\astron-rpa"

echo [INFO] Checking service status...
echo.

REM ============================================
REM Docker Services
REM ============================================

echo ═══════════════════════════════════════════════════════════
echo 🐳 Docker Services
echo ═══════════════════════════════════════════════════════════

docker ps >nul 2>&1
if errorlevel 1 (
    echo   Status: ❌ Docker not running
    echo.
) else (
    cd /d "%PROJECT_ROOT%\docker"
    
    echo.
    docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"
    echo.
    
    REM Check individual services
    for %%s in (mysql redis minio ai-service openapi-service resource-service robot-service) do (
        docker compose ps %%s 2>nul | findstr "Up" >nul
        if not errorlevel 1 (
            echo   ✅ %%s
        ) else (
            echo   ❌ %%s
        )
    )
)

echo.

REM ============================================
REM Desktop Application
REM ============================================

echo ═══════════════════════════════════════════════════════════
echo 🖥️  Desktop Application
echo ═══════════════════════════════════════════════════════════
echo.

tasklist /FI "IMAGENAME eq astron-rpa.exe" 2>nul | findstr "astron-rpa.exe" >nul
if not errorlevel 1 (
    echo   Status: ✅ Running
    for /f "tokens=2" %%p in ('tasklist /FI "IMAGENAME eq astron-rpa.exe" /FO CSV /NH') do (
        echo   PID: %%~p
    )
) else (
    echo   Status: ❌ Not Running
)

if exist "%INSTALL_DIR%\astron-rpa.exe" (
    echo   Location: ✅ %INSTALL_DIR%
) else (
    echo   Location: ❌ Not installed
)

echo.

REM ============================================
REM RPA Engine
REM ============================================

echo ═══════════════════════════════════════════════════════════
echo 🤖 RPA Engine
echo ═══════════════════════════════════════════════════════════
echo.

tasklist /FI "IMAGENAME eq python.exe" 2>nul | findstr "python.exe" >nul
if not errorlevel 1 (
    set "ENGINE_FOUND=0"
    for /f "tokens=2" %%p in ('tasklist /FI "IMAGENAME eq python.exe" /FO CSV /NH') do (
        wmic process where "ProcessId=%%~p" get CommandLine 2>nul | findstr "astronverse" >nul
        if not errorlevel 1 (
            echo   Status: ✅ Running
            echo   PID: %%~p
            set "ENGINE_FOUND=1"
        )
    )
    if !ENGINE_FOUND! equ 0 (
        echo   Status: ❌ Not Running
    )
) else (
    echo   Status: ❌ Not Running
)

if exist "%INSTALL_DIR%\python_core\python.exe" (
    echo   Engine Path: ✅ %INSTALL_DIR%\python_core
) else (
    echo   Engine Path: ❌ Not found
)

echo.

REM ============================================
REM Network Status
REM ============================================

echo ═══════════════════════════════════════════════════════════
echo 🌐 Network Status
echo ═══════════════════════════════════════════════════════════
echo.

REM Check if ports are listening
for %%p in (8040:Web-UI 32742:Engine 32743:WebSocket 8000:Auth 3306:MySQL 6379:Redis 9000:MinIO) do (
    for /f "tokens=1,2 delims=:" %%a in ("%%p") do (
        netstat -an | findstr ":%%a.*LISTENING" >nul
        if not errorlevel 1 (
            echo   ✅ Port %%a ^(%%b^) - Listening
        ) else (
            echo   ❌ Port %%a ^(%%b^) - Not listening
        )
    )
)

echo.

REM ============================================
REM Access Points
REM ============================================

echo ═══════════════════════════════════════════════════════════
echo 🔗 Access Points
echo ═══════════════════════════════════════════════════════════
echo.

set "SERVER_URL=http://localhost:8040"

REM Test connectivity
powershell -Command "try { Invoke-WebRequest -Uri '%SERVER_URL%' -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 (
    echo   ✅ Web UI:          %SERVER_URL%
) else (
    echo   ❌ Web UI:          %SERVER_URL% ^(Not accessible^)
)

echo   🔗 API Gateway:     http://localhost:32742
echo   🔐 Auth Service:    http://localhost:8000
echo   💾 MinIO Console:   http://localhost:9001
echo.

REM ============================================
REM System Resources
REM ============================================

echo ═══════════════════════════════════════════════════════════
echo 💻 System Resources
echo ═══════════════════════════════════════════════════════════
echo.

REM CPU Usage
for /f "skip=1" %%p in ('wmic cpu get loadpercentage') do (
    echo   CPU Usage: %%p%%
    goto cpu_done
)
:cpu_done

REM Memory Usage
for /f "skip=1 tokens=1-4" %%a in ('wmic OS get FreePhysicalMemory^,TotalVisibleMemorySize /value') do (
    if "%%a"=="FreePhysicalMemory" set FREE_MEM=%%b
    if "%%a"=="TotalVisibleMemorySize" set TOTAL_MEM=%%b
)
set /a USED_MEM=TOTAL_MEM-FREE_MEM
set /a MEM_PERCENT=(USED_MEM*100)/TOTAL_MEM
echo   Memory Usage: %MEM_PERCENT%%% ^(%USED_MEM% KB / %TOTAL_MEM% KB^)

REM Disk Space
for /f "tokens=3" %%a in ('dir /-c %SystemDrive%\ ^| find "bytes free"') do (
    set FREE_DISK=%%a
    goto disk_done
)
:disk_done
set FREE_DISK=%FREE_DISK:,=%
set /a FREE_GB=FREE_DISK/1073741824
echo   Free Disk Space: %FREE_GB% GB

echo.

REM ============================================
REM Summary
REM ============================================

echo ═══════════════════════════════════════════════════════════
echo 📋 Summary
echo ═══════════════════════════════════════════════════════════
echo.

set "OVERALL_STATUS=OK"

docker ps >nul 2>&1
if errorlevel 1 set "OVERALL_STATUS=WARN"

tasklist /FI "IMAGENAME eq astron-rpa.exe" | findstr "astron-rpa.exe" >nul
if errorlevel 1 set "OVERALL_STATUS=WARN"

if "%OVERALL_STATUS%"=="OK" (
    echo   Overall Status: 🟢 All Systems Operational
) else (
    echo   Overall Status: 🟡 Some Services Not Running
)

echo.
echo   Last Checked: %date% %time%
echo.
echo ═══════════════════════════════════════════════════════════
echo.
echo [COMMANDS]
echo.
echo   • Start services:   ACTIONS\START.bat
echo   • Stop services:    ACTIONS\STOP.bat
echo   • View logs:        docker compose logs -f
echo   • Restart service:  docker compose restart [service-name]
echo.

pause
exit /b 0

