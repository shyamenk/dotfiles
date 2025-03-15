#!/usr/bin/env python3
"""
Ping Sweep Script - A simple network scanner that checks for responsive hosts
"""

import subprocess
import ipaddress
import argparse
import concurrent.futures
import platform
import sys
from datetime import datetime

def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Ping Sweep Network Scanner")
    parser.add_argument("-n", "--network", required=True, 
                        help="Target network with CIDR notation (e.g., 192.168.1.0/24)")
    parser.add_argument("-t", "--threads", type=int, default=10,
                        help="Number of concurrent threads (default: 10)")
    parser.add_argument("-to", "--timeout", type=int, default=1,
                        help="Ping timeout in seconds (default: 1)")
    parser.add_argument("-c", "--count", type=int, default=1,
                        help="Number of packets to send (default: 1)")
    return parser.parse_args()

def ping(ip_address, timeout, count):
    """
    Ping an IP address and return whether it's responsive or not.
    Adapts the command based on the operating system.
    """
    # Check which OS we're running on and adjust the ping command accordingly
    os_type = platform.system().lower()
    
    if os_type == "windows":
        # Windows ping command
        ping_cmd = ["ping", "-n", str(count), "-w", str(timeout * 1000), str(ip_address)]
        no_response_text = "Request timed out"
    else:
        # Linux/Unix/MacOS ping command
        ping_cmd = ["ping", "-c", str(count), "-W", str(timeout), str(ip_address)]
        no_response_text = "100% packet loss"
    
    try:
        output = subprocess.check_output(ping_cmd, stderr=subprocess.STDOUT, text=True)
        return not no_response_text in output
    except subprocess.CalledProcessError:
        return False
    except Exception as e:
        print(f"Error pinging {ip_address}: {e}")
        return False

def main():
    args = parse_arguments()
    
    try:
        # Parse the network from CIDR notation
        network = ipaddress.ip_network(args.network)
        
        # Get the number of hosts in the network (excluding network and broadcast addresses for IPv4)
        if network.version == 4 and network.num_addresses > 2:
            hosts = list(network.hosts())  # Excludes network and broadcast addresses
        else:
            hosts = list(network)  # Include all addresses for IPv6 or small IPv4 networks
        
        host_count = len(hosts)
        
        print(f"\n[*] Ping Sweep Script")
        print(f"[*] Target Network: {args.network}")
        print(f"[*] Scanning {host_count} hosts with {args.threads} threads")
        print(f"[*] Start Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("-" * 60)
        
        # Count alive hosts
        alive_hosts = []
        
        # Use ThreadPoolExecutor to run pings concurrently
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.threads) as executor:
            # Create a dictionary mapping futures to IP addresses
            future_to_ip = {
                executor.submit(ping, str(ip), args.timeout, args.count): ip 
                for ip in hosts
            }
            
            # Process as completed to show progress
            completed = 0
            for future in concurrent.futures.as_completed(future_to_ip):
                ip = future_to_ip[future]
                completed += 1
                
                # Print progress
                sys.stdout.write(f"\r[*] Progress: {completed}/{host_count} hosts scanned ({completed/host_count*100:.1f}%)")
                sys.stdout.flush()
                
                # If host is alive, add to list
                try:
                    is_alive = future.result()
                    if is_alive:
                        alive_hosts.append(str(ip))
                except Exception as e:
                    print(f"\nError scanning {ip}: {e}")
        
        # Print results
        print("\n" + "-" * 60)
        print(f"[+] Scan completed: {len(alive_hosts)}/{host_count} hosts are up")
        print("-" * 60)
        
        # Print alive hosts
        if alive_hosts:
            print("[+] Responsive hosts:")
            for host in sorted(alive_hosts, key=lambda ip: [int(octet) for octet in ip.split('.')]):
                print(f"    {host}")
        
        print(f"[*] End Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
    except ValueError as e:
        print(f"[!] Error: {e}")
        print("[!] Please provide a valid network in CIDR notation (e.g., 192.168.1.0/24)")
        sys.exit(1)
    
    except KeyboardInterrupt:
        print("\n[!] Scan interrupted by user")
        sys.exit(1)

if __name__ == "__main__":
    main()
