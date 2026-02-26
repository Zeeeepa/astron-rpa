# 🚀 AstronRPA - Quick Start Actions Guide

This directory contains automated scripts to simplify the setup, start, and stop operations for AstronRPA on Windows.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Prerequisites](#-prerequisites)
- [Script Descriptions](#-script-descriptions)
- [Usage Guide](#-usage-guide)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)
- [Advanced Usage](#-advanced-usage)

---

## 🎯 Overview

The ACTIONS folder provides three main automation scripts:

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `SETUP.bat` | One-time system setup and build | First installation or after major updates |
| `START.bat` | Start all AstronRPA services | Daily use - start working |
| `STOP.bat` | Stop all AstronRPA services | End of workday or maintenance |

---

## ✅ Prerequisites

Before running any scripts, ensure you have:

### Required Software
- **Windows 10/11** (64-bit)
- **Administrator privileges** (for some operations)
- **Internet connection** (for downloads and Docker images)

### System Requirements
- **CPU**: 4+ cores recommended
- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 20GB+ available
- **Network**: Open ports 8000-8040, 3306, 6379, 9000-9001

---

## 📝 Script Descriptions

### 1. SETUP.bat - Complete System Setup

**Purpose**: Automates the entire installation and build process.

**What it does**:
```
✅ Checks for required software (Python, Node.js, Rust, etc.)
✅ Installs missing dependencies via winget
✅ Clones repository (if not already done)
✅ Builds RPA engine from source
✅ Builds frontend and desktop application
✅ Sets up Docker containers
✅ Configures initial settings
✅ Creates desktop shortcuts
```

**Duration**: 45-90 minutes (first run)

**Requirements**:
- Administrator privileges
- Internet connection
- 20GB free disk space

---

### 2. START.bat - Start All Services

**Purpose**: Launches all AstronRPA components in the correct order.

**What it does**:
```
✅ Verifies system configuration
✅ Starts Docker containers (server services)
✅ Launches RPA engine
✅ Opens desktop application
✅ Displays status dashboard
✅ Opens web UI in browser (optional)
```

**Duration**: 2-5 minutes

**Requirements**:
- Completed SETUP.bat at least once
- Docker Desktop running

---

### 3. STOP.bat - Stop All Services

**Purpose**: Gracefully shuts down all AstronRPA services.

**What it does**:
```
✅ Closes desktop application
✅ Stops RPA engine processes
✅ Stops Docker containers
✅ Saves current state
✅ Cleans up temporary files
✅ Displays shutdown summary
```

**Duration**: 30-60 seconds

---

## 🚀 Usage Guide

### First-Time Setup

```powershell
# 1. Navigate to AstronRPA directory
cd C:\Projects\astron-rpa

# 2. Run setup script (as Administrator)
# Right-click ACTIONS\SETUP.bat → "Run as administrator"
# Or from PowerShell:
Start-Process "ACTIONS\SETUP.bat" -Verb RunAs

# 3. Follow on-screen prompts
# - Accept defaults for most options
# - Provide Python installation path if prompted
# - Wait for completion (45-90 minutes)

# 4. Verify installation
# Script will display: "✅ Setup Complete! AstronRPA is ready."
```

### Daily Usage

**Starting AstronRPA:**
```powershell
# Method 1: Double-click
# Navigate to: C:\Projects\astron-rpa\ACTIONS\
# Double-click: START.bat

# Method 2: Command line
cd C:\Projects\astron-rpa
ACTIONS\START.bat

# Method 3: Desktop shortcut (created by SETUP.bat)
# Double-click: "Start AstronRPA" on desktop
```

**Stopping AstronRPA:**
```powershell
# Method 1: Double-click
# Navigate to: C:\Projects\astron-rpa\ACTIONS\
# Double-click: STOP.bat

# Method 2: Command line
cd C:\Projects\astron-rpa
ACTIONS\STOP.bat

# Method 3: Desktop shortcut
# Double-click: "Stop AstronRPA" on desktop
```

---

## ⚙️ Configuration

### Environment Variables

The scripts use these environment variables (auto-configured by SETUP.bat):

```powershell
# Python Configuration
ASTRONRPA_PYTHON_PATH="C:\Program Files\Python313\python.exe"

# Installation Paths
ASTRONRPA_HOME="C:\Projects\astron-rpa"
ASTRONRPA_INSTALL_DIR="C:\Program Files\astron-rpa"

# Server Configuration
ASTRONRPA_SERVER_IP="localhost"
ASTRONRPA_SERVER_PORT="8040"

# Engine Configuration
ASTRONRPA_ENGINE_PORT="32742"
ASTRONRPA_LOG_LEVEL="INFO"
```

### Customizing Settings

**Edit configuration file:**
```powershell
# 1. Open configuration file
notepad ACTIONS\config.ini

# 2. Modify settings as needed
[Server]
ServerIP=192.168.1.100
ServerPort=8040

[Engine]
EnginePort=32742
LogLevel=DEBUG
AutoStart=true

[Docker]
AutoStart=true
ComposeFile=docker\docker-compose.yml

# 3. Save and restart services
ACTIONS\STOP.bat
ACTIONS\START.bat
```

---

## 🔧 Troubleshooting

### Common Issues

#### ❌ Error: "SETUP.bat failed - Python not found"

**Solution:**
```powershell
# Install Python 3.13
winget install Python.Python.3.13

# Verify installation
python --version

# Re-run SETUP.bat
ACTIONS\SETUP.bat
```

---

#### ❌ Error: "START.bat - Docker not running"

**Solution:**
```powershell
# Start Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Wait 1 minute for Docker to initialize
Start-Sleep -Seconds 60

# Verify Docker is running
docker ps

# Re-run START.bat
ACTIONS\START.bat
```

---

#### ❌ Error: "Port already in use"

**Solution:**
```powershell
# Find process using port 8040
netstat -ano | findstr :8040

# Kill process (replace PID with actual process ID)
taskkill /PID <PID> /F

# Re-run START.bat
ACTIONS\START.bat
```

---

#### ❌ Error: "Build failed - Rust not found"

**Solution:**
```powershell
# Install Rust
winget install Rustlang.Rustup

# Restart terminal
exit

# Open new terminal and re-run SETUP.bat
ACTIONS\SETUP.bat
```

---

### Logs and Diagnostics

**View setup logs:**
```powershell
# Setup log location
notepad ACTIONS\logs\setup.log

# Or view in real-time
Get-Content ACTIONS\logs\setup.log -Tail 50 -Wait
```

**View runtime logs:**
```powershell
# Engine logs
notepad "C:\Program Files\astron-rpa\logs\engine.log"

# Docker logs
cd docker
docker compose logs -f

# Application logs
notepad "%APPDATA%\astron-rpa\logs\app.log"
```

---

## 🎓 Advanced Usage

### Silent Installation

```powershell
# Run SETUP.bat with no prompts (uses defaults)
ACTIONS\SETUP.bat --silent

# With custom Python path
ACTIONS\SETUP.bat --silent --python-path "D:\Python313\python.exe"
```

---

### Scheduled Startup

**Start AstronRPA automatically on Windows boot:**

```powershell
# Method 1: Task Scheduler
schtasks /create /tn "AstronRPA-Startup" /tr "C:\Projects\astron-rpa\ACTIONS\START.bat" /sc onlogon /rl highest

# Method 2: Add to Startup folder
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\AstronRPA.lnk")
$Shortcut.TargetPath = "C:\Projects\astron-rpa\ACTIONS\START.bat"
$Shortcut.Save()
```

---

### Development Mode

**Start services in development mode (with hot-reload):**

```powershell
# Start in dev mode
ACTIONS\START.bat --dev

# This will:
# - Start services with debug logging
# - Enable hot-reload for frontend
# - Skip building (use existing builds)
# - Open dev tools automatically
```

---

### Unattended Updates

**Update AstronRPA to latest version:**

```powershell
# Pull latest changes
cd C:\Projects\astron-rpa
git pull origin main

# Re-run setup (will detect existing installation)
ACTIONS\SETUP.bat --update

# Restart services
ACTIONS\STOP.bat
ACTIONS\START.bat
```

---

### Multiple Environments

**Run multiple AstronRPA instances:**

```powershell
# Create separate directories
mkdir C:\Projects\astron-rpa-dev
mkdir C:\Projects\astron-rpa-prod

# Clone to each directory
cd C:\Projects\astron-rpa-dev
git clone https://github.com/iflytek/astron-rpa.git .

cd C:\Projects\astron-rpa-prod
git clone https://github.com/iflytek/astron-rpa.git .

# Configure different ports in config.ini
# Dev: 8040, 32742
# Prod: 8050, 32752

# Start each instance
C:\Projects\astron-rpa-dev\ACTIONS\START.bat
C:\Projects\astron-rpa-prod\ACTIONS\START.bat
```

---

## 📊 Status Monitoring

### Check Service Status

```powershell
# Run status check
ACTIONS\STATUS.bat

# Output example:
# ┌─────────────────────────────────────┐
# │  AstronRPA Service Status           │
# ├─────────────────────────────────────┤
# │  Docker Services:                   │
# │  ✅ MySQL         - Running         │
# │  ✅ Redis         - Running         │
# │  ✅ MinIO         - Running         │
# │  ✅ AI Service    - Running         │
# │  ✅ API Service   - Running         │
# │                                     │
# │  Desktop App:      ✅ Running       │
# │  RPA Engine:       ✅ Running       │
# │                                     │
# │  Web UI:   http://localhost:8040   │
# │  Status:   🟢 All services online  │
# └─────────────────────────────────────┘
```

---

## 🔐 Security Notes

### Administrator Privileges

Some operations require admin rights:
- Installing system dependencies
- Modifying system PATH
- Creating Windows services
- Binding to privileged ports (< 1024)

**Run as admin when:**
- First-time setup (SETUP.bat)
- Installing updates
- Changing system configuration

---

### Firewall Configuration

**Allow required ports:**
```powershell
# Add firewall rules (run as administrator)
netsh advfirewall firewall add rule name="AstronRPA-Web" dir=in action=allow protocol=TCP localport=8040
netsh advfirewall firewall add rule name="AstronRPA-Engine" dir=in action=allow protocol=TCP localport=32742
netsh advfirewall firewall add rule name="AstronRPA-WS" dir=in action=allow protocol=TCP localport=32743
```

---

## 📞 Support

### Getting Help

**If you encounter issues:**

1. **Check logs** (see Logs and Diagnostics section above)
2. **Review troubleshooting** section in this document
3. **Search existing issues**: https://github.com/iflytek/astron-rpa/issues
4. **Ask community**: https://github.com/iflytek/astron-rpa/discussions
5. **Contact support**: cbg_rpa_ml@iflytek.com

### Reporting Bugs

**When reporting issues, include:**
- Output from `ACTIONS\STATUS.bat`
- Content of `ACTIONS\logs\setup.log`
- Content of `ACTIONS\logs\start.log`
- Windows version (`winver`)
- Installed software versions

---

## 📝 Change Log

### Version 1.0.0 (Initial Release)
- ✅ SETUP.bat - Automated installation
- ✅ START.bat - Service startup
- ✅ STOP.bat - Service shutdown
- ✅ STATUS.bat - Service monitoring
- ✅ config.ini - Configuration management
- ✅ Comprehensive error handling
- ✅ Logging and diagnostics

---

## 📄 License

This automation toolkit is provided under the same license as AstronRPA.
See the main LICENSE file in the repository root.

---

## 🙏 Credits

**Developed by**: iFlytek AI Research Team  
**Automation Scripts**: Community Contributors  
**Documentation**: AstronRPA Documentation Team  

---

**Made with ❤️ for the AstronRPA Community**

For more information, visit: https://github.com/iflytek/astron-rpa

