# 🎬 AstronRPA Actions Scripts

Quick reference for automated management scripts.

---

## 📜 Available Scripts

| Script | Purpose | Duration |
|--------|---------|----------|
| **SETUP.bat** | Complete installation & build | 45-90 min |
| **START.bat** | Start all services | 2-5 min |
| **STOP.bat** | Stop all services | 30-60 sec |
| **STATUS.bat** | Check service status | Instant |

---

## 🚀 Quick Start

### First Time Setup
```batch
# Run as Administrator
SETUP.bat
```

### Daily Usage
```batch
# Start AstronRPA
START.bat

# Check status
STATUS.bat

# Stop AstronRPA
STOP.bat
```

---

## 📖 Detailed Documentation

See **[INSTRUCTIONS.md](INSTRUCTIONS.md)** for:
- Complete usage guide
- Configuration options
- Troubleshooting steps
- Advanced features
- Best practices

---

## 🔧 Common Commands

### Setup
```batch
# Silent installation (no prompts)
SETUP.bat --silent

# Custom Python path
SETUP.bat --python-path "D:\Python313\python.exe"

# Skip dependency installation
SETUP.bat --skip-deps

# Update existing installation
SETUP.bat --update
```

### Start
```batch
# Start with no browser
START.bat --no-browser

# Development mode
START.bat --dev

# Quick start (skip checks)
START.bat --quick
```

### Stop
```batch
# Force stop all services
STOP.bat --force

# Keep Docker running
STOP.bat --keep-docker

# Silent stop (no prompts)
STOP.bat --silent
```

---

## 📊 Service Status

Run `STATUS.bat` to see:
- Docker services status
- Desktop application status
- RPA engine status
- Network ports status
- System resources usage
- Access points

---

## 🆘 Troubleshooting

### Common Issues

**Services won't start?**
```batch
# Check Docker
docker ps

# View logs
cd docker
docker compose logs -f

# Restart services
STOP.bat --force
START.bat
```

**Build failed?**
```batch
# Check logs
type ACTIONS\logs\setup.log

# Re-run with clean environment
SETUP.bat --skip-deps
```

**Application won't close?**
```batch
# Force stop everything
STOP.bat --force
```

---

## 📁 Directory Structure

```
ACTIONS/
├── INSTRUCTIONS.md      # Detailed documentation
├── README.md           # This file
├── SETUP.bat          # Installation script
├── START.bat          # Startup script
├── STOP.bat           # Shutdown script
├── STATUS.bat         # Status checker
└── logs/              # Script logs
    ├── setup.log
    ├── start.log
    └── stop.log
```

---

## 🔗 Links

- **Documentation**: [../README.md](../README.md)
- **Build Guide**: [../BUILD_GUIDE.md](../BUILD_GUIDE.md)
- **Docker Setup**: [../docker/QUICK_START.md](../docker/QUICK_START.md)
- **GitHub Issues**: https://github.com/iflytek/astron-rpa/issues
- **Support Email**: cbg_rpa_ml@iflytek.com

---

## 📝 Version History

- **v1.0.0** (2024) - Initial release
  - SETUP.bat - Automated installation
  - START.bat - Service startup
  - STOP.bat - Service shutdown
  - STATUS.bat - Status monitoring

---

**Made with ❤️ for the AstronRPA Community**

