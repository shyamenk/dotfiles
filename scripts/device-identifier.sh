#!/bin/bash
#
# Network Device Identifier
# A script to identify devices on your network with detailed information
# For Arch Linux systems
#

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root for full functionality${NC}"
  exit 1
fi

# Check for required tools
check_requirements() {
  local missing_tools=()
  
  for tool in nmap whois dig host nbtscan arp-scan; do
    if ! command -v "$tool" &> /dev/null; then
      missing_tools+=("$tool")
    fi
  done
  
  if [ ${#missing_tools[@]} -ne 0 ]; then
    echo -e "${YELLOW}Some tools are missing. Installing...${NC}"
    pacman -S --noconfirm --needed nmap whois bind-tools samba-common arp-scan 2>/dev/null
    
    # Check again after installation
    for tool in "${missing_tools[@]}"; do
      if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}Failed to install $tool. Some functionality may be limited.${NC}"
      fi
    done
  fi
}

# Function to scan a single IP
scan_device() {
  local ip=$1
  local output_file=$(mktemp)
  
  echo -e "\n${CYAN}=== Detailed Analysis for $ip ===${NC}"
  
  # Get MAC address and vendor
  echo -e "${YELLOW}Getting hardware information...${NC}"
  mac=$(arp -n | grep "$ip" | awk '{print $3}')
  
  if [ -n "$mac" ]; then
    echo -e "${GREEN}MAC Address:${NC} $mac"
    vendor=$(macchanger -l | grep -i "${mac:0:8}" | cut -d' ' -f5-)
    if [ -n "$vendor" ]; then
      echo -e "${GREEN}Hardware Vendor:${NC} $vendor"
    fi
  else
    echo -e "${RED}No MAC address found. Device might be offline.${NC}"
  fi
  
  # Basic port scan
  echo -e "\n${YELLOW}Scanning common ports...${NC}"
  nmap -F "$ip" > "$output_file"
  grep -E "^[0-9]+\/tcp|^[0-9]+\/udp" "$output_file" | while read line; do
    port=$(echo "$line" | awk '{print $1}')
    state=$(echo "$line" | awk '{print $2}')
    service=$(echo "$line" | awk '{print $3}')
    echo -e "${GREEN}$port${NC}\t$state\t$service"
  done
  
  # Try to identify OS
  echo -e "\n${YELLOW}Attempting OS detection...${NC}"
  os_info=$(nmap -O --osscan-guess "$ip" | grep -E "OS details|Running:" | head -1)
  if [ -n "$os_info" ]; then
    echo -e "${GREEN}OS Detection:${NC} $os_info"
  else
    echo -e "${RED}OS detection failed. Try with sudo for better results.${NC}"
  fi
  
  # Service version detection for open ports
  echo -e "\n${YELLOW}Detecting service versions...${NC}"
  open_ports=$(grep "open" "$output_file" | awk '{print $1}' | cut -d'/' -f1 | tr '\n' ',')
  if [ -n "$open_ports" ]; then
    open_ports=${open_ports%,} # Remove trailing comma
    nmap -sV -p "$open_ports" "$ip" | grep -E "^[0-9]+\/tcp|^[0-9]+\/udp" | while read line; do
      echo -e "${GREEN}$(echo $line | awk '{print $1}')${NC}\t$(echo $line | awk '{$1=""; print $0}')"
    done
  fi
  
  # Check for hostname
  echo -e "\n${YELLOW}Looking up hostname...${NC}"
  hostname=$(dig -x "$ip" +short)
  if [ -z "$hostname" ]; then
    hostname=$(host "$ip" | grep "domain name pointer" | awk '{print $5}')
  fi
  if [ -z "$hostname" ]; then
    hostname=$(nbtscan "$ip" 2>/dev/null | grep -v "^IP" | awk '{print $2}')
  fi
  
  if [ -n "$hostname" ]; then
    echo -e "${GREEN}Hostname:${NC} $hostname"
  else
    echo -e "${RED}No hostname found.${NC}"
  fi
  
  # Try to identify common services
  identify_service "$ip" 22 "SSH"
  identify_service "$ip" 53 "DNS"
  identify_service "$ip" 80 "Web Server"
  identify_service "$ip" 443 "HTTPS Web Server"
  identify_service "$ip" 21 "FTP"
  identify_service "$ip" 25 "SMTP (Mail)"
  identify_service "$ip" 3306 "MySQL"
  identify_service "$ip" 5432 "PostgreSQL"
  identify_service "$ip" 3389 "RDP"
  
  # Clean up
  rm "$output_file"
  
  echo -e "\n${CYAN}=== Analysis Complete ===${NC}"
}

# Function to identify specific services with banner grabbing where possible
identify_service() {
  local ip=$1
  local port=$2
  local service_name=$3
  
  # Check if port is open using nc with a 1 second timeout
  if timeout 1 bash -c "echo > /dev/tcp/$ip/$port" 2>/dev/null; then
    echo -e "\n${YELLOW}Detected $service_name on port $port${NC}"
    
    case $port in
      22)
        # SSH version
        ssh_banner=$(timeout 1 bash -c "echo '' | nc -w 1 $ip $port 2>/dev/null" | head -1)
        if [ -n "$ssh_banner" ]; then
          echo -e "${GREEN}SSH Version:${NC} $ssh_banner"
        fi
        ;;
      53)
        # Check if it's a DNS server by querying it
        dns_response=$(dig @"$ip" google.com +short)
        if [ -n "$dns_response" ]; then
          echo -e "${GREEN}Active DNS server${NC}"
        else
          echo -e "${RED}DNS port open but not responding to queries${NC}"
        fi
        ;;
      80|443)
        # Try to get web server info
        protocol="http"
        if [ "$port" -eq 443 ]; then protocol="https"; fi
        
        web_server=$(curl -s -I -m 2 "$protocol://$ip" | grep -i "Server:" | cut -d' ' -f2-)
        if [ -n "$web_server" ]; then
          echo -e "${GREEN}Web Server:${NC} $web_server"
        fi
        
        web_title=$(curl -s -L -m 2 "$protocol://$ip" | grep -i "<title>" | sed -e 's/<[^>]*>//g')
        if [ -n "$web_title" ]; then
          echo -e "${GREEN}Page Title:${NC} $web_title"
        fi
        ;;
    esac
  fi
}

# Main execution starts here
check_requirements

# Check if an IP was provided
if [ -z "$1" ]; then
  echo -e "${RED}Please provide an IP address to scan${NC}"
  echo -e "Usage: $0 <ip_address>"
  exit 1
fi

# Scan the provided IP
scan_device "$1"

# Provide suggestions based on open ports
echo -e "\n${CYAN}=== Device Identification ===${NC}"
if nmap -p22 --open "$1" -oG - 2>/dev/null | grep -q "22/open"; then
  echo -e "${GREEN}✓${NC} This device appears to be a Linux/Unix server or network device (SSH enabled)"
fi

if nmap -p53 --open "$1" -oG - 2>/dev/null | grep -q "53/open"; then
  echo -e "${GREEN}✓${NC} This device appears to be a DNS server"
fi

if nmap -p80,443 --open "$1" -oG - 2>/dev/null | grep -q "open"; then
  echo -e "${GREEN}✓${NC} This device is hosting a web server"
fi

if nmap -p161 --open "$1" -oG - 2>/dev/null | grep -q "161/open"; then
  echo -e "${GREEN}✓${NC} This device supports SNMP (likely a router, switch, or printer)"
fi

# Give final verdict based on the scan results
echo -e "\n${CYAN}=== Most Likely Device Type ===${NC}"
nmap_os=$(sudo nmap -O --osscan-guess "$1" 2>/dev/null | grep "Running:" | head -1 | cut -d ":" -f2- | tr -d '\n\r')
ssh_banner=$(timeout 1 bash -c "echo '' | nc -w 1 $1 22 2>/dev/null" | head -1)

if echo "$ssh_banner" | grep -qi "dropbear\|openwrt"; then
  echo -e "${MAGENTA}This appears to be a router or embedded device running OpenWRT or similar firmware${NC}"
elif echo "$ssh_banner" | grep -qi "ubuntu\|debian"; then
  echo -e "${MAGENTA}This appears to be a Linux server running Ubuntu/Debian${NC}"
elif [ "$nmap_os" ]; then
  echo -e "${MAGENTA}$nmap_os${NC}"
elif nmap -p53 --open "$1" -oG - 2>/dev/null | grep -q "53/open"; then
  echo -e "${MAGENTA}This is likely a DNS server or a router/gateway device${NC}"
else
  echo -e "${MAGENTA}Based on open ports (22/SSH, 53/DNS), this is likely a router, gateway, or Linux server${NC}"
fi

echo -e "\n${YELLOW}For more detailed information, try running:${NC}"
echo -e "  sudo nmap -A -T4 $1"
echo -e "  sudo nmap -sU -F $1 (to check UDP ports)"
