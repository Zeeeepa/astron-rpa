@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================
REM AstronRPA - Automatic Update Script
REM Version: 1.0.0
REM Description: Updates AstronRPA to latest version
REM ============================================

color 0B
title AstronRPA - Update Manager

echo.
echo ═══════════════════════════════════════════════════════════
echo ║                                                         ║
echo ║           🔄 AstronRPA Update Manager 🔄                ║
echo ║                                                         ║
echo ║        Keep Your RPA Platform Up-to-Date               ║
echo ║                                                         ║
echo ═══════════════════════════════════════════════════════════
echo.

REM ============================================
REM 1. Initialize Variables
REM ============================================

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "PROJECT_ROOT=%SCRIPT_DIR%\.."
set "LOG_DIR=%SCRIPT_DIR%\logs"
set "LOG_FILE=%LOG_DIR%\update.log"
set "BACKUP_DIR=%SCRIPT_DIR%\backups\update_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "BACKUP_DIR=%BACKUP_DIR: =0%"

REM Create directories
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM Initialize log
echo [%date% %time%] Update started > "%LOG_FILE%"

REM Default settings
set "CHECK_ONLY=0"
set "SKIP_BACKUP=0"
set "FORCE_UPDATE=0"
set "UPDATE_BRANCH=main"

REM ============================================
REM 2. Parse Arguments
REM ============================================

:parse_args
if "%~1"=="" goto end_parse_args
if /i "%~1"=="--check" (
    set CHECK_ONLY=1
    shift
    goto parse_args
)
if /i "%~1"=="--skip-backup" (
    set SKIP_BACKUP=1
    shift
    goto parse_args
)
if /i "%~1"=="--force" (
    set FORCE_UPDATE=1
    shift
    goto parse_args
)
if /i "%~1"=="--branch" (
    set UPDATE_BRANCH=%~2
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-h" goto show_help
echo Unknown parameter: %~1
goto show_help

:show_help
echo.
echo Usage: UPDATE.bat [options]
echo.
echo Options:
echo   --check              Check for updates only (don't install)
echo   --skip-backup        Skip backup before update
echo   --force              Force update even if up-to-date
echo   --branch ^<name^>      Update from specific branch (default: main)
echo   --help, -h           Display this help message
echo.
echo Examples:
echo   UPDATE.bat --check
echo   UPDATE.bat --force
echo   UPDATE.bat --branch develop
echo   UPDATE.bat --skip-backup
echo.
exit /b 0

:end_parse_args

REM ============================================
REM 3. Check Git Installation
REM ============================================

echo [INFO] Checking Git installation...
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git is not installed or not in PATH
    echo [ERROR] Please install Git: https://git-scm.com/download/win
    echo [ERROR] Update failed >> "%LOG_FILE%"
    exit /b 1
)
echo [OK] Git is installed

REM ============================================
REM 4. Check Current Version
REM ============================================

cd /d "%PROJECT_ROOT%"

echo [INFO] Checking current version...
for /f "tokens=*" %%i in ('git rev-parse HEAD') do set CURRENT_VERSION=%%i
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD') do set CURRENT_BRANCH=%%i
echo [INFO] Current version: %CURRENT_VERSION:~0,8% on branch %CURRENT_BRANCH%
echo [%date% %time%] Current: %CURRENT_VERSION% (%CURRENT_BRANCH%) >> "%LOG_FILE%"

REM ============================================
REM 5. Fetch Latest Changes
REM ============================================

echo [INFO] Fetching latest changes from remote...
git fetch origin %UPDATE_BRANCH% >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to fetch from remote
    echo [ERROR] Please check your internet connection
    exit /b 1
)

REM ============================================
REM 6. Check for Updates
REM ============================================

echo [INFO] Checking for updates on branch %UPDATE_BRANCH%...
for /f "tokens=*" %%i in ('git rev-parse origin/%UPDATE_BRANCH%') do set LATEST_VERSION=%%i
echo [INFO] Latest version: %LATEST_VERSION:~0,8%
echo [%date% %time%] Latest: %LATEST_VERSION% >> "%LOG_FILE%"

if "%CURRENT_VERSION%"=="%LATEST_VERSION%" (
    if "%FORCE_UPDATE%"=="0" (
        echo.
        echo [OK] ✅ You are already on the latest version!
        echo [OK] Current: %CURRENT_VERSION:~0,8%
        echo [OK] No update needed.
        echo.
        if "%CHECK_ONLY%"=="1" exit /b 0
        
        set /p "FORCE_CHOICE=Do you want to rebuild anyway? (y/N): "
        if /i not "!FORCE_CHOICE!"=="y" (
            echo [INFO] Update cancelled by user
            exit /b 0
        )
        set FORCE_UPDATE=1
    )
)

REM Count commits behind
for /f %%i in ('git rev-list --count HEAD..origin/%UPDATE_BRANCH%') do set COMMITS_BEHIND=%%i
echo [INFO] You are %COMMITS_BEHIND% commit(s) behind

if "%CHECK_ONLY%"=="1" (
    echo.
    echo [INFO] 📊 Update Check Complete
    echo [INFO] Current:  %CURRENT_VERSION:~0,8% (%CURRENT_BRANCH%)
    echo [INFO] Latest:   %LATEST_VERSION:~0,8% (%UPDATE_BRANCH%)
    echo [INFO] Status:   %COMMITS_BEHIND% commit(s) behind
    echo.
    if "%COMMITS_BEHIND%"=="0" (
        echo [OK] ✅ No updates available
    ) else (
        echo [INFO] 🔄 Updates available - run UPDATE.bat to install
    )
    exit /b 0
)

REM ============================================
REM 7. Show Changes
REM ============================================

echo.
echo [INFO] 📝 Changes in this update:
echo ─────────────────────────────────────────────────────────
git log --oneline HEAD..origin/%UPDATE_BRANCH% --max-count=10
echo ─────────────────────────────────────────────────────────
echo.

REM ============================================
REM 8. Confirm Update
REM ============================================

if "%FORCE_UPDATE%"=="0" (
    set /p "CONFIRM=Proceed with update? (Y/n): "
    if /i "!CONFIRM!"=="n" (
        echo [INFO] Update cancelled by user
        exit /b 0
    )
)

echo.
echo [INFO] 🚀 Starting update process...
echo.

REM ============================================
REM 9. Stop Running Services
REM ============================================

echo [INFO] Stopping services...
if exist "%SCRIPT_DIR%\STOP.bat" (
    call "%SCRIPT_DIR%\STOP.bat" --silent
    if errorlevel 1 (
        echo [WARN] Failed to stop services gracefully
        set /p "CONTINUE=Continue anyway? (y/N): "
        if /i not "!CONTINUE!"=="y" (
            echo [ERROR] Update aborted
            exit /b 1
        )
    )
) else (
    echo [WARN] STOP.bat not found - services may still be running
)

REM ============================================
REM 10. Create Backup
REM ============================================

if "%SKIP_BACKUP%"=="0" (
    echo [INFO] Creating backup before update...
    echo [INFO] Backup location: %BACKUP_DIR%
    
    REM Backup critical directories
    echo [INFO] Backing up configuration files...
    if exist "%PROJECT_ROOT%\engine" xcopy /E /I /Q /Y "%PROJECT_ROOT%\engine\*.toml" "%BACKUP_DIR%\engine\" >> "%LOG_FILE%" 2>&1
    if exist "%PROJECT_ROOT%\backend" xcopy /E /I /Q /Y "%PROJECT_ROOT%\backend\*\.env*" "%BACKUP_DIR%\backend\" >> "%LOG_FILE%" 2>&1
    if exist "%PROJECT_ROOT%\frontend" xcopy /E /I /Q /Y "%PROJECT_ROOT%\frontend\*.json" "%BACKUP_DIR%\frontend\" >> "%LOG_FILE%" 2>&1
    
    REM Backup database (if MySQL is running)
    docker ps | findstr "mysql" >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Backing up MySQL database...
        docker exec astron-mysql mysqldump -u root -proot --all-databases > "%BACKUP_DIR%\mysql_backup.sql" 2>> "%LOG_FILE%"
        if not errorlevel 1 (
            echo [OK] Database backup complete
        ) else (
            echo [WARN] Database backup failed
        )
    )
    
    echo [OK] Backup created successfully
    echo [%date% %time%] Backup: %BACKUP_DIR% >> "%LOG_FILE%"
) else (
    echo [WARN] Skipping backup (--skip-backup flag used)
)

REM ============================================
REM 11. Pull Latest Changes
REM ============================================

echo [INFO] Pulling latest changes...
git pull origin %UPDATE_BRANCH% >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to pull changes from remote
    echo [ERROR] You may have local changes that conflict
    echo [ERROR] Run 'git status' to see conflicts
    goto rollback_prompt
)

echo [OK] Successfully pulled latest changes

REM Get new version
for /f "tokens=*" %%i in ('git rev-parse HEAD') do set NEW_VERSION=%%i
echo [INFO] Updated to version: %NEW_VERSION:~0,8%
echo [%date% %time%] Updated to: %NEW_VERSION% >> "%LOG_FILE%"

REM ============================================
REM 12. Update Dependencies
REM ============================================

echo.
echo [INFO] 📦 Updating dependencies...

REM Update Python dependencies
if exist "%PROJECT_ROOT%\engine\requirements.txt" (
    echo [INFO] Updating Python dependencies...
    "%PYTHON_EXE%" -m pip install --upgrade -r "%PROJECT_ROOT%\engine\requirements.txt" >> "%LOG_FILE%" 2>&1
    if errorlevel 1 (
        echo [WARN] Some Python dependencies failed to update
    ) else (
        echo [OK] Python dependencies updated
    )
)

REM Update Node dependencies
if exist "%PROJECT_ROOT%\frontend\package.json" (
    echo [INFO] Updating Node dependencies...
    cd /d "%PROJECT_ROOT%\frontend"
    call pnpm install >> "%LOG_FILE%" 2>&1
    if errorlevel 1 (
        echo [WARN] Some Node dependencies failed to update
    ) else (
        echo [OK] Node dependencies updated
    )
    cd /d "%PROJECT_ROOT%"
)

REM ============================================
REM 13. Rebuild Application
REM ============================================

echo.
echo [INFO] 🔨 Rebuilding application...

REM Check what changed
set "REBUILD_ENGINE=0"
set "REBUILD_FRONTEND=0"

git diff --name-only %CURRENT_VERSION% %NEW_VERSION% | findstr "engine/" >nul && set "REBUILD_ENGINE=1"
git diff --name-only %CURRENT_VERSION% %NEW_VERSION% | findstr "frontend/" >nul && set "REBUILD_FRONTEND=1"

if "%REBUILD_ENGINE%"=="1" (
    echo [INFO] Rebuilding RPA engine...
    if exist "%PROJECT_ROOT%\build.bat" (
        cd /d "%PROJECT_ROOT%"
        call build.bat --skip-frontend >> "%LOG_FILE%" 2>&1
        if errorlevel 1 (
            echo [ERROR] Engine rebuild failed
            goto rollback_prompt
        )
        echo [OK] Engine rebuilt successfully
    )
)

if "%REBUILD_FRONTEND%"=="1" (
    echo [INFO] Rebuilding frontend...
    if exist "%PROJECT_ROOT%\build.bat" (
        cd /d "%PROJECT_ROOT%"
        call build.bat --skip-engine >> "%LOG_FILE%" 2>&1
        if errorlevel 1 (
            echo [ERROR] Frontend rebuild failed
            goto rollback_prompt
        )
        echo [OK] Frontend rebuilt successfully
    )
)

if "%REBUILD_ENGINE%"=="0" if "%REBUILD_FRONTEND%"=="0" (
    echo [INFO] No rebuild necessary (no code changes detected)
)

REM ============================================
REM 14. Restart Services
REM ============================================

echo.
echo [INFO] Starting services...
if exist "%SCRIPT_DIR%\START.bat" (
    call "%SCRIPT_DIR%\START.bat" --no-browser >> "%LOG_FILE%" 2>&1
    if errorlevel 1 (
        echo [ERROR] Failed to start services
        echo [ERROR] Please manually run START.bat
    ) else (
        echo [OK] Services started successfully
    )
)

REM ============================================
REM 15. Verify Update
REM ============================================

echo.
echo [INFO] 🔍 Verifying update...

for /f "tokens=*" %%i in ('git rev-parse HEAD') do set VERIFY_VERSION=%%i
if "%VERIFY_VERSION%"=="%LATEST_VERSION%" (
    echo [OK] ✅ Update verification successful
) else (
    echo [WARN] ⚠️  Version mismatch detected
    echo [WARN] Expected: %LATEST_VERSION:~0,8%
    echo [WARN] Current:  %VERIFY_VERSION:~0,8%
)

REM ============================================
REM 16. Success Summary
REM ============================================

echo.
echo ═══════════════════════════════════════════════════════════
echo ║                                                         ║
echo ║           ✅ UPDATE COMPLETED SUCCESSFULLY ✅            ║
echo ║                                                         ║
echo ═══════════════════════════════════════════════════════════
echo.
echo [INFO] 📊 Update Summary:
echo   Old Version:  %CURRENT_VERSION:~0,8%
echo   New Version:  %NEW_VERSION:~0,8%
echo   Commits:      %COMMITS_BEHIND% applied
echo   Backup:       %BACKUP_DIR%
echo   Log:          %LOG_FILE%
echo.
echo [INFO] 🎉 AstronRPA is now up-to-date!
echo [INFO] You can now use the system normally.
echo.
echo [%date% %time%] Update completed successfully >> "%LOG_FILE%"

exit /b 0

REM ============================================
REM Rollback Handler
REM ============================================

:rollback_prompt
echo.
echo [ERROR] ❌ Update failed!
echo [ERROR] Would you like to rollback to the previous version?
echo.
set /p "ROLLBACK=Rollback to %CURRENT_VERSION:~0,8%? (Y/n): "
if /i not "!ROLLBACK!"=="n" (
    goto rollback
)
echo [INFO] Rollback cancelled - system may be in inconsistent state
echo [ERROR] Update failed - rollback declined >> "%LOG_FILE%"
exit /b 1

:rollback
echo [INFO] 🔄 Rolling back to previous version...
git reset --hard %CURRENT_VERSION% >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo [ERROR] Rollback failed!
    echo [ERROR] Please manually run: git reset --hard %CURRENT_VERSION%
    exit /b 1
)

echo [OK] Rolled back to %CURRENT_VERSION:~0,8%
echo [INFO] Restarting services...
if exist "%SCRIPT_DIR%\START.bat" (
    call "%SCRIPT_DIR%\START.bat" --no-browser
)

echo [INFO] Rollback complete
echo [%date% %time%] Rolled back to: %CURRENT_VERSION% >> "%LOG_FILE%"
exit /b 1

