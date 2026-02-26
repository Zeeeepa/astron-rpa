#!/usr/bin/env python3
"""
AstronRPA Setup - Consolidated Installation & Configuration
Consolidates: SETUP.bat, SETUP_AI.bat, analyze_dependencies.py

Usage:
    python setup.py              # Full interactive setup
    python setup.py --ai         # AI-assisted setup
    python setup.py --check      # Check dependencies only
    python setup.py --repair     # Repair installation
    python setup.py --config     # Configuration only
"""

import os
import sys
import platform
import subprocess
import json
import shutil
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import re

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

def print_required(msg):
    print(f"{Colors.FAIL}{Colors.BOLD}[REQUIRED]{Colors.ENDC} {msg}")

def print_optional(msg):
    print(f"{Colors.OKCYAN}[OPTIONAL]{Colors.ENDC} {msg}")

class ConfigManager:
    """Manages configuration with interactive prompts"""
    
    def __init__(self):
        self.config = {}
        self.config_file = Path('.env')
        
        # Define all configuration variables
        self.required_vars = {
            'PROJECT_NAME': {
                'description': 'Project name',
                'default': 'AstronRPA',
                'validator': lambda x: len(x) > 0
            },
            'MYSQL_ROOT_PASSWORD': {
                'description': 'MySQL root password',
                'default': None,
                'validator': lambda x: len(x) >= 8
            },
            'MYSQL_DATABASE': {
                'description': 'MySQL database name',
                'default': 'astron_rpa',
                'validator': lambda x: len(x) > 0
            },
            'REDIS_PASSWORD': {
                'description': 'Redis password',
                'default': None,
                'validator': lambda x: len(x) >= 8
            },
        }
        
        self.optional_vars = {
            'MYSQL_PORT': {
                'description': 'MySQL port',
                'default': '3306',
                'validator': lambda x: x.isdigit() and 1024 <= int(x) <= 65535
            },
            'REDIS_PORT': {
                'description': 'Redis port',
                'default': '6379',
                'validator': lambda x: x.isdigit() and 1024 <= int(x) <= 65535
            },
            'MINIO_ROOT_USER': {
                'description': 'MinIO root username',
                'default': 'minioadmin',
                'validator': lambda x: len(x) >= 3
            },
            'MINIO_ROOT_PASSWORD': {
                'description': 'MinIO root password',
                'default': 'minioadmin',
                'validator': lambda x: len(x) >= 8
            },
            'MINIO_PORT': {
                'description': 'MinIO API port',
                'default': '9000',
                'validator': lambda x: x.isdigit() and 1024 <= int(x) <= 65535
            },
            'MINIO_CONSOLE_PORT': {
                'description': 'MinIO console port',
                'default': '9001',
                'validator': lambda x: x.isdigit() and 1024 <= int(x) <= 65535
            },
            'API_PORT': {
                'description': 'API Gateway port',
                'default': '8000',
                'validator': lambda x: x.isdigit() and 1024 <= int(x) <= 65535
            },
            'FRONTEND_PORT': {
                'description': 'Frontend application port',
                'default': '8080',
                'validator': lambda x: x.isdigit() and 1024 <= int(x) <= 65535
            },
            'AI_SERVICE_PORT': {
                'description': 'AI service port',
                'default': '6688',
                'validator': lambda x: x.isdigit() and 1024 <= int(x) <= 65535
            },
            'LOG_LEVEL': {
                'description': 'Logging level (DEBUG/INFO/WARNING/ERROR)',
                'default': 'INFO',
                'validator': lambda x: x.upper() in ['DEBUG', 'INFO', 'WARNING', 'ERROR']
            },
            'ENVIRONMENT': {
                'description': 'Environment (development/production)',
                'default': 'development',
                'validator': lambda x: x.lower() in ['development', 'production', 'dev', 'prod']
            },
            'ENABLE_AI_FEATURES': {
                'description': 'Enable AI features (yes/no)',
                'default': 'yes',
                'validator': lambda x: x.lower() in ['yes', 'no', 'y', 'n', 'true', 'false']
            },
            'BACKUP_ENABLED': {
                'description': 'Enable automatic backups (yes/no)',
                'default': 'yes',
                'validator': lambda x: x.lower() in ['yes', 'no', 'y', 'n', 'true', 'false']
            },
            'BACKUP_RETENTION_DAYS': {
                'description': 'Backup retention period (days)',
                'default': '7',
                'validator': lambda x: x.isdigit() and int(x) > 0
            },
        }
    
    def load_existing_config(self) -> bool:
        """Load existing configuration from .env file"""
        if not self.config_file.exists():
            return False
        
        try:
            with open(self.config_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        if '=' in line:
                            key, value = line.split('=', 1)
                            self.config[key.strip()] = value.strip()
            return True
        except Exception as e:
            print_error(f"Failed to load config: {e}")
            return False
    
    def prompt_for_value(self, key: str, config_def: Dict, required: bool) -> str:
        """Prompt user for a configuration value"""
        description = config_def['description']
        default = config_def.get('default')
        validator = config_def.get('validator')
        
        # Check if already in config
        if key in self.config:
            default = self.config[key]
        
        # Build prompt
        if required:
            prompt = f"{Colors.FAIL}{Colors.BOLD}[REQUIRED]{Colors.ENDC} {description}"
        else:
            prompt = f"{Colors.OKCYAN}[OPTIONAL]{Colors.ENDC} {description}"
        
        if default:
            prompt += f" [{Colors.OKGREEN}{default}{Colors.ENDC}]"
        
        prompt += ": "
        
        # Get input
        while True:
            try:
                value = input(prompt).strip()
                
                # Use default if empty
                if not value and default:
                    value = str(default)
                
                # Validate required fields
                if required and not value:
                    print_error("This field is required!")
                    continue
                
                # Skip validation if empty optional field
                if not value and not required:
                    return ""
                
                # Validate
                if validator and not validator(value):
                    print_error("Invalid value! Please try again.")
                    continue
                
                return value
            
            except (KeyboardInterrupt, EOFError):
                print("\n")
                print_warning("Configuration cancelled")
                sys.exit(0)
    
    def interactive_config(self) -> bool:
        """Run interactive configuration"""
        print_header("AstronRPA Configuration")
        
        # Check for existing config
        if self.load_existing_config():
            print_info("Found existing configuration")
            use_existing = input(f"Use existing values as defaults? [{Colors.OKGREEN}Y/n{Colors.ENDC}]: ").strip().lower()
            if use_existing in ['n', 'no']:
                self.config = {}
        
        print("\n" + Colors.BOLD + "=" * 60 + Colors.ENDC)
        print(Colors.BOLD + "REQUIRED CONFIGURATION" + Colors.ENDC)
        print(Colors.BOLD + "=" * 60 + Colors.ENDC + "\n")
        
        # Collect required variables
        for key, config_def in self.required_vars.items():
            value = self.prompt_for_value(key, config_def, required=True)
            self.config[key] = value
        
        print("\n" + Colors.BOLD + "=" * 60 + Colors.ENDC)
        print(Colors.BOLD + "OPTIONAL CONFIGURATION" + Colors.ENDC)
        print(Colors.BOLD + "=" * 60 + Colors.ENDC + "\n")
        
        configure_optional = input(f"Configure optional settings? [{Colors.OKGREEN}Y/n{Colors.ENDC}]: ").strip().lower()
        
        if configure_optional not in ['n', 'no']:
            for key, config_def in self.optional_vars.items():
                value = self.prompt_for_value(key, config_def, required=False)
                if value:
                    self.config[key] = value
        else:
            # Use defaults for optional vars
            for key, config_def in self.optional_vars.items():
                if key not in self.config and config_def.get('default'):
                    self.config[key] = str(config_def['default'])
        
        return True
    
    def save_config(self) -> bool:
        """Save configuration to .env file"""
        try:
            with open(self.config_file, 'w') as f:
                f.write("# AstronRPA Configuration\n")
                f.write("# Generated by setup.py\n\n")
                
                # Write required vars
                f.write("# Required Configuration\n")
                for key in self.required_vars.keys():
                    if key in self.config:
                        f.write(f"{key}={self.config[key]}\n")
                
                f.write("\n# Optional Configuration\n")
                for key in self.optional_vars.keys():
                    if key in self.config:
                        f.write(f"{key}={self.config[key]}\n")
            
            print_success(f"Configuration saved to {self.config_file}")
            return True
        except Exception as e:
            print_error(f"Failed to save config: {e}")
            return False
    
    def display_summary(self):
        """Display configuration summary"""
        print_header("Configuration Summary")
        
        print(Colors.BOLD + "Required Settings:" + Colors.ENDC)
        for key in self.required_vars.keys():
            if key in self.config:
                # Mask passwords
                value = self.config[key]
                if 'PASSWORD' in key:
                    value = '*' * len(value)
                print(f"  {Colors.OKGREEN}✓{Colors.ENDC} {key}: {value}")
        
        print(f"\n{Colors.BOLD}Optional Settings:{Colors.ENDC}")
        for key in self.optional_vars.keys():
            if key in self.config:
                print(f"  {Colors.OKCYAN}•{Colors.ENDC} {key}: {self.config[key]}")

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
        self.config_manager = ConfigManager()
    
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
                print_warning(f"Please install {tool} manually and re-run setup")
            else:
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
            print_warning("Engine directory not found - skipping")
            return True
        
        try:
            print_info("Installing Python packages...")
            req_file = engine_dir / 'requirements.txt'
            if req_file.exists():
                subprocess.run([sys.executable, '-m', 'pip', 'install', '-r',
                              str(req_file)], check=True)
            
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
            print_warning("Frontend directory not found - skipping")
            return True
        
        try:
            print_info("Installing npm packages...")
            subprocess.run(['npm', 'install'], cwd=frontend_dir, check=True)
            
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
            result = subprocess.run(['docker', 'ps'], 
                                  capture_output=True, timeout=5)
            
            if result.returncode != 0:
                print_error("Docker is not running")
                print_info("Please start Docker Desktop and try again")
                return False
            
            print_info("Starting Docker services...")
            compose_file = self.root_dir / 'docker-compose.yml'
            if compose_file.exists():
                subprocess.run(['docker-compose', 'up', '-d'],
                             cwd=self.root_dir, check=True)
                print_success("Docker services started")
            else:
                print_warning("docker-compose.yml not found - skipping")
            
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
        
        # Configuration
        print()
        if not self.config_manager.interactive_config():
            return False
        
        if not self.config_manager.save_config():
            return False
        
        self.config_manager.display_summary()
        
        # Confirm to continue
        print()
        proceed = input(f"\nProceed with installation? [{Colors.OKGREEN}Y/n{Colors.ENDC}]: ").strip().lower()
        if proceed in ['n', 'no']:
            print_warning("Installation cancelled")
            return False
        
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
        print_info("Configuration saved to .env")
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
    parser.add_argument('--config', action='store_true',
                       help='Configuration only')
    
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
    
    if args.config:
        print_header("Configuration Only")
        if manager.config_manager.interactive_config():
            manager.config_manager.save_config()
            manager.config_manager.display_summary()
        return 0
    
    if args.repair:
        print_header("Repair Installation")
        manager.build_engine()
        manager.build_frontend()
        return 0
    
    # Full setup
    success = manager.run_full_setup()
    return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())
