#!/usr/bin/env python3
"""
AstronRPA Runtime Manager - Consolidated Service Management
Consolidates: START.bat, STOP.bat, STATUS.bat, UPDATE.bat, ai_diagnostics.py

Usage:
    python start.py              # Start all services
    python start.py stop         # Stop all services
    python start.py status       # Check status
    python start.py restart      # Restart services
    python start.py update       # Update AstronRPA
    python start.py doctor       # Run diagnostics
"""

import os
import sys
import subprocess
import time
import json
from pathlib import Path
from typing import Dict, List, Optional
import platform

# Color codes
class C:
    H='[95m';B='[94m';G='[92m';W='[93m';F='[91m';E='[0m';BO='[1m'

def ph(m): print(f"\n{C.H}{C.BO}{'='*60}{C.E}\n{C.H}{C.BO}{m:^60}{C.E}\n{C.H}{C.BO}{'='*60}{C.E}\n")
def ps(m): print(f"{C.G}✓ {m}{C.E}")
def pe(m): print(f"{C.F}✗ {m}{C.E}")
def pw(m): print(f"{C.W}⚠ {m}{C.E}")
def pi(m): print(f"{C.B}ℹ {m}{C.E}")

class ServiceManager:
    """Manages all AstronRPA services"""
    
    def __init__(self):
        self.root = Path(__file__).parent
        self.services = {
            'docker': {'type': 'docker', 'containers': ['mysql', 'redis', 'minio', 'ai-service']},
            'engine': {'type': 'process', 'cmd': ['python', 'engine/main.py']},
            'desktop': {'type': 'process', 'cmd': ['npm', 'start'], 'cwd': 'frontend'}
        }
    
    def check_process(self, name: str) -> bool:
        """Check if process is running"""
        try:
            if platform.system() == 'Windows':
                r = subprocess.run(['tasklist'], capture_output=True, text=True)
                return name.lower() in r.stdout.lower()
            else:
                r = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
                return name in r.stdout
        except: return False
    
    def check_docker_container(self, name: str) -> bool:
        """Check if Docker container is running"""
        try:
            r = subprocess.run(['docker', 'ps', '--filter', f'name={name}'],
                             capture_output=True, text=True, timeout=5)
            return name in r.stdout
        except: return False
    
    def start_docker(self) -> bool:
        """Start Docker services"""
        pi("Starting Docker services...")
        try:
            compose = self.root / 'docker-compose.yml'
            if not compose.exists():
                pw("docker-compose.yml not found")
                return False
            subprocess.run(['docker-compose', 'up', '-d'], cwd=self.root, check=True, timeout=120)
            time.sleep(5)  # Wait for services
            ps("Docker services started")
            return True
        except Exception as e:
            pe(f"Failed to start Docker: {e}")
            return False
    
    def stop_docker(self) -> bool:
        """Stop Docker services"""
        pi("Stopping Docker services...")
        try:
            subprocess.run(['docker-compose', 'down'], cwd=self.root, timeout=60)
            ps("Docker services stopped")
            return True
        except Exception as e:
            pe(f"Failed to stop Docker: {e}")
            return False
    
    def start_engine(self) -> bool:
        """Start RPA engine"""
        pi("Starting RPA engine...")
        try:
            engine_dir = self.root / 'engine'
            if not engine_dir.exists():
                pe("Engine directory not found")
                return False
            subprocess.Popen([sys.executable, 'main.py'], cwd=engine_dir)
            time.sleep(2)
            ps("RPA engine started")
            return True
        except Exception as e:
            pe(f"Failed to start engine: {e}")
            return False
    
    def start_desktop(self) -> bool:
        """Start desktop application"""
        pi("Starting desktop app...")
        try:
            frontend_dir = self.root / 'frontend'
            if not frontend_dir.exists():
                pe("Frontend directory not found")
                return False
            subprocess.Popen(['npm', 'start'], cwd=frontend_dir)
            time.sleep(3)
            ps("Desktop app started")
            return True
        except Exception as e:
            pe(f"Failed to start desktop: {e}")
            return False
    
    def start_all(self) -> bool:
        """Start all services"""
        ph("Starting AstronRPA")
        return all([self.start_docker(), self.start_engine(), self.start_desktop()])
    
    def stop_all(self) -> bool:
        """Stop all services"""
        ph("Stopping AstronRPA")
        self.stop_docker()
        # Kill processes
        try:
            if platform.system() == 'Windows':
                subprocess.run(['taskkill', '/F', '/IM', 'python.exe'], capture_output=True)
                subprocess.run(['taskkill', '/F', '/IM', 'node.exe'], capture_output=True)
            else:
                subprocess.run(['pkill', '-f', 'engine/main.py'])
                subprocess.run(['pkill', '-f', 'npm.*start'])
            ps("All services stopped")
            return True
        except Exception as e:
            pe(f"Error stopping services: {e}")
            return False
    
    def status(self) -> Dict:
        """Get status of all services"""
        ph("Service Status")
        status = {}
        
        # Check Docker containers
        for container in ['mysql', 'redis', 'minio']:
            running = self.check_docker_container(container)
            status[container] = running
            if running: ps(f"{container}: Running")
            else: pe(f"{container}: Stopped")
        
        # Check processes
        engine_running = self.check_process('main.py')
        status['engine'] = engine_running
        if engine_running: ps("Engine: Running")
        else: pe("Engine: Stopped")
        
        desktop_running = self.check_process('npm')
        status['desktop'] = desktop_running
        if desktop_running: ps("Desktop: Running")
        else: pe("Desktop: Stopped")
        
        return status

class UpdateManager:
    """Handles updates"""
    
    def __init__(self):
        self.root = Path(__file__).parent
    
    def check_updates(self) -> bool:
        """Check for available updates"""
        ph("Checking for Updates")
        try:
            subprocess.run(['git', 'fetch', 'origin'], cwd=self.root, check=True)
            r = subprocess.run(['git', 'log', 'HEAD..origin/main', '--oneline'],
                             cwd=self.root, capture_output=True, text=True)
            if r.stdout.strip():
                pi(f"Updates available:\n{r.stdout}")
                return True
            ps("Already up to date")
            return False
        except Exception as e:
            pe(f"Failed to check updates: {e}")
            return False
    
    def update(self) -> bool:
        """Update to latest version"""
        ph("Updating AstronRPA")
        try:
            subprocess.run(['git', 'pull', 'origin', 'main'], cwd=self.root, check=True)
            ps("Update successful")
            pi("Please restart AstronRPA")
            return True
        except Exception as e:
            pe(f"Update failed: {e}")
            return False

class DiagnosticsManager:
    """Run system diagnostics"""
    
    def run(self):
        ph("System Diagnostics")
        
        # Check Python
        pi(f"Python: {sys.version.split()[0]}")
        
        # Check disk space
        import shutil
        usage = shutil.disk_usage("/")
        free_gb = usage.free / (1024**3)
        if free_gb < 5: pw(f"Low disk space: {free_gb:.1f}GB free")
        else: ps(f"Disk space: {free_gb:.1f}GB free")
        
        # Check ports
        ports = [3306, 6379, 8000, 8080, 9000]
        import socket
        for port in ports:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                in_use = s.connect_ex(('localhost', port)) == 0
                if in_use: pw(f"Port {port}: In use")
                else: ps(f"Port {port}: Available")

def main():
    import argparse
    parser = argparse.ArgumentParser(description='AstronRPA Runtime')
    parser.add_argument('command', nargs='?', default='start',
                       choices=['start', 'stop', 'status', 'restart', 'update', 'doctor'])
    args = parser.parse_args()
    
    sm = ServiceManager()
    
    if args.command == 'start': return 0 if sm.start_all() else 1
    elif args.command == 'stop': return 0 if sm.stop_all() else 1
    elif args.command == 'status': sm.status(); return 0
    elif args.command == 'restart': sm.stop_all(); time.sleep(2); return 0 if sm.start_all() else 1
    elif args.command == 'update': um = UpdateManager(); um.check_updates() and um.update(); return 0
    elif args.command == 'doctor': DiagnosticsManager().run(); return 0

if __name__ == '__main__': sys.exit(main())
