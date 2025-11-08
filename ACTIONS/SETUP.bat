@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================
REM AstronRPA - Complete Setup Script
REM Version: 1.0.0
REM Description: Automates the entire installation process
REM ============================================

color 0A
title AstronRPA - Setup Wizard

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║              🚀 AstronRPA Setup Wizard 🚀                 ║
echo ║                                                            ║
echo ║         Enterprise-Grade RPA Automation Platform          ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo [INFO] Starting automated setup process...
echo [INFO] This will take approximately 45-90 minutes.
echo.

REM ============================================
REM 1. Initialize Variables
REM ============================================

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "PROJECT_ROOT=%SCRIPT_DIR%\.."
set "LOG_DIR=%SCRIPT_DIR%\logs"
set "LOG_FILE=%LOG_DIR%\setup.log"

REM Create logs directory
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Initialize log file
echo [%date% %time%] Setup started > "%LOG_FILE%"

REM Default paths
set "PYTHON_EXE=C:\Program Files\Python313\python.exe"
set "SEVENZ_EXE=C:\Program Files\7-Zip\7z.exe"
set "SKIP_DEPS=0"
set "SILENT_MODE=0"

REM ============================================
REM 2. Parse Arguments
REM ============================================

:parse_args
if "%~1"=="" goto end_parse_args
if /i "%~1"=="--python-path" (
    set "PYTHON_EXE=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--silent" (
    set SILENT_MODE=1
    shift
    goto parse_args
)
if /i "%~1"=="--skip-deps" (
    set SKIP_DEPS=1
    shift
    goto parse_args
)
if /i "%~1"=="--update" (
    set UPDATE_MODE=1
    shift
    goto parse_args
)
if /i "%~1"=="--help" goto show_help
shift
goto parse_args

:show_help
echo.
echo Usage: SETUP.bat [options]
echo.
echo Options:
echo   --python-path ^<path^>    Specify Python 3.13 executable path
echo   --silent                 Run without prompts (use defaults)
echo   --skip-deps              Skip dependency installation
echo   --update                 Update existing installation
echo   --help                   Display this help message
echo.
echo Examples:
echo   SETUP.bat
echo   SETUP.bat --python-path "D:\Python313\python.exe"
echo   SETUP.bat --silent --skip-deps
echo.
exit /b 0

:end_parse_args

REM ============================================
REM 3. Administrator Check
REM ============================================

echo [STEP 1/10] Checking administrator privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] This script should be run as Administrator for best results.
    if !SILENT_MODE! equ 0 (
        echo.
        choice /C YN /M "Continue anyway"
        if errorlevel 2 exit /b 1
    )
) else (
    echo [OK] Running with administrator privileges
)
echo [%date% %time%] Admin check completed >> "%LOG_FILE%"

REM ============================================
REM 4. System Requirements Check
REM ============================================

echo.
echo [STEP 2/10] Verifying system requirements...
echo [INFO] Checking Windows version...

REM Check Windows version
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%version%" == "10.0" (
    echo [OK] Windows 10/11 detected
) else (
    echo [ERROR] Windows 10 or later required
    echo [ERROR] Your version: %version%
    goto error_exit
)

REM Check disk space
echo [INFO] Checking disk space...
for /f "tokens=3" %%a in ('dir /-c %SystemDrive%\ ^| find "bytes free"') do set FREE_SPACE=%%a
set FREE_SPACE=%FREE_SPACE:,=%
if %FREE_SPACE% LSS 21474836480 (
    echo [WARNING] Low disk space detected. Recommended: 20GB+
    echo [WARNING] Available: %FREE_SPACE% bytes
)

REM Check RAM
echo [INFO] Checking system memory...
for /f "tokens=4" %%a in ('systeminfo ^| find "Total Physical Memory"') do set TOTAL_RAM=%%a
echo [OK] Total RAM: %TOTAL_RAM%

echo [%date% %time%] System requirements checked >> "%LOG_FILE%"

REM ============================================
REM 5. Dependency Detection
REM ============================================

echo.
echo [STEP 3/10] Detecting installed dependencies...

set "MISSING_DEPS="

REM Check Python
echo [INFO] Checking Python 3.13...
python --version 2>nul | findstr "3.13" >nul
if errorlevel 1 (
    echo [NOT FOUND] Python 3.13
    set "MISSING_DEPS=!MISSING_DEPS! Python"
) else (
    echo [OK] Python 3.13 found
)

REM Check Node.js
echo [INFO] Checking Node.js...
node --version 2>nul | findstr "v22\|v23" >nul
if errorlevel 1 (
    echo [NOT FOUND] Node.js 22+
    set "MISSING_DEPS=!MISSING_DEPS! Node.js"
) else (
    echo [OK] Node.js found
)

REM Check pnpm
echo [INFO] Checking pnpm...
pnpm --version >nul 2>&1
if errorlevel 1 (
    echo [NOT FOUND] pnpm
    set "MISSING_DEPS=!MISSING_DEPS! pnpm"
) else (
    echo [OK] pnpm found
)

REM Check UV
echo [INFO] Checking UV...
uv --version >nul 2>&1
if errorlevel 1 (
    echo [NOT FOUND] UV
    set "MISSING_DEPS=!MISSING_DEPS! UV"
) else (
    echo [OK] UV found
)

REM Check Rust
echo [INFO] Checking Rust...
rustc --version >nul 2>&1
if errorlevel 1 (
    echo [NOT FOUND] Rust
    set "MISSING_DEPS=!MISSING_DEPS! Rust"
) else (
    echo [OK] Rust found
)

REM Check 7-Zip
echo [INFO] Checking 7-Zip...
7z --help >nul 2>&1
if errorlevel 1 (
    if not exist "%SEVENZ_EXE%" (
        echo [NOT FOUND] 7-Zip
        set "MISSING_DEPS=!MISSING_DEPS! 7-Zip"
    )
) else (
    echo [OK] 7-Zip found
)

REM Check Docker
echo [INFO] Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo [NOT FOUND] Docker
    set "MISSING_DEPS=!MISSING_DEPS! Docker"
) else (
    echo [OK] Docker found
)

REM Check SWIG
echo [INFO] Checking SWIG...
swig -version >nul 2>&1
if errorlevel 1 (
    echo [WARNING] SWIG not found (optional)
)

echo [%date% %time%] Dependencies checked >> "%LOG_FILE%"

REM ============================================
REM 6. Install Missing Dependencies
REM ============================================

if not "!MISSING_DEPS!"=="" (
    echo.
    echo [STEP 4/10] Installing missing dependencies...
    echo [INFO] Missing: !MISSING_DEPS!
    
    if !SKIP_DEPS! equ 1 (
        echo [WARNING] Skipping dependency installation (--skip-deps flag)
        goto skip_install_deps
    )
    
    if !SILENT_MODE! equ 0 (
        echo.
        choice /C YN /M "Install missing dependencies automatically"
        if errorlevel 2 goto skip_install_deps
    )
    
    REM Install via winget
    echo [INFO] Using Windows Package Manager (winget) to install dependencies...
    
    echo !MISSING_DEPS! | findstr "Python" >nul
    if not errorlevel 1 (
        echo [INSTALLING] Python 3.13...
        winget install -e --id Python.Python.3.13 --silent --accept-source-agreements --accept-package-agreements
    )
    
    echo !MISSING_DEPS! | findstr "Node.js" >nul
    if not errorlevel 1 (
        echo [INSTALLING] Node.js...
        winget install -e --id OpenJS.NodeJS.LTS --silent --accept-source-agreements --accept-package-agreements
    )
    
    echo !MISSING_DEPS! | findstr "pnpm" >nul
    if not errorlevel 1 (
        echo [INSTALLING] pnpm...
        call npm install -g pnpm@latest
    )
    
    echo !MISSING_DEPS! | findstr "UV" >nul
    if not errorlevel 1 (
        echo [INSTALLING] UV...
        powershell -Command "irm https://astral.sh/uv/install.ps1 | iex"
    )
    
    echo !MISSING_DEPS! | findstr "Rust" >nul
    if not errorlevel 1 (
        echo [INSTALLING] Rust...
        winget install -e --id Rustlang.Rustup --silent --accept-source-agreements --accept-package-agreements
    )
    
    echo !MISSING_DEPS! | findstr "7-Zip" >nul
    if not errorlevel 1 (
        echo [INSTALLING] 7-Zip...
        winget install -e --id 7zip.7zip --silent --accept-source-agreements --accept-package-agreements
    )
    
    echo !MISSING_DEPS! | findstr "Docker" >nul
    if not errorlevel 1 (
        echo [INSTALLING] Docker Desktop...
        winget install -e --id Docker.DockerDesktop --silent --accept-source-agreements --accept-package-agreements
        echo [WARNING] Docker Desktop requires system restart
        echo [WARNING] Please restart Windows and re-run this script
        if !SILENT_MODE! equ 0 pause
        exit /b 1
    )
    
    echo [OK] Dependencies installed successfully
    echo [INFO] Please restart your terminal for changes to take effect
    
    if !SILENT_MODE! equ 0 (
        echo.
        choice /C YN /M "Restart terminal now and re-run this script"
        if not errorlevel 2 exit /b 0
    )
)

:skip_install_deps

REM ============================================
REM 7. Build RPA Engine
REM ============================================

echo.
echo [STEP 5/10] Building RPA Engine...
echo [INFO] This may take 15-25 minutes...

cd /d "%PROJECT_ROOT%"

REM Check if Python executable exists
if not exist "%PYTHON_EXE%" (
    echo [ERROR] Python not found at: %PYTHON_EXE%
    echo [INFO] Searching for Python 3.13...
    
    REM Try to find Python
    for %%p in (python.exe python3.exe python313.exe) do (
        where %%p >nul 2>&1
        if not errorlevel 1 (
            for /f "tokens=*" %%i in ('where %%p') do (
                set "PYTHON_EXE=%%i"
                echo [FOUND] Python at: !PYTHON_EXE!
                goto found_python
            )
        )
    )
    
    echo [ERROR] Could not find Python 3.13 installation
    echo [INFO] Please install Python 3.13 and re-run this script
    goto error_exit
)

:found_python
echo [INFO] Using Python: %PYTHON_EXE%

REM Run build script
echo [INFO] Running build.bat...
call build.bat --python-exe "%PYTHON_EXE%"

if errorlevel 1 (
    echo [ERROR] Build failed
    echo [INFO] Check logs at: %PROJECT_ROOT%\build\logs\
    goto error_exit
)

echo [OK] RPA Engine built successfully
echo [%date% %time%] Engine build completed >> "%LOG_FILE%"

REM ============================================
REM 8. Install Desktop Application
REM ============================================

echo.
echo [STEP 6/10] Installing Desktop Application...

set "MSI_PATH=%PROJECT_ROOT%\frontend\packages\tauri-app\src-tauri\target\debug\bundle\msi"

if exist "%MSI_PATH%\*.msi" (
    for %%f in ("%MSI_PATH%\*.msi") do (
        echo [INFO] Found installer: %%~nxf
        echo [INFO] Installing AstronRPA Desktop...
        
        msiexec /i "%%f" /qn /l*v "%LOG_DIR%\install.log"
        
        if errorlevel 1 (
            echo [WARNING] Silent installation failed, trying interactive...
            msiexec /i "%%f"
        )
        
        echo [OK] Desktop application installed
        goto msi_installed
    )
) else (
    echo [WARNING] MSI installer not found
    echo [INFO] You may need to build the application manually
)

:msi_installed
echo [%date% %time%] Desktop app installed >> "%LOG_FILE%"

REM ============================================
REM 9. Setup Docker Services
REM ============================================

echo.
echo [STEP 7/10] Setting up Docker services...

cd /d "%PROJECT_ROOT%\docker"

REM Check if Docker is running
docker ps >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Docker is not running
    echo [INFO] Please start Docker Desktop and wait 1 minute
    
    if !SILENT_MODE! equ 0 (
        choice /C YN /M "Start Docker Desktop now"
        if not errorlevel 2 (
            start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
            echo [INFO] Waiting for Docker to start (60 seconds)...
            timeout /t 60 /nobreak >nul
        )
    )
)

REM Create .env file if it doesn't exist
if not exist .env (
    echo [INFO] Creating .env configuration...
    copy .env.example .env
    
    REM Get local IP address
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
        set "LOCAL_IP=%%a"
        goto got_ip
    )
    :got_ip
    set "LOCAL_IP=!LOCAL_IP: =!"
    
    REM Update .env with local IP
    powershell -Command "(Get-Content .env) -replace 'YOUR_SERVER_IP', '!LOCAL_IP!' | Set-Content .env"
    
    echo [OK] Configuration created with IP: !LOCAL_IP!
)

REM Pull Docker images
echo [INFO] Pulling Docker images (this may take 10-20 minutes)...
docker compose pull

REM Start services
echo [INFO] Starting Docker services...
docker compose up -d

if errorlevel 1 (
    echo [ERROR] Failed to start Docker services
    echo [INFO] Check logs: docker compose logs
    goto error_exit
)

echo [OK] Docker services started
echo [%date% %time%] Docker services started >> "%LOG_FILE%"

REM Wait for services to be ready
echo [INFO] Waiting for services to initialize (30 seconds)...
timeout /t 30 /nobreak >nul

REM ============================================
REM 10. Configure Desktop Application
REM ============================================

echo.
echo [STEP 8/10] Configuring desktop application...

set "INSTALL_DIR=C:\Program Files\astron-rpa"
set "CONFIG_FILE=%INSTALL_DIR%\resources\conf.yaml"

if exist "%CONFIG_FILE%" (
    echo [INFO] Updating configuration file...
    
    REM Backup original
    copy "%CONFIG_FILE%" "%CONFIG_FILE%.backup" >nul
    
    REM Update server address
    powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'http://localhost:8040/', 'http://!LOCAL_IP!:8040/' | Set-Content '%CONFIG_FILE%'"
    
    echo [OK] Configuration updated
) else (
    echo [WARNING] Configuration file not found
    echo [INFO] Manual configuration may be required
)

echo [%date% %time%] Configuration completed >> "%LOG_FILE%"

REM ============================================
REM 11. Create Desktop Shortcuts
REM ============================================

echo.
echo [STEP 9/10] Creating desktop shortcuts...

set "DESKTOP=%USERPROFILE%\Desktop"

REM Create START shortcut
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Start AstronRPA.lnk'); $Shortcut.TargetPath = '%SCRIPT_DIR%\START.bat'; $Shortcut.WorkingDirectory = '%PROJECT_ROOT%'; $Shortcut.IconLocation = '%INSTALL_DIR%\astron-rpa.exe'; $Shortcut.Description = 'Start AstronRPA Services'; $Shortcut.Save()"

REM Create STOP shortcut
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Stop AstronRPA.lnk'); $Shortcut.TargetPath = '%SCRIPT_DIR%\STOP.bat'; $Shortcut.WorkingDirectory = '%PROJECT_ROOT%'; $Shortcut.Description = 'Stop AstronRPA Services'; $Shortcut.Save()"

REM Create APP shortcut
if exist "%INSTALL_DIR%\astron-rpa.exe" (
    powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\AstronRPA.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\astron-rpa.exe'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'AstronRPA Desktop Application'; $Shortcut.Save()"
)

echo [OK] Desktop shortcuts created
echo [%date% %time%] Shortcuts created >> "%LOG_FILE%"

REM ============================================
REM 12. Verification & Summary
REM ============================================

echo.
echo [STEP 10/10] Verifying installation...

set "ALL_OK=1"

REM Verify Docker services
docker compose ps | findstr "Up" >nul
if errorlevel 1 (
    echo [WARNING] Some Docker services may not be running
    set "ALL_OK=0"
)

REM Verify desktop app
if exist "%INSTALL_DIR%\astron-rpa.exe" (
    echo [OK] Desktop application installed
) else (
    echo [WARNING] Desktop application not found
    set "ALL_OK=0"
)

REM Verify engine
if exist "%INSTALL_DIR%\python_core\python.exe" (
    echo [OK] RPA Engine installed
) else (
    echo [WARNING] RPA Engine not found
    set "ALL_OK=0"
)

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║              ✅ Setup Complete! ✅                         ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo [INFO] Installation Summary:
echo   • Project Directory: %PROJECT_ROOT%
echo   • Install Directory: %INSTALL_DIR%
echo   • Server Address: http://!LOCAL_IP!:8040
echo   • Web UI: http://!LOCAL_IP!:8040
echo.
echo [NEXT STEPS]
echo   1. Double-click "Start AstronRPA" on your desktop
echo   2. Open browser to: http://!LOCAL_IP!:8040
echo   3. Login with default credentials:
echo      Username: admin
echo      Password: admin123
echo.
echo [INFO] Desktop shortcuts created:
echo   • Start AstronRPA.lnk
echo   • Stop AstronRPA.lnk
echo   • AstronRPA.lnk (Application)
echo.
echo [INFO] Useful commands:
echo   • Start services:  %SCRIPT_DIR%\START.bat
echo   • Stop services:   %SCRIPT_DIR%\STOP.bat
echo   • Check status:    docker compose ps
echo.

if !ALL_OK! equ 0 (
    echo [WARNING] Some components may need manual configuration
    echo [INFO] Check setup log: %LOG_FILE%
)

echo [%date% %time%] Setup completed successfully >> "%LOG_FILE%"

if !SILENT_MODE! equ 0 (
    echo.
    choice /C YN /M "Start AstronRPA now"
    if not errorlevel 2 (
        call "%SCRIPT_DIR%\START.bat"
    )
)

goto end

REM ============================================
REM Error Handler
REM ============================================

:error_exit
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║              ❌ Setup Failed ❌                            ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo [ERROR] Setup encountered errors. Please review the messages above.
echo [INFO] Setup log: %LOG_FILE%
echo.
echo [HELP] Common solutions:
echo   1. Run as Administrator
echo   2. Check internet connection
echo   3. Ensure 20GB+ free disk space
echo   4. Install dependencies manually
echo   5. Review setup log for details
echo.
echo [SUPPORT]
echo   GitHub: https://github.com/iflytek/astron-rpa/issues
echo   Email: cbg_rpa_ml@iflytek.com
echo.
echo [%date% %time%] Setup failed >> "%LOG_FILE%"
if !SILENT_MODE! equ 0 pause
exit /b 1

:end
if !SILENT_MODE! equ 0 pause
exit /b 0

