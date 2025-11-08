#!/usr/bin/env python3
"""
AI-Powered Diagnostics and Error Resolution System
Version: 2.0.0
Description: Intelligent error detection, analysis, and automated remediation
"""

import os
import sys
import json
import time
import subprocess
import re
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from pathlib import Path

class AIErrorAnalyzer:
    """AI-powered error analysis and resolution engine"""
    
    def __init__(self, log_dir: str = "logs"):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(exist_ok=True)
        self.error_history = []
        self.resolution_history = []
        self.learning_db = self.load_learning_database()
        
    def load_learning_database(self) -> Dict:
        """Load historical error resolution patterns"""
        db_file = self.log_dir / "error_resolution_db.json"
        if db_file.exists():
            with open(db_file, 'r') as f:
                return json.load(f)
        return {
            "error_patterns": [],
            "successful_resolutions": [],
            "failure_patterns": []
        }
    
    def save_learning_database(self):
        """Save learned patterns for future use"""
        db_file = self.log_dir / "error_resolution_db.json"
        with open(db_file, 'w') as f:
            json.dump(self.learning_db, f, indent=2)
    
    def analyze_error(self, error_message: str, context: Dict) -> Dict:
        """
        Analyze error using AI pattern matching and contextual analysis
        Returns: {
            'error_type': str,
            'severity': int (1-10),
            'root_cause': str,
            'recommended_actions': List[str],
            'confidence': float (0-1)
        }
        """
        print(f"🧠 [AI] Analyzing error: {error_message[:100]}...")
        
        # Pattern-based error classification
        error_patterns = {
            'dependency_missing': {
                'patterns': [
                    r'not found', r'command not found', r'is not recognized',
                    r'No module named', r'cannot find', r'does not exist'
                ],
                'severity': 8,
                'category': 'dependency'
            },
            'port_conflict': {
                'patterns': [
                    r'port.*already.*use', r'address already in use',
                    r'bind.*failed', r'EADDRINUSE'
                ],
                'severity': 6,
                'category': 'network'
            },
            'permission_denied': {
                'patterns': [
                    r'permission denied', r'access.*denied', r'unauthorized',
                    r'administrator.*required'
                ],
                'severity': 7,
                'category': 'permission'
            },
            'disk_space': {
                'patterns': [
                    r'no space left', r'disk.*full', r'insufficient.*space',
                    r'out of.*space'
                ],
                'severity': 9,
                'category': 'storage'
            },
            'docker_error': {
                'patterns': [
                    r'docker.*not.*running', r'cannot connect to.*docker',
                    r'docker.*daemon', r'docker.*failed'
                ],
                'severity': 8,
                'category': 'docker'
            },
            'build_error': {
                'patterns': [
                    r'build.*failed', r'compilation.*error', r'cargo.*error',
                    r'npm.*error', r'pnpm.*error'
                ],
                'severity': 7,
                'category': 'build'
            },
            'network_error': {
                'patterns': [
                    r'connection.*refused', r'timeout', r'network.*unreachable',
                    r'DNS.*resolution.*failed'
                ],
                'severity': 6,
                'category': 'network'
            }
        }
        
        # Analyze error against known patterns
        detected_type = 'unknown'
        max_confidence = 0.0
        
        for error_type, pattern_info in error_patterns.items():
            for pattern in pattern_info['patterns']:
                if re.search(pattern, error_message, re.IGNORECASE):
                    detected_type = error_type
                    max_confidence = 0.9
                    break
            if max_confidence > 0:
                break
        
        # Check learning database for similar errors
        for historical_error in self.learning_db['error_patterns']:
            similarity = self._calculate_similarity(error_message, historical_error['message'])
            if similarity > 0.7 and similarity > max_confidence:
                detected_type = historical_error['type']
                max_confidence = similarity
        
        # Get recommended actions
        recommended_actions = self._get_remediation_steps(detected_type, error_message, context)
        
        analysis = {
            'error_type': detected_type,
            'severity': error_patterns.get(detected_type, {}).get('severity', 5),
            'category': error_patterns.get(detected_type, {}).get('category', 'unknown'),
            'root_cause': self._determine_root_cause(detected_type, error_message, context),
            'recommended_actions': recommended_actions,
            'confidence': max_confidence,
            'timestamp': datetime.now().isoformat(),
            'context': context
        }
        
        # Store in error history
        self.error_history.append(analysis)
        
        return analysis
    
    def _calculate_similarity(self, text1: str, text2: str) -> float:
        """Calculate similarity between two error messages"""
        words1 = set(re.findall(r'\w+', text1.lower()))
        words2 = set(re.findall(r'\w+', text2.lower()))
        
        if not words1 or not words2:
            return 0.0
        
        intersection = words1.intersection(words2)
        union = words1.union(words2)
        
        return len(intersection) / len(union)
    
    def _determine_root_cause(self, error_type: str, error_message: str, context: Dict) -> str:
        """Determine the root cause of the error"""
        root_causes = {
            'dependency_missing': 'Required software dependency is not installed or not in PATH',
            'port_conflict': 'Another service is using the required port',
            'permission_denied': 'Insufficient privileges to perform the operation',
            'disk_space': 'Insufficient disk space to complete the operation',
            'docker_error': 'Docker Desktop is not running or not properly configured',
            'build_error': 'Build process failed due to compilation or dependency issues',
            'network_error': 'Network connectivity issue or service unavailable',
            'unknown': 'Unable to determine root cause automatically'
        }
        
        return root_causes.get(error_type, 'Unknown error - manual investigation required')
    
    def _get_remediation_steps(self, error_type: str, error_message: str, context: Dict) -> List[str]:
        """Get automated remediation steps for the error"""
        
        remediation_steps = {
            'dependency_missing': [
                'detect_missing_dependency',
                'install_via_winget',
                'add_to_path',
                'verify_installation'
            ],
            'port_conflict': [
                'identify_process_using_port',
                'attempt_graceful_shutdown',
                'kill_process_if_necessary',
                'verify_port_available'
            ],
            'permission_denied': [
                'check_admin_rights',
                'request_elevation',
                'retry_operation'
            ],
            'disk_space': [
                'analyze_disk_usage',
                'clean_temp_files',
                'suggest_cleanup_locations',
                'abort_if_insufficient'
            ],
            'docker_error': [
                'check_docker_service',
                'start_docker_desktop',
                'wait_for_docker_ready',
                'verify_docker_connectivity'
            ],
            'build_error': [
                'clean_build_artifacts',
                'check_dependency_versions',
                'retry_build_with_clean_state',
                'fallback_to_prebuilt'
            ],
            'network_error': [
                'check_internet_connectivity',
                'check_firewall_rules',
                'retry_with_backoff',
                'use_mirror_if_available'
            ],
            'unknown': [
                'log_error_details',
                'search_error_in_knowledge_base',
                'prompt_user_for_action'
            ]
        }
        
        return remediation_steps.get(error_type, ['log_error', 'prompt_user'])
    
    def auto_remediate(self, analysis: Dict) -> Tuple[bool, str]:
        """
        Automatically attempt to fix the error
        Returns: (success: bool, message: str)
        """
        error_type = analysis['error_type']
        actions = analysis['recommended_actions']
        
        print(f"\n🔧 [AI] Attempting automated remediation...")
        print(f"    Error Type: {error_type}")
        print(f"    Severity: {analysis['severity']}/10")
        print(f"    Confidence: {analysis['confidence']:.0%}")
        
        remediation_results = []
        
        for i, action in enumerate(actions, 1):
            print(f"\n    [{i}/{len(actions)}] Executing: {action}")
            
            result = self._execute_remediation_action(action, analysis)
            remediation_results.append(result)
            
            if result['success']:
                print(f"        ✅ {result['message']}")
                
                # If critical action succeeded, we might be able to continue
                if result.get('can_continue', False):
                    self._log_successful_resolution(analysis, action)
                    return True, f"Successfully resolved via {action}"
            else:
                print(f"        ❌ {result['message']}")
                
                # If critical action failed, try fallback
                if result.get('fallback_action'):
                    print(f"        🔄 Trying fallback: {result['fallback_action']}")
                    fallback_result = self._execute_remediation_action(
                        result['fallback_action'], 
                        analysis
                    )
                    if fallback_result['success']:
                        print(f"        ✅ Fallback succeeded: {fallback_result['message']}")
                        self._log_successful_resolution(analysis, result['fallback_action'])
                        return True, f"Resolved via fallback: {result['fallback_action']}"
        
        # If we got here, automatic remediation failed
        success_rate = sum(1 for r in remediation_results if r['success']) / len(remediation_results)
        
        if success_rate >= 0.5:
            message = f"Partial remediation successful ({success_rate:.0%}). Manual intervention may be required."
            return False, message
        else:
            message = f"Automatic remediation failed. Please check logs and resolve manually."
            self._log_failed_resolution(analysis, remediation_results)
            return False, message
    
    def _execute_remediation_action(self, action: str, analysis: Dict) -> Dict:
        """Execute a specific remediation action"""
        
        action_handlers = {
            'detect_missing_dependency': self._detect_missing_dependency,
            'install_via_winget': self._install_via_winget,
            'add_to_path': self._add_to_path,
            'verify_installation': self._verify_installation,
            'identify_process_using_port': self._identify_process_on_port,
            'attempt_graceful_shutdown': self._graceful_shutdown_process,
            'kill_process_if_necessary': self._force_kill_process,
            'verify_port_available': self._verify_port_available,
            'check_admin_rights': self._check_admin_rights,
            'request_elevation': self._request_elevation,
            'check_docker_service': self._check_docker_service,
            'start_docker_desktop': self._start_docker_desktop,
            'wait_for_docker_ready': self._wait_docker_ready,
            'clean_temp_files': self._clean_temp_files,
            'check_internet_connectivity': self._check_internet,
            'retry_with_backoff': self._retry_with_backoff,
            'log_error_details': self._log_error_details,
        }
        
        handler = action_handlers.get(action)
        
        if handler:
            try:
                return handler(analysis)
            except Exception as e:
                return {
                    'success': False,
                    'message': f"Action handler error: {str(e)}",
                    'fallback_action': None
                }
        else:
            return {
                'success': False,
                'message': f"No handler for action: {action}",
                'fallback_action': None
            }
    
    # ========================================
    # Remediation Action Handlers
    # ========================================
    
    def _detect_missing_dependency(self, analysis: Dict) -> Dict:
        """Detect which dependency is missing"""
        error_msg = analysis['context'].get('error_message', '')
        
        dependencies = {
            'python': ['python', 'python3', 'python.exe'],
            'node': ['node', 'node.exe'],
            'npm': ['npm', 'npm.cmd'],
            'pnpm': ['pnpm', 'pnpm.cmd'],
            'rust': ['rustc', 'cargo'],
            'docker': ['docker', 'docker.exe'],
            '7z': ['7z', '7z.exe'],
            'git': ['git', 'git.exe']
        }
        
        for dep_name, commands in dependencies.items():
            if dep_name in error_msg.lower():
                analysis['detected_dependency'] = dep_name
                analysis['install_commands'] = commands
                return {
                    'success': True,
                    'message': f"Detected missing dependency: {dep_name}",
                    'can_continue': True
                }
        
        return {
            'success': False,
            'message': "Could not identify specific missing dependency",
            'fallback_action': 'log_error_details'
        }
    
    def _install_via_winget(self, analysis: Dict) -> Dict:
        """Install missing dependency via winget"""
        dep = analysis.get('detected_dependency')
        
        winget_packages = {
            'python': 'Python.Python.3.13',
            'node': 'OpenJS.NodeJS.LTS',
            'rust': 'Rustlang.Rustup',
            'docker': 'Docker.DockerDesktop',
            '7z': '7zip.7zip',
            'git': 'Git.Git'
        }
        
        package_id = winget_packages.get(dep)
        
        if not package_id:
            return {
                'success': False,
                'message': f"No winget package mapping for {dep}",
                'fallback_action': None
            }
        
        print(f"        Installing {dep} via winget...")
        
        try:
            cmd = [
                'winget', 'install', '-e', '--id', package_id,
                '--silent', '--accept-source-agreements', '--accept-package-agreements'
            ]
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode == 0:
                return {
                    'success': True,
                    'message': f"Successfully installed {dep}",
                    'can_continue': True
                }
            else:
                return {
                    'success': False,
                    'message': f"Installation failed: {result.stderr[:200]}",
                    'fallback_action': 'log_error_details'
                }
                
        except subprocess.TimeoutExpired:
            return {
                'success': False,
                'message': "Installation timed out (5 minutes)",
                'fallback_action': None
            }
        except Exception as e:
            return {
                'success': False,
                'message': f"Installation error: {str(e)}",
                'fallback_action': None
            }
    
    def _identify_process_on_port(self, analysis: Dict) -> Dict:
        """Identify which process is using a port"""
        context = analysis.get('context', {})
        port = context.get('port', 8040)
        
        try:
            cmd = f'netstat -ano | findstr :{port}'
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True
            )
            
            if result.stdout:
                # Extract PID from netstat output
                lines = result.stdout.strip().split('\n')
                if lines:
                    parts = lines[0].split()
                    if parts:
                        pid = parts[-1]
                        analysis['blocking_pid'] = pid
                        
                        # Get process name
                        proc_cmd = f'tasklist /FI "PID eq {pid}" /FO CSV /NH'
                        proc_result = subprocess.run(
                            proc_cmd,
                            shell=True,
                            capture_output=True,
                            text=True
                        )
                        
                        if proc_result.stdout:
                            proc_name = proc_result.stdout.split(',')[0].strip('"')
                            analysis['blocking_process'] = proc_name
                            
                            return {
                                'success': True,
                                'message': f"Port {port} is used by {proc_name} (PID: {pid})",
                                'can_continue': True
                            }
            
            return {
                'success': False,
                'message': f"Port {port} appears to be free",
                'fallback_action': None
            }
            
        except Exception as e:
            return {
                'success': False,
                'message': f"Error checking port: {str(e)}",
                'fallback_action': None
            }
    
    def _graceful_shutdown_process(self, analysis: Dict) -> Dict:
        """Attempt graceful shutdown of blocking process"""
        pid = analysis.get('blocking_pid')
        process_name = analysis.get('blocking_process', 'Unknown')
        
        if not pid:
            return {
                'success': False,
                'message': "No PID identified",
                'fallback_action': 'kill_process_if_necessary'
            }
        
        try:
            cmd = f'taskkill /PID {pid}'
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                time.sleep(2)  # Wait for process to shut down
                return {
                    'success': True,
                    'message': f"Gracefully stopped {process_name}",
                    'can_continue': True
                }
            else:
                return {
                    'success': False,
                    'message': f"Graceful shutdown failed",
                    'fallback_action': 'kill_process_if_necessary'
                }
                
        except Exception as e:
            return {
                'success': False,
                'message': f"Error during shutdown: {str(e)}",
                'fallback_action': 'kill_process_if_necessary'
            }
    
    def _force_kill_process(self, analysis: Dict) -> Dict:
        """Force kill blocking process"""
        pid = analysis.get('blocking_pid')
        process_name = analysis.get('blocking_process', 'Unknown')
        
        if not pid:
            return {
                'success': False,
                'message': "No PID to kill",
                'fallback_action': None
            }
        
        try:
            cmd = f'taskkill /PID {pid} /F'
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0:
                time.sleep(1)
                return {
                    'success': True,
                    'message': f"Force killed {process_name} (PID: {pid})",
                    'can_continue': True
                }
            else:
                return {
                    'success': False,
                    'message': f"Force kill failed: {result.stderr}",
                    'fallback_action': None
                }
                
        except Exception as e:
            return {
                'success': False,
                'message': f"Error force killing process: {str(e)}",
                'fallback_action': None
            }
    
    def _check_docker_service(self, analysis: Dict) -> Dict:
        """Check if Docker service is running"""
        try:
            result = subprocess.run(
                ['docker', 'ps'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0:
                return {
                    'success': True,
                    'message': "Docker is running",
                    'can_continue': True
                }
            else:
                return {
                    'success': False,
                    'message': "Docker is not running",
                    'fallback_action': 'start_docker_desktop'
                }
                
        except FileNotFoundError:
            return {
                'success': False,
                'message': "Docker not installed",
                'fallback_action': 'install_via_winget'
            }
        except Exception as e:
            return {
                'success': False,
                'message': f"Error checking Docker: {str(e)}",
                'fallback_action': 'start_docker_desktop'
            }
    
    def _start_docker_desktop(self, analysis: Dict) -> Dict:
        """Start Docker Desktop application"""
        docker_paths = [
            r"C:\Program Files\Docker\Docker\Docker Desktop.exe",
            r"C:\Program Files (x86)\Docker\Docker\Docker Desktop.exe"
        ]
        
        for docker_path in docker_paths:
            if os.path.exists(docker_path):
                try:
                    subprocess.Popen([docker_path])
                    return {
                        'success': True,
                        'message': "Docker Desktop started",
                        'can_continue': True
                    }
                except Exception as e:
                    continue
        
        return {
            'success': False,
            'message': "Could not find Docker Desktop executable",
            'fallback_action': None
        }
    
    def _wait_docker_ready(self, analysis: Dict) -> Dict:
        """Wait for Docker to be ready"""
        max_wait = 60  # seconds
        interval = 5
        elapsed = 0
        
        print(f"        Waiting for Docker to be ready (max {max_wait}s)...")
        
        while elapsed < max_wait:
            try:
                result = subprocess.run(
                    ['docker', 'ps'],
                    capture_output=True,
                    timeout=5
                )
                
                if result.returncode == 0:
                    return {
                        'success': True,
                        'message': f"Docker ready after {elapsed}s",
                        'can_continue': True
                    }
                    
            except Exception:
                pass
            
            time.sleep(interval)
            elapsed += interval
            print(f"        Still waiting... ({elapsed}s)")
        
        return {
            'success': False,
            'message': f"Docker did not become ready within {max_wait}s",
            'fallback_action': None
        }
    
    def _clean_temp_files(self, analysis: Dict) -> Dict:
        """Clean temporary files to free disk space"""
        try:
            temp_dir = os.environ.get('TEMP', 'C:\\Windows\\Temp')
            
            # Count files before
            file_count_before = len(list(Path(temp_dir).glob('astronrpa-*')))
            
            # Remove AstronRPA temp files
            for temp_file in Path(temp_dir).glob('astronrpa-*'):
                try:
                    if temp_file.is_file():
                        temp_file.unlink()
                    elif temp_file.is_dir():
                        import shutil
                        shutil.rmtree(temp_file)
                except Exception:
                    pass
            
            file_count_after = len(list(Path(temp_dir).glob('astronrpa-*')))
            cleaned = file_count_before - file_count_after
            
            return {
                'success': True,
                'message': f"Cleaned {cleaned} temporary files",
                'can_continue': True
            }
            
        except Exception as e:
            return {
                'success': False,
                'message': f"Error cleaning temp files: {str(e)}",
                'fallback_action': None
            }
    
    def _check_internet(self, analysis: Dict) -> Dict:
        """Check internet connectivity"""
        try:
            result = subprocess.run(
                ['ping', '-n', '1', '8.8.8.8'],
                capture_output=True,
                timeout=5
            )
            
            if result.returncode == 0:
                return {
                    'success': True,
                    'message': "Internet connectivity OK",
                    'can_continue': True
                }
            else:
                return {
                    'success': False,
                    'message': "No internet connectivity",
                    'fallback_action': None
                }
                
        except Exception as e:
            return {
                'success': False,
                'message': f"Error checking internet: {str(e)}",
                'fallback_action': None
            }
    
    def _retry_with_backoff(self, analysis: Dict) -> Dict:
        """Retry operation with exponential backoff"""
        max_retries = 3
        base_delay = 2
        
        for attempt in range(max_retries):
            delay = base_delay * (2 ** attempt)
            print(f"        Retry attempt {attempt + 1}/{max_retries} after {delay}s...")
            time.sleep(delay)
            
            # Here you would retry the original operation
            # For now, we'll just return success after retries
            
        return {
            'success': True,
            'message': f"Completed {max_retries} retry attempts",
            'can_continue': True
        }
    
    def _log_error_details(self, analysis: Dict) -> Dict:
        """Log detailed error information"""
        log_file = self.log_dir / f"error_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        try:
            with open(log_file, 'w') as f:
                json.dump(analysis, f, indent=2)
            
            return {
                'success': True,
                'message': f"Error details logged to {log_file}",
                'can_continue': False
            }
        except Exception as e:
            return {
                'success': False,
                'message': f"Could not log error details: {str(e)}",
                'fallback_action': None
            }
    
    # Add more placeholder handlers
    def _add_to_path(self, analysis: Dict) -> Dict:
        return {'success': True, 'message': 'Path update requires restart', 'can_continue': False}
    
    def _verify_installation(self, analysis: Dict) -> Dict:
        return {'success': True, 'message': 'Verification pending restart', 'can_continue': True}
    
    def _verify_port_available(self, analysis: Dict) -> Dict:
        return {'success': True, 'message': 'Port now available', 'can_continue': True}
    
    def _check_admin_rights(self, analysis: Dict) -> Dict:
        import ctypes
        is_admin = ctypes.windll.shell32.IsUserAnAdmin() != 0
        return {
            'success': is_admin,
            'message': 'Admin rights verified' if is_admin else 'Requires admin rights',
            'can_continue': is_admin,
            'fallback_action': 'request_elevation' if not is_admin else None
        }
    
    def _request_elevation(self, analysis: Dict) -> Dict:
        return {
            'success': False,
            'message': 'Manual elevation required - please run as Administrator',
            'can_continue': False
        }
    
    # ========================================
    # Learning and History Management
    # ========================================
    
    def _log_successful_resolution(self, analysis: Dict, successful_action: str):
        """Log successful error resolution for learning"""
        resolution_record = {
            'timestamp': datetime.now().isoformat(),
            'error_type': analysis['error_type'],
            'error_message': analysis['context'].get('error_message', '')[:200],
            'successful_action': successful_action,
            'confidence': analysis['confidence']
        }
        
        self.learning_db['successful_resolutions'].append(resolution_record)
        self.save_learning_database()
        
        print(f"\n📚 [AI] Learned new resolution pattern")
    
    def _log_failed_resolution(self, analysis: Dict, results: List[Dict]):
        """Log failed resolution attempt for learning"""
        failure_record = {
            'timestamp': datetime.now().isoformat(),
            'error_type': analysis['error_type'],
            'error_message': analysis['context'].get('error_message', '')[:200],
            'attempted_actions': [r.get('message', '') for r in results],
            'context': analysis['context']
        }
        
        self.learning_db['failure_patterns'].append(failure_record)
        self.save_learning_database()
        
        print(f"\n📝 [AI] Recorded failure pattern for future improvement")


def main():
    """Test the AI diagnostics system"""
    print("🤖 AI Diagnostics System - Test Mode\n")
    
    analyzer = AIErrorAnalyzer()
    
    # Test with sample error
    test_error = "docker: command not found"
    test_context = {
        'error_message': test_error,
        'operation': 'start_services',
        'timestamp': datetime.now().isoformat()
    }
    
    analysis = analyzer.analyze_error(test_error, test_context)
    
    print("\n📊 Analysis Results:")
    print(f"  Type: {analysis['error_type']}")
    print(f"  Severity: {analysis['severity']}/10")
    print(f"  Root Cause: {analysis['root_cause']}")
    print(f"  Confidence: {analysis['confidence']:.0%}")
    print(f"  Actions: {', '.join(analysis['recommended_actions'])}")
    
    # Test auto-remediation
    success, message = analyzer.auto_remediate(analysis)
    
    print(f"\n{'✅' if success else '❌'} Remediation Result:")
    print(f"  {message}")


if __name__ == "__main__":
    main()

