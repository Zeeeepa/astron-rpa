#!/usr/bin/env python3
"""
AstronRPA Setup - Consolidated Installation & Configuration
Consolidates: SETUP.bat, SETUP_AI.bat, analyze_dependencies.py

Usage:
    python setup.py              # Full setup
    python setup.py --ai         # AI-assisted setup
    python setup.py --check      # Check dependencies only
    python setup.py --repair     # Repair installation
"""

import os
import sys
import platform
import subprocess
import json
import shutil
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# ANSI color codes
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_header(msg):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{msg:^60}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}\n")

def print_success(msg):
    print(f"{Colors.OKGREEN}✓ {msg}{Colors.ENDC}")

def print_error(msg):
    print(f"{Colors.FAIL}✗ {msg}{Colors.ENDC}")

def print_warning(msg):
    print(f"{Colors.WARNING}⚠ {msg}{Colors.ENDC}")

def print_info(msg):
    print(f"{Colors.OKCYAN}ℹ {msg}{Colors.ENDC}")

class DependencyAnalyzer:
    """Analyzes and installs system dependencies"""
    
    def __init__(self):
        self.is_windows = platform.system() == 'Windows'
        self.required_tools = {
            'git': {'version': '2.0', 'installer': 'https://git-scm.com/downloads'},
            'python': {'version': '3.8', 'installer': 'https://python.org/downloads'},
            'node': {'version': '16.0', 'installer': 'https://nodejs.org'},
            'docker': {'version': '20.0', 'installer': 'https://docker.com/get-started'},
        }
    
    def check_tool(self, tool: str) -> Tuple[bool, str]:
        """Check if a tool is installed and get version"""
        try:
            if tool == 'python':
                result = subprocess.run([sys.executable, '--version'], 
                                      capture_output=True, text=True, timeout=5)
            elif tool == 'node':
                result = subprocess.run(['node', '--version'],
                                      capture_output=True, text=True, timeout=5)
            else:
                result = subprocess.run([tool, '--version'],
                                      capture_output=True, text=True, timeout=5)
            
            if result.returncode == 0:
                version = result.stdout.strip() + result.stderr.strip()
                return True, version
        except (FileNotFoundError, subprocess.TimeoutExpired):
            pass
        return False, ""
    
    def analyze_all(self) -> Dict:
        """Analyze all dependencies"""
        results = {}
        for tool, info in self.required_tools.items():
            found, version = self.check_tool(tool)
            results[tool] = {
                'found': found,
                'version': version,
                'required': info['version'],
                'installer': info['installer']
            }
        return results

class SetupManager:
    """Main setup orchestrator"""
    
    def __init__(self, ai_mode=False):
        self.ai_mode = ai_mode
        self.root_dir = Path(__file__).parent
        self.log_dir = self.root_dir / 'ACTIONS' / 'logs'
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.analyzer = DependencyAnalyzer()
    
    def check_admin(self) -> bool:
        """Check if running with admin privileges"""
        try:
            if platform.system() == 'Windows':
                import ctypes
                return ctypes.windll.shell32.IsUserAnAdmin() != 0
            else:
                return os.geteuid() == 0
        except:
            return False
    
    def install_dependencies(self) -> bool:
        """Install missing dependencies"""
        print_header("Installing Dependencies")
        
        deps = self.analyzer.analyze_all()
        missing = [k for k, v in deps.items() if not v['found']]
        
        if not missing:
            print_success("All dependencies already installed")
            return True
        
        print_warning(f"Missing dependencies: {', '.join(missing)}")
        
        for tool in missing:
            print_info(f"Installing {tool}...")
            info = deps[tool]
            
            if platform.system() == 'Windows':
                print_info(f"Download from: {info['installer']}")
                # On Windows, guide user to download
                print_warning(f"Please install {tool} manually and re-run setup")
            else:
                # On Linux/Mac, try package managers
                if shutil.which('apt-get'):
                    subprocess.run(['sudo', 'apt-get', 'install', '-y', tool])
                elif shutil.which('brew'):
                    subprocess.run(['brew', 'install', tool])
        
        return len(missing) == 0
    
    def build_engine(self) -> bool:
        """Build RPA engine"""
        print_header("Building RPA Engine")
        
        engine_dir = self.root_dir / 'engine'
        if not engine_dir.exists():
            print_error("Engine directory not found")
            return False
        
        try:
            # Install Python dependencies
            print_info("Installing Python packages...")
            subprocess.run([sys.executable, '-m', 'pip', 'install', '-r',
                          str(engine_dir / 'requirements.txt')],
                         check=True)
            
            print_success("Engine built successfully")
            return True
        except subprocess.CalledProcessError as e:
            print_error(f"Engine build failed: {e}")
            return False
    
    def build_frontend(self) -> bool:
        """Build desktop application"""
        print_header("Building Desktop Application")
        
        frontend_dir = self.root_dir / 'frontend'
        if not frontend_dir.exists():
            print_error("Frontend directory not found")
            return False
        
        try:
            # Install npm dependencies
            print_info("Installing npm packages...")
            subprocess.run(['npm', 'install'], cwd=frontend_dir, check=True)
            
            # Build application
            print_info("Building application...")
            subprocess.run(['npm', 'run', 'build'], cwd=frontend_dir, check=True)
            
            print_success("Desktop app built successfully")
            return True
        except subprocess.CalledProcessError as e:
            print_error(f"Frontend build failed: {e}")
            return False
    
    def setup_docker(self) -> bool:
        """Setup Docker services"""
        print_header("Setting Up Docker Services")
        
        try:
            # Check if Docker is running
            result = subprocess.run(['docker', 'ps'], 
                                  capture_output=True, timeout=5)
            
            if result.returncode != 0:
                print_error("Docker is not running")
                print_info("Please start Docker Desktop and try again")
                return False
            
            # Start Docker Compose services
            print_info("Starting Docker services...")
            compose_file = self.root_dir / 'docker-compose.yml'
            if compose_file.exists():
                subprocess.run(['docker-compose', 'up', '-d'],
                             cwd=self.root_dir, check=True)
                print_success("Docker services started")
            else:
                print_warning("docker-compose.yml not found")
            
            return True
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            print_error(f"Docker setup failed: {e}")
            return False
    
    def run_full_setup(self) -> bool:
        """Run complete setup process"""
        print_header("AstronRPA Setup")
        print_info(f"Platform: {platform.system()}")
        print_info(f"Python: {sys.version.split()[0]}")
        print_info(f"AI Mode: {'Enabled' if self.ai_mode else 'Disabled'}")
        
        # Check admin
        if not self.check_admin():
            print_warning("Not running as administrator")
            print_info("Some operations may require elevated privileges")
        
        steps = [
            ("Checking dependencies", self.install_dependencies),
            ("Building RPA engine", self.build_engine),
            ("Building desktop app", self.build_frontend),
            ("Setting up Docker", self.setup_docker),
        ]
        
        for step_name, step_func in steps:
            print()
            if not step_func():
                print_error(f"Setup failed at: {step_name}")
                return False
        
        print_header("Setup Complete!")
        print_success("AstronRPA is ready to use")
        print_info("Run 'python start.py' to start the application")
        return True

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='AstronRPA Setup')
    parser.add_argument('--ai', action='store_true', 
                       help='Enable AI-assisted setup')
    parser.add_argument('--check', action='store_true',
                       help='Check dependencies only')
    parser.add_argument('--repair', action='store_true',
                       help='Repair installation')
    
    args = parser.parse_args()
    
    manager = SetupManager(ai_mode=args.ai)
    
    if args.check:
        print_header("Dependency Check")
        deps = manager.analyzer.analyze_all()
        for tool, info in deps.items():
            if info['found']:
                print_success(f"{tool}: {info['version']}")
            else:
                print_error(f"{tool}: Not found")
        return 0
    
    if args.repair:
        print_header("Repair Installation")
        # Re-run build steps
        manager.build_engine()
        manager.build_frontend()
        return 0
    
    # Full setup
    success = manager.run_full_setup()
    return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())
