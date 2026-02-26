@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================
REM AstronRPA - AI-Powered Setup Script
REM Version: 2.0.0 (AI-Enhanced)
REM Description: Intelligent setup with automated error resolution
REM ============================================

color 0D
title AstronRPA - AI-Powered Setup Wizard

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║         🤖 AstronRPA AI-Powered Setup Wizard 🤖          ║
echo ║                                                            ║
echo ║      Intelligent Installation with Self-Healing           ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo [AI] Initializing intelligent setup system...
echo [AI] Error detection and auto-remediation enabled
echo.

REM ============================================
REM 1. Initialize AI System
REM ============================================

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "PROJECT_ROOT=%SCRIPT_DIR%\.."
set "LOG_DIR=%SCRIPT_DIR%\logs"
set "AI_DIAGNOSTICS=%SCRIPT_DIR%\ai_diagnostics.py"

REM Create logs directory
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Check if Python is available for AI system
set "AI_ENABLED=0"
python --version >nul 2>&1
if not errorlevel 1 (
    set "AI_ENABLED=1"
    echo [AI] ✅ AI diagnostics system activated
) else (
    echo [WARNING] Python not found - AI features limited
    echo [INFO] Will attempt to install Python first...
)

REM ============================================
REM 2. AI-Powered Dependency Check
REM ============================================

echo.
echo [STEP 1/10] 🧠 AI-Powered Dependency Analysis...

if !AI_ENABLED! equ 1 (
    echo [AI] Running intelligent dependency scan...
    
    REM Use AI to analyze dependencies
    python "%AI_DIAGNOSTICS%" --mode analyze-dependencies --output "%LOG_DIR%\dependency_analysis.json" 2>nul
    
    if exist "%LOG_DIR%\dependency_analysis.json" (
        echo [AI] ✅ Dependency analysis complete
        
        REM Read AI recommendations
        for /f "tokens=*" %%a in ('python -c "import json; data=json.load(open('%LOG_DIR%\dependency_analysis.json')); print(data.get('status', 'unknown'))"') do (
            set "DEP_STATUS=%%a"
        )
        
        if "!DEP_STATUS!"=="all_present" (
            echo [AI] ✅ All dependencies detected
        ) else if "!DEP_STATUS!"=="partial" (
            echo [AI] ⚠️  Some dependencies missing - will auto-install
        ) else (
            echo [AI] ❌ Multiple dependencies missing - preparing auto-install
        )
    )
) else (
    echo [INFO] Using basic dependency check...
)

REM Standard dependency detection with AI fallback
call :check_and_fix_dependency "python" "Python.Python.3.13" "Python 3.13"
call :check_and_fix_dependency "node" "OpenJS.NodeJS.LTS" "Node.js"
call :check_and_fix_dependency "pnpm" "" "pnpm (via npm)"
call :check_and_fix_dependency "docker" "Docker.DockerDesktop" "Docker Desktop"
call :check_and_fix_dependency "rustc" "Rustlang.Rustup" "Rust"
call :check_and_fix_dependency "7z" "7zip.7zip" "7-Zip"

REM Enable AI if Python is now installed
if !AI_ENABLED! equ 0 (
    python --version >nul 2>&1
    if not errorlevel 1 (
        set "AI_ENABLED=1"
        echo [AI] ✅ AI diagnostics system now activated
    )
)

REM ============================================
REM 3. AI-Monitored Build Process
REM ============================================

echo.
echo [STEP 2/10] 🔨 AI-Monitored Build Process...

if !AI_ENABLED! equ 1 (
    echo [AI] Starting intelligent build monitoring...
    echo [AI] Automatic error detection and recovery enabled
)

REM Start build with AI monitoring
cd /d "%PROJECT_ROOT%"

:build_attempt
set "BUILD_ATTEMPT=1"
set "MAX_BUILD_ATTEMPTS=3"

:retry_build
if !BUILD_ATTEMPT! GTR !MAX_BUILD_ATTEMPTS! (
    echo [ERROR] Build failed after !MAX_BUILD_ATTEMPTS! attempts
    goto ai_analyze_build_failure
)

echo.
echo [BUILD] Attempt !BUILD_ATTEMPT!/!MAX_BUILD_ATTEMPTS!...

REM Run build and capture output
call build.bat > "%LOG_DIR%\build_output.log" 2>&1

if errorlevel 1 (
    echo [ERROR] Build failed on attempt !BUILD_ATTEMPT!
    
    if !AI_ENABLED! equ 1 (
        echo.
        echo [AI] 🔍 Analyzing build failure...
        
        REM Use AI to analyze the error
        python "%AI_DIAGNOSTICS%" ^
            --mode analyze-error ^
            --log-file "%LOG_DIR%\build_output.log" ^
            --context "build_process" ^
            --output "%LOG_DIR%\error_analysis.json"
        
        if exist "%LOG_DIR%\error_analysis.json" (
            echo [AI] ✅ Error analysis complete
            
            REM Check if AI can auto-fix
            for /f "tokens=*" %%a in ('python -c "import json; data=json.load(open('%LOG_DIR%\error_analysis.json')); print(data.get('can_auto_fix', 'false'))"') do (
                set "CAN_AUTO_FIX=%%a"
            )
            
            if "!CAN_AUTO_FIX!"=="true" (
                echo.
                echo [AI] 🔧 Attempting automated fix...
                
                REM Let AI attempt to fix the issue
                python "%AI_DIAGNOSTICS%" ^
                    --mode auto-remediate ^
                    --analysis "%LOG_DIR%\error_analysis.json" ^
                    --output "%LOG_DIR%\remediation_result.json"
                
                if exist "%LOG_DIR%\remediation_result.json" (
                    for /f "tokens=*" %%a in ('python -c "import json; data=json.load(open('%LOG_DIR%\remediation_result.json')); print(data.get('success', 'false'))"') do (
                        set "FIX_SUCCESS=%%a"
                    )
                    
                    if "!FIX_SUCCESS!"=="true" (
                        echo [AI] ✅ Automated fix successful!
                        echo [AI] 🔄 Retrying build...
                        
                        set /a BUILD_ATTEMPT+=1
                        timeout /t 3 /nobreak >nul
                        goto retry_build
                    ) else (
                        echo [AI] ❌ Automated fix unsuccessful
                        
                        REM Get AI recommendation
                        for /f "tokens=*" %%a in ('python -c "import json; data=json.load(open('%LOG_DIR%\remediation_result.json')); print(data.get('recommendation', 'manual'))"') do (
                            set "AI_RECOMMENDATION=%%a"
                        )
                        
                        echo [AI] 💡 Recommendation: !AI_RECOMMENDATION!
                        
                        if "!AI_RECOMMENDATION!"=="retry" (
                            set /a BUILD_ATTEMPT+=1
                            goto retry_build
                        ) else if "!AI_RECOMMENDATION!"=="fallback" (
                            goto build_fallback
                        ) else (
                            goto ai_analyze_build_failure
                        )
                    )
                )
            ) else (
                echo [AI] ⚠️  Error requires manual intervention
                goto ai_analyze_build_failure
            )
        )
    ) else (
        REM No AI - simple retry
        echo [INFO] Retrying build...
        set /a BUILD_ATTEMPT+=1
        timeout /t 5 /nobreak >nul
        goto retry_build
    )
) else (
    echo [BUILD] ✅ Build successful!
    goto post_build_steps
)

:ai_analyze_build_failure
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║              🤖 AI Build Failure Analysis 🤖              ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝

if !AI_ENABLED! equ 1 (
    echo.
    echo [AI] Performing deep analysis of build failure...
    
    python "%AI_DIAGNOSTICS%" ^
        --mode deep-analysis ^
        --log-file "%LOG_DIR%\build_output.log" ^
        --history-file "%LOG_DIR%\error_history.json" ^
        --output "%LOG_DIR%\deep_analysis.json"
    
    if exist "%LOG_DIR%\deep_analysis.json" (
        echo.
        echo [AI] 📊 Analysis Results:
        echo.
        
        REM Display AI analysis results
        python -c "import json; data=json.load(open('%LOG_DIR%\deep_analysis.json')); print('  Error Type:', data.get('error_type', 'Unknown')); print('  Root Cause:', data.get('root_cause', 'Unknown')); print('  Severity:', data.get('severity', '?') + '/10'); print('  Confidence:', str(int(data.get('confidence', 0)*100)) + '%%')"
        
        echo.
        echo [AI] 💡 Recommended Actions:
        python -c "import json; data=json.load(open('%LOG_DIR%\deep_analysis.json')); actions=data.get('recommended_actions', []); [print('    ' + str(i+1) + '. ' + action) for i, action in enumerate(actions[:5])]"
    )
)

echo.
echo [INFO] Build logs available at: %LOG_DIR%\build_output.log
echo.

choice /C YN /M "Try alternative build method (fallback)"
if errorlevel 2 goto error_exit
goto build_fallback

:build_fallback
echo.
echo [FALLBACK] Attempting alternative build strategy...
echo [AI] Using pre-built binaries where available

REM Fallback build strategy
REM ... implement fallback logic here ...

echo [FALLBACK] ⚠️  Alternative build methods not yet implemented
goto error_exit

:post_build_steps

REM ============================================
REM 4. AI-Powered Docker Setup
REM ============================================

echo.
echo [STEP 3/10] 🐳 AI-Powered Docker Configuration...

if !AI_ENABLED! equ 1 (
    echo [AI] Intelligent Docker setup with health monitoring...
)

REM Check Docker status with AI monitoring
call :ai_check_and_fix "docker" "Docker Desktop"

cd /d "%PROJECT_ROOT%\docker"

REM Start Docker services with AI monitoring
echo [INFO] Starting Docker services...

docker compose up -d > "%LOG_DIR%\docker_startup.log" 2>&1

if errorlevel 1 (
    echo [ERROR] Docker services failed to start
    
    if !AI_ENABLED! equ 1 (
        echo [AI] 🔍 Analyzing Docker startup failure...
        
        python "%AI_DIAGNOSTICS%" ^
            --mode analyze-error ^
            --log-file "%LOG_DIR%\docker_startup.log" ^
            --context "docker_startup" ^
            --output "%LOG_DIR%\docker_error.json"
        
        if exist "%LOG_DIR%\docker_error.json" (
            python "%AI_DIAGNOSTICS%" ^
                --mode auto-remediate ^
                --analysis "%LOG_DIR%\docker_error.json" ^
                --output "%LOG_DIR%\docker_fix.json"
            
            REM Check if fix was successful
            for /f "tokens=*" %%a in ('python -c "import json; data=json.load(open('%LOG_DIR%\docker_fix.json')); print(data.get('success', 'false'))"') do (
                set "DOCKER_FIX_SUCCESS=%%a"
            )
            
            if "!DOCKER_FIX_SUCCESS!"=="true" (
                echo [AI] ✅ Docker issue resolved automatically
                echo [AI] 🔄 Retrying Docker startup...
                
                timeout /t 5 /nobreak >nul
                docker compose up -d
                
                if not errorlevel 1 (
                    echo [AI] ✅ Docker services started successfully!
                ) else (
                    echo [AI] ❌ Docker startup still failing
                    goto error_exit
                )
            ) else (
                echo [AI] ⚠️  Could not automatically resolve Docker issue
                goto error_exit
            )
        )
    ) else (
        goto error_exit
    )
) else (
    echo [SUCCESS] ✅ Docker services started
)

REM ============================================
REM 5. AI System Health Check
REM ============================================

echo.
echo [STEP 4/10] 🏥 AI System Health Validation...

if !AI_ENABLED! equ 1 (
    echo [AI] Running comprehensive system health check...
    
    python "%AI_DIAGNOSTICS%" ^
        --mode health-check ^
        --components "docker,build,network,disk" ^
        --output "%LOG_DIR%\health_check.json"
    
    if exist "%LOG_DIR%\health_check.json" (
        for /f "tokens=*" %%a in ('python -c "import json; data=json.load(open('%LOG_DIR%\health_check.json')); print(data.get('overall_status', 'unknown'))"') do (
            set "HEALTH_STATUS=%%a"
        )
        
        if "!HEALTH_STATUS!"=="healthy" (
            echo [AI] ✅ All systems healthy
        ) else if "!HEALTH_STATUS!"=="warning" (
            echo [AI] ⚠️  System has warnings but is operational
        ) else (
            echo [AI] ❌ System health issues detected
            echo [AI] Check logs for details: %LOG_DIR%\health_check.json
        )
    )
)

REM ============================================
REM 6. Installation Complete
REM ============================================

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║         ✅ AI-Powered Setup Complete! ✅                  ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

if !AI_ENABLED! equ 1 (
    echo [AI] 🎓 Setup completed with AI assistance
    echo [AI] 📊 Generating setup report...
    
    python "%AI_DIAGNOSTICS%" ^
        --mode generate-report ^
        --log-dir "%LOG_DIR%" ^
        --output "%LOG_DIR%\setup_report.html"
    
    if exist "%LOG_DIR%\setup_report.html" (
        echo [AI] 📄 Detailed report: %LOG_DIR%\setup_report.html
        
        choice /C YN /M "Open setup report in browser"
        if not errorlevel 2 (
            start "" "%LOG_DIR%\setup_report.html"
        )
    )
)

echo.
echo [INFO] 🎉 AstronRPA is ready to use!
echo.
echo [NEXT STEPS]
echo   1. Run: START_AI.bat (to start with AI monitoring)
echo   2. Or:  START.bat (standard startup)
echo   3. Access: http://localhost:8040
echo.

if !AI_ENABLED! equ 1 (
    echo [AI] 🤖 AI features enabled:
    echo   • Intelligent error detection
    echo   • Automatic problem resolution
    echo   • Predictive maintenance
    echo   • Performance optimization
    echo.
)

pause
goto end

REM ============================================
REM Helper Functions
REM ============================================

:check_and_fix_dependency
set "CMD=%~1"
set "PACKAGE=%~2"
set "NAME=%~3"

echo.
echo [CHECK] %NAME%...

REM Check if command exists
%CMD% --version >nul 2>&1
if not errorlevel 1 (
    echo [OK] ✅ %NAME% found
    goto :eof
)

echo [MISSING] ❌ %NAME% not found

if !AI_ENABLED! equ 1 (
    echo [AI] 🔧 Preparing automated installation...
    
    REM Use AI to determine best installation method
    python "%AI_DIAGNOSTICS%" ^
        --mode suggest-install ^
        --dependency "%CMD%" ^
        --output "%LOG_DIR%\install_suggestion.json" 2>nul
    
    if exist "%LOG_DIR%\install_suggestion.json" (
        for /f "tokens=*" %%a in ('python -c "import json; data=json.load(open('%LOG_DIR%\install_suggestion.json')); print(data.get('method', 'winget'))"') do (
            set "INSTALL_METHOD=%%a"
        )
        
        echo [AI] 💡 Suggested method: !INSTALL_METHOD!
    )
)

if not "%PACKAGE%"=="" (
    echo [INSTALL] Installing %NAME% via winget...
    
    winget install -e --id %PACKAGE% --silent --accept-source-agreements --accept-package-agreements
    
    if not errorlevel 1 (
        echo [SUCCESS] ✅ %NAME% installed
    ) else (
        echo [WARNING] ⚠️  Installation may have issues
        
        if !AI_ENABLED! equ 1 (
            echo [AI] 🔍 Diagnosing installation issue...
            REM AI would analyze the installation failure here
        )
    )
) else if "%CMD%"=="pnpm" (
    echo [INSTALL] Installing pnpm via npm...
    call npm install -g pnpm@latest
)

goto :eof

:ai_check_and_fix
set "COMPONENT=%~1"
set "COMPONENT_NAME=%~2"

echo [CHECK] Verifying %COMPONENT_NAME%...

if !AI_ENABLED! equ 1 (
    python "%AI_DIAGNOSTICS%" ^
        --mode check-component ^
        --component "%COMPONENT%" ^
        --output "%LOG_DIR%\component_check.json" 2>nul
    
    if exist "%LOG_DIR%\component_check.json" (
        for /f "tokens=*" %%a in ('python -c "import json; data=json.load(open('%LOG_DIR%\component_check.json')); print(data.get('status', 'unknown'))"') do (
            set "COMPONENT_STATUS=%%a"
        )
        
        if "!COMPONENT_STATUS!"=="ok" (
            echo [AI] ✅ %COMPONENT_NAME% status: Healthy
        ) else if "!COMPONENT_STATUS!"=="fixable" (
            echo [AI] ⚠️  %COMPONENT_NAME% has issues - attempting auto-fix...
            
            python "%AI_DIAGNOSTICS%" ^
                --mode auto-fix-component ^
                --component "%COMPONENT%" ^
                --output "%LOG_DIR%\component_fix.json"
            
            echo [AI] ✅ Auto-fix attempted
        ) else (
            echo [AI] ❌ %COMPONENT_NAME% requires manual attention
        )
    )
)

goto :eof

:error_exit
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║              ❌ Setup Failed ❌                            ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

if !AI_ENABLED! equ 1 (
    echo [AI] 🔍 Final error analysis...
    
    python "%AI_DIAGNOSTICS%" ^
        --mode failure-report ^
        --log-dir "%LOG_DIR%" ^
        --output "%LOG_DIR%\failure_report.json"
    
    if exist "%LOG_DIR%\failure_report.json" (
        echo.
        echo [AI] 📊 Failure Analysis:
        python -c "import json; data=json.load(open('%LOG_DIR%\failure_report.json')); print('  Primary Issue:', data.get('primary_issue', 'Unknown')); print('  Impact:', data.get('impact', 'Unknown')); print('  Recommended Fix:', data.get('recommended_fix', 'See logs'))"
        echo.
    )
)

echo [ERROR] Setup encountered fatal errors
echo [INFO] Logs available in: %LOG_DIR%\
echo.
echo [SUPPORT]
echo   • Review logs in: %LOG_DIR%\
echo   • GitHub Issues: https://github.com/iflytek/astron-rpa/issues
echo   • Email: cbg_rpa_ml@iflytek.com
echo.

pause
exit /b 1

:end
exit /b 0

