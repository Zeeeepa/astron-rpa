#!/usr/bin/env python3
"""
Dependency Analyzer - Phase 1 Intelligence Gathering
Analyzes AstronRPA service dependencies and generates architecture documentation
"""

import os
import sys
import json
import yaml
import re
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple
from datetime import datetime
from collections import defaultdict

class DependencyAnalyzer:
    """Analyzes service dependencies across the AstronRPA system"""
    
    def __init__(self, project_root: str = ".."):
        self.project_root = Path(project_root).resolve()
        self.dependencies = defaultdict(lambda: {
            'depends_on': set(),
            'used_by': set(),
            'ports': set(),
            'config_files': set(),
            'type': 'unknown',
            'health_check': None,
            'entry_point': None
        })
        
    def analyze_all(self) -> Dict:
        """Run complete dependency analysis"""
        print("🔍 [Phase 1] Starting Comprehensive Dependency Analysis...")
        print(f"    Project Root: {self.project_root}")
        
        # Step 1: Analyze Docker services
        print("\n[Step 1/5] Analyzing Docker services...")
        self.analyze_docker_compose()
        
        # Step 2: Analyze Python engine services
        print("[Step 2/5] Analyzing Python engine services...")
        self.analyze_python_services()
        
        # Step 3: Analyze configuration files
        print("[Step 3/5] Scanning configuration files...")
        self.analyze_config_files()
        
        # Step 4: Analyze port usage
        print("[Step 4/5] Mapping port allocations...")
        self.analyze_ports()
        
        # Step 5: Build dependency graph
        print("[Step 5/5] Building dependency graph...")
        graph = self.build_dependency_graph()
        
        print("\n✅ Analysis Complete!")
        return graph
    
    def analyze_docker_compose(self):
        """Analyze docker-compose.yml for service dependencies"""
        compose_file = self.project_root / "docker" / "docker-compose.yml"
        
        if not compose_file.exists():
            print(f"    ⚠️  docker-compose.yml not found at {compose_file}")
            return
        
        print(f"    📄 Reading {compose_file}")
        
        with open(compose_file, 'r', encoding='utf-8') as f:
            try:
                compose_data = yaml.safe_load(f)
            except yaml.YAMLError as e:
                print(f"    ❌ Error parsing YAML: {e}")
                return
        
        services = compose_data.get('services', {})
        print(f"    Found {len(services)} Docker services")
        
        for service_name, service_config in services.items():
            print(f"      • {service_name}")
            
            self.dependencies[service_name]['type'] = 'docker'
            self.dependencies[service_name]['config_files'].add(str(compose_file))
            
            # Extract dependencies
            depends_on = service_config.get('depends_on', [])
            if isinstance(depends_on, dict):
                depends_on = list(depends_on.keys())
            
            for dep in depends_on:
                self.dependencies[service_name]['depends_on'].add(dep)
                self.dependencies[dep]['used_by'].add(service_name)
            
            # Extract ports
            ports = service_config.get('ports', [])
            for port in ports:
                if isinstance(port, str):
                    # Format: "host:container" or just "port"
                    port_num = port.split(':')[-1].split('/')[0]
                    self.dependencies[service_name]['ports'].add(port_num)
            
            # Extract health check
            health_check = service_config.get('healthcheck', {})
            if health_check:
                test = health_check.get('test', [])
                if test:
                    self.dependencies[service_name]['health_check'] = ' '.join(test)
    
    def analyze_python_services(self):
        """Analyze Python engine services"""
        engine_dir = self.project_root / "engine" / "servers"
        
        if not engine_dir.exists():
            print(f"    ⚠️  Engine directory not found at {engine_dir}")
            return
        
        print(f"    📂 Scanning {engine_dir}")
        
        # Find all __main__.py files
        main_files = list(engine_dir.rglob("__main__.py"))
        print(f"    Found {len(main_files)} Python services")
        
        for main_file in main_files:
            # Extract service name from path
            # e.g., .../astronverse-executor/src/astronverse/executor/__main__.py → executor
            parts = main_file.parts
            service_name = None
            
            for i, part in enumerate(parts):
                if part.startswith('astronverse-'):
                    service_name = part.replace('astronverse-', '')
                    break
            
            if not service_name:
                continue
            
            print(f"      • {service_name}")
            
            self.dependencies[service_name]['type'] = 'python-engine'
            self.dependencies[service_name]['entry_point'] = str(main_file.relative_to(self.project_root))
            self.dependencies[service_name]['config_files'].add(str(main_file))
            
            # Analyze the __main__.py for hints
            with open(main_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
                # Look for port definitions
                port_matches = re.findall(r'--port["\'].*?default["\']?[:=]\s*["\']?(\d+)', content)
                for port in port_matches:
                    self.dependencies[service_name]['ports'].add(port)
                
                # Look for gateway_port or other service references
                gateway_matches = re.findall(r'--gateway_port["\'].*?default["\']?[:=]\s*["\']?(\d+)', content)
                if gateway_matches:
                    # This service depends on a gateway
                    self.dependencies[service_name]['depends_on'].add('gateway')
                    self.dependencies['gateway']['used_by'].add(service_name)
                    self.dependencies['gateway']['ports'].add(gateway_matches[0])
                
                # Check for imports that might indicate dependencies
                if 'mysql' in content.lower() or 'pymysql' in content:
                    self.dependencies[service_name]['depends_on'].add('mysql')
                    self.dependencies['mysql']['used_by'].add(service_name)
                
                if 'redis' in content.lower():
                    self.dependencies[service_name]['depends_on'].add('redis')
                    self.dependencies['redis']['used_by'].add(service_name)
                
                if 'minio' in content.lower() or 's3' in content.lower():
                    self.dependencies[service_name]['depends_on'].add('minio')
                    self.dependencies['minio']['used_by'].add(service_name)
    
    def analyze_config_files(self):
        """Scan for configuration files that might reveal dependencies"""
        print(f"    📂 Searching for config files...")
        
        config_patterns = [
            "**/*.yaml",
            "**/*.yml", 
            "**/*.json",
            "**/*.conf",
            "**/*.ini",
            "**/.env*"
        ]
        
        config_files = []
        for pattern in config_patterns:
            config_files.extend(self.project_root.rglob(pattern))
        
        # Filter out node_modules, .git, etc.
        config_files = [f for f in config_files 
                       if not any(x in f.parts for x in ['.git', 'node_modules', '__pycache__', 'dist'])]
        
        print(f"    Found {len(config_files)} config files")
        
        service_keywords = {
            'mysql': ['mysql', 'database_host', 'db_host', '3306'],
            'redis': ['redis', 'cache_host', '6379'],
            'minio': ['minio', 's3', 'object_storage', '9000'],
            'ai-service': ['ai_service', 'ai-service', 'ai_host'],
            'openapi-service': ['openapi', 'api_gateway'],
            'resource-service': ['resource_service', 'resource-service'],
            'robot-service': ['robot_service', 'robot-service']
        }
        
        for config_file in config_files[:50]:  # Limit to first 50 to avoid slowdown
            try:
                with open(config_file, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read().lower()
                    
                    for service, keywords in service_keywords.items():
                        for keyword in keywords:
                            if keyword in content:
                                # This config file mentions this service
                                # Try to determine which service this config belongs to
                                config_service = self._guess_service_from_path(config_file)
                                if config_service and config_service != service:
                                    self.dependencies[config_service]['depends_on'].add(service)
                                    self.dependencies[service]['used_by'].add(config_service)
                                break
            except Exception as e:
                pass  # Skip files that can't be read
    
    def _guess_service_from_path(self, path: Path) -> Optional[str]:
        """Guess which service a config file belongs to based on path"""
        parts = path.parts
        
        # Look for service name in path
        for part in parts:
            if part.startswith('astronverse-'):
                return part.replace('astronverse-', '')
            if part in ['mysql', 'redis', 'minio', 'docker']:
                return part
        
        return None
    
    def analyze_ports(self):
        """Analyze port usage across services"""
        print("    🔍 Analyzing port allocations...")
        
        # Scan for common port patterns in code
        search_dirs = [
            self.project_root / "engine",
            self.project_root / "backend",
            self.project_root / "frontend"
        ]
        
        for search_dir in search_dirs:
            if not search_dir.exists():
                continue
                
            for py_file in search_dir.rglob("*.py"):
                try:
                    with open(py_file, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        
                        # Look for port assignments
                        # port = 8080, PORT=8080, --port 8080, etc.
                        port_patterns = [
                            r'port\s*[:=]\s*(\d{4,5})',
                            r'PORT\s*[:=]\s*(\d{4,5})',
                            r'--port["\']?\s+(\d{4,5})',
                            r'localhost:(\d{4,5})',
                            r':\s*(\d{4,5})\s*[,\)]'  # In connection strings
                        ]
                        
                        for pattern in port_patterns:
                            matches = re.findall(pattern, content, re.IGNORECASE)
                            for port in matches:
                                if 1000 <= int(port) <= 65535:  # Valid port range
                                    service = self._guess_service_from_path(py_file)
                                    if service:
                                        self.dependencies[service]['ports'].add(port)
                
                except Exception:
                    pass
    
    def build_dependency_graph(self) -> Dict:
        """Build final dependency graph with all analysis results"""
        graph = {
            'metadata': {
                'analyzed_at': datetime.now().isoformat(),
                'project_root': str(self.project_root),
                'total_services': len(self.dependencies)
            },
            'services': {}
        }
        
        for service_name, data in self.dependencies.items():
            graph['services'][service_name] = {
                'type': data['type'],
                'entry_point': data['entry_point'],
                'depends_on': sorted(list(data['depends_on'])),
                'used_by': sorted(list(data['used_by'])),
                'ports': sorted(list(data['ports'])),
                'health_check': data['health_check'],
                'config_files': sorted(list(data['config_files']))
            }
        
        return graph
    
    def generate_markdown_report(self, graph: Dict) -> str:
        """Generate ARCHITECTURE.md report"""
        md = []
        md.append("# 🏗️ AstronRPA System Architecture\n")
        md.append(f"**Generated:** {graph['metadata']['analyzed_at']}\n")
        md.append(f"**Services Identified:** {graph['metadata']['total_services']}\n")
        md.append("\n---\n")
        
        # Group services by type
        by_type = defaultdict(list)
        for service_name, data in graph['services'].items():
            by_type[data['type']].append((service_name, data))
        
        # Docker services
        if 'docker' in by_type:
            md.append("\n## 🐳 Docker Services\n")
            for service_name, data in sorted(by_type['docker']):
                md.append(f"\n### {service_name}\n")
                md.append(f"- **Type:** Docker Container\n")
                if data['ports']:
                    md.append(f"- **Ports:** {', '.join(data['ports'])}\n")
                if data['health_check']:
                    md.append(f"- **Health Check:** `{data['health_check']}`\n")
                if data['depends_on']:
                    md.append(f"- **Depends On:** {', '.join(data['depends_on'])}\n")
                if data['used_by']:
                    md.append(f"- **Used By:** {', '.join(data['used_by'])}\n")
        
        # Python engine services
        if 'python-engine' in by_type:
            md.append("\n## 🐍 Python Engine Services\n")
            for service_name, data in sorted(by_type['python-engine']):
                md.append(f"\n### {service_name}\n")
                md.append(f"- **Type:** Python Service\n")
                if data['entry_point']:
                    md.append(f"- **Entry Point:** `{data['entry_point']}`\n")
                if data['ports']:
                    md.append(f"- **Ports:** {', '.join(data['ports'])}\n")
                if data['depends_on']:
                    md.append(f"- **Depends On:** {', '.join(data['depends_on'])}\n")
                if data['used_by']:
                    md.append(f"- **Used By:** {', '.join(data['used_by'])}\n")
        
        # Dependency graph
        md.append("\n## 📊 Dependency Graph\n")
        md.append("\n```\n")
        md.append("Service Dependency Flow:\n")
        md.append("========================\n\n")
        
        # Find root services (no dependencies)
        roots = [s for s, d in graph['services'].items() if not d['depends_on']]
        
        def print_tree(service, indent=0, visited=None):
            if visited is None:
                visited = set()
            if service in visited:
                return []
            visited.add(service)
            
            lines = [f"{'  ' * indent}├─ {service}"]
            used_by = graph['services'].get(service, {}).get('used_by', [])
            for child in sorted(used_by):
                lines.extend(print_tree(child, indent + 1, visited))
            return lines
        
        for root in sorted(roots):
            md.extend(print_tree(root))
        
        md.append("\n```\n")
        
        # Startup order recommendation
        md.append("\n## 🚀 Recommended Startup Order\n")
        md.append("\nBased on dependency analysis:\n\n")
        
        startup_order = self._calculate_startup_order(graph)
        for i, tier in enumerate(startup_order, 1):
            md.append(f"**Tier {i}:**\n")
            for service in sorted(tier):
                md.append(f"- {service}\n")
            md.append("\n")
        
        # Port allocation table
        md.append("\n## 🔌 Port Allocation Map\n")
        md.append("\n| Service | Ports | Type |\n")
        md.append("|---------|-------|------|\n")
        
        for service_name in sorted(graph['services'].keys()):
            data = graph['services'][service_name]
            if data['ports']:
                ports = ', '.join(sorted(data['ports']))
                md.append(f"| {service_name} | {ports} | {data['type']} |\n")
        
        return ''.join(md)
    
    def _calculate_startup_order(self, graph: Dict) -> List[List[str]]:
        """Calculate recommended startup order based on dependencies"""
        services = graph['services']
        tiers = []
        remaining = set(services.keys())
        
        while remaining:
            # Find services with no unmet dependencies
            tier = []
            for service in remaining:
                deps = set(services[service]['depends_on'])
                if deps.issubset(set().union(*tiers)):
                    tier.append(service)
            
            if not tier:
                # Circular dependency or unknown deps - add all remaining
                tier = list(remaining)
            
            tiers.append(tier)
            remaining -= set(tier)
        
        return tiers
    
    def export_json(self, graph: Dict, output_path: str):
        """Export dependency graph as JSON"""
        with open(output_path, 'w') as f:
            json.dump(graph, f, indent=2, default=str)
        print(f"✅ Exported JSON to: {output_path}")
    
    def export_markdown(self, graph: Dict, output_path: str):
        """Export architecture documentation as Markdown"""
        md = self.generate_markdown_report(graph)
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(md)
        print(f"✅ Exported Markdown to: {output_path}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Analyze AstronRPA service dependencies')
    parser.add_argument('--project-root', default='..', help='Project root directory')
    parser.add_argument('--output-json', default='ACTIONS/dependencies.json', help='Output JSON file')
    parser.add_argument('--output-md', default='ACTIONS/ARCHITECTURE.md', help='Output Markdown file')
    parser.add_argument('--phase1', action='store_true', help='Run complete Phase 1 analysis')
    
    args = parser.parse_args()
    
    analyzer = DependencyAnalyzer(project_root=args.project_root)
    graph = analyzer.analyze_all()
    
    # Export results
    analyzer.export_json(graph, args.output_json)
    analyzer.export_markdown(graph, args.output_md)
    
    print("\n" + "="*60)
    print("📊 ANALYSIS SUMMARY")
    print("="*60)
    print(f"Total Services: {graph['metadata']['total_services']}")
    
    by_type = defaultdict(int)
    for service_data in graph['services'].values():
        by_type[service_data['type']] += 1
    
    for stype, count in by_type.items():
        print(f"  {stype}: {count}")
    
    print(f"\nResults saved to:")
    print(f"  • JSON: {args.output_json}")
    print(f"  • Markdown: {args.output_md}")
    print("\n✅ Phase 1 Complete! Review ARCHITECTURE.md for detailed analysis.")


if __name__ == "__main__":
    main()

