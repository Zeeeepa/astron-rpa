# ⚡ AstronRPA - 5-Minute Quick Start Guide

Get AstronRPA up and running in **5 minutes** with this streamlined guide!

---

## 🎯 Prerequisites Check (30 seconds)

Before starting, ensure you have:

- ✅ **Windows 10/11** (64-bit)
- ✅ **Administrator privileges**
- ✅ **20GB+ free disk space**
- ✅ **8GB+ RAM**
- ✅ **Internet connection**

---

## 🚀 Installation (2-3 minutes)

### **Step 1: Download & Extract**
```
1. Download AstronRPA from GitHub
2. Extract to C:\AstronRPA (or your preferred location)
3. Open the ACTIONS folder
```

### **Step 2: Run Setup**
```batch
# Right-click SETUP.bat → Run as Administrator
SETUP.bat
```

**What happens:**
- ✅ Checks system requirements
- ✅ Installs missing dependencies (Python, Node.js, Docker, etc.)
- ✅ Builds RPA engine
- ✅ Builds desktop application
- ✅ Starts Docker services
- ✅ Creates desktop shortcut

**Time:** 45-90 minutes (mostly automated)

⚠️ **First-time setup takes longer** - subsequent operations are much faster!

---

## 🎮 Daily Usage (30 seconds)

### **Start AstronRPA**
```batch
# Double-click or run:
START.bat
```

**Opens automatically:**
- 🌐 Web UI: http://localhost:8080
- 🖥️ Desktop application

---

### **Check Status**
```batch
STATUS.bat
```

**Shows:**
- ✅ Running services (green)
- ⚠️ Issues (yellow)
- ❌ Stopped services (red)

---

### **Stop AstronRPA**
```batch
STOP.bat
```

**Gracefully stops:**
- All Docker services
- RPA engine
- Desktop application

---

## 🔧 Common Commands

### **Check for Updates**
```batch
UPDATE.bat --check
```

### **Update to Latest Version**
```batch
UPDATE.bat
```

### **View Logs**
```batch
# Coming soon
LOGS.bat
```

### **System Health Check**
```batch
# Coming soon
DOCTOR.bat
```

---

## 🎨 Your First Automation (2 minutes)

### **1. Open the Desktop App**
- Look for "AstronRPA" on your desktop
- Or open http://localhost:8080 in your browser

### **2. Create a Simple Bot**
```
1. Click "New Project"
2. Choose "Browser Automation" template
3. Add action: "Open URL" → https://example.com
4. Add action: "Take Screenshot"
5. Click "Run"
```

### **3. View Results**
- Screenshots saved to: `output/screenshots/`
- Logs visible in the UI

---

## 📊 System Architecture

```
AstronRPA/
├── Docker Services (Backend)
│   ├── MySQL (Database) - Port 3306
│   ├── Redis (Cache) - Port 6379
│   ├── MinIO (Storage) - Port 9000/9001
│   ├── AI Service - Port 6688
│   └── Backend APIs - Ports 8000-8003
│
├── RPA Engine (Python)
│   ├── Browser Bridge
│   ├── Task Executor
│   ├── Scheduler
│   └── Trigger Service
│
└── Desktop App (Tauri + Vue)
    └── Web UI on Port 8080
```

---

## 🆘 Quick Troubleshooting

### **Setup fails?**
```batch
# Check system requirements
VALIDATE.bat

# Run with AI diagnostics
SETUP_AI.bat
```

### **Services won't start?**
```batch
# Check what's running
STATUS.bat

# Try restarting
STOP.bat
START.bat
```

### **Port conflicts?**
```
Error: Port 3306 already in use
Solution: Stop other MySQL instances or configure different ports
```

### **Docker issues?**
```
1. Ensure Docker Desktop is running
2. Check: docker ps
3. Restart Docker Desktop if needed
```

---

## 🔗 Important URLs

After starting AstronRPA:

| Service | URL | Purpose |
|---------|-----|---------|
| **Web UI** | http://localhost:8080 | Main interface |
| **API Gateway** | http://localhost:8000 | REST API |
| **MinIO Console** | http://localhost:9001 | Object storage |
| **AI Service** | http://localhost:6688 | AI capabilities |

---

## 📁 Important Directories

```
AstronRPA/
├── ACTIONS/              # Management scripts
├── engine/               # Python RPA engine
├── frontend/             # Web UI source
├── backend/              # Backend services
├── build/                # Compiled binaries
├── output/               # Automation results
└── logs/                 # System logs
```

---

## 🎓 Next Steps

### **Learn More**
- 📖 [Full Documentation](INSTRUCTIONS.md) - Complete guide
- 🔧 [Deployment Guide](DEPLOYMENT_GUIDE.md) - Production setup
- 🐛 [Troubleshooting](INSTRUCTIONS.md#troubleshooting) - Common issues

### **Explore Features**
- 🌐 Browser automation
- 🖱️ Desktop automation
- 📊 Data processing
- 🤖 AI integration
- ⏰ Task scheduling
- 🔔 Event triggers

### **Join Community**
- 💬 GitHub Discussions
- 🐛 Report Issues
- 🌟 Star the Project

---

## 💡 Pro Tips

### **Speed Up Future Starts**
```batch
# Leave Docker running in background
# START.bat will be instant!
```

### **Scheduled Startup**
```batch
# Windows Task Scheduler
# Schedule START.bat to run at login
```

### **Development Mode**
```batch
START.bat --dev
# Enables hot reload and debug logging
```

### **Update Regularly**
```batch
# Check weekly for updates
UPDATE.bat --check

# Or enable auto-check on startup
```

---

## ⚠️ Important Notes

### **System Resources**
- First build: Uses 4+ CPU cores, 6GB+ RAM
- Normal operation: ~2GB RAM, minimal CPU
- Docker containers: ~4GB disk space

### **Firewall**
- Allow Docker Desktop
- Allow ports: 3306, 6379, 8000-8003, 9000-9001

### **Antivirus**
- May flag downloaded binaries
- Add AstronRPA folder to exclusions if needed

### **Network**
- Internet required for initial setup
- Offline operation supported after setup
- Cloud features require internet

---

## 🎉 You're Ready!

You've successfully:
- ✅ Installed AstronRPA
- ✅ Started all services
- ✅ Created your first automation
- ✅ Know the basics

**Time to explore!** 🚀

---

## 📞 Need Help?

### **Check Logs**
```batch
cd ACTIONS\logs
dir /od
# View latest log file
```

### **Run Diagnostics**
```batch
DOCTOR.bat --full
# Coming soon - full system health check
```

### **Get Support**
- 📖 Read [INSTRUCTIONS.md](INSTRUCTIONS.md)
- 🐛 Check [GitHub Issues](https://github.com/Zeeeepa/astron-rpa/issues)
- 💬 Ask in Discussions

---

## 🔄 Uninstall (if needed)

```batch
# Complete removal
UNINSTALL.bat

# Keep user data
UNINSTALL.bat --keep-data
```

---

## 📊 Quick Reference Card

```
┌─────────────────────────────────────────────┐
│          AstronRPA Quick Commands           │
├─────────────────────────────────────────────┤
│  SETUP.bat         │ First-time install     │
│  START.bat         │ Start all services     │
│  STOP.bat          │ Stop all services      │
│  STATUS.bat        │ Check service status   │
│  UPDATE.bat        │ Update to latest       │
│  UPDATE.bat --check│ Check for updates      │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│            Important URLs                    │
├─────────────────────────────────────────────┤
│  http://localhost:8080    │ Main Web UI     │
│  http://localhost:8000    │ API Gateway     │
│  http://localhost:9001    │ MinIO Console   │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│           System Requirements                │
├─────────────────────────────────────────────┤
│  OS:    Windows 10/11 64-bit                │
│  CPU:   4+ cores recommended                │
│  RAM:   8GB minimum, 16GB recommended       │
│  Disk:  20GB free space                     │
└─────────────────────────────────────────────┘
```

---

**🎯 Goal: Get you productive in 5 minutes!**

**⏱️ Actual time: ~5 minutes reading + 45-90 minutes automated setup**

**Ready to automate? Let's go!** 🚀

