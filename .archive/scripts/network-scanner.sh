#!/bin/bash
#
# Network Client Scanner
# Scans your local network and displays all connected clients
#

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root for full functionality${NC}"
  exit 1
fi

# Check and install required tools
check_requirements() {
  local missing_tools=()
  
  for tool in nmap ip arp-scan; do
    if ! command -v "$tool" &> /dev/null; then
      missing_tools+=("$tool")
    fi
  done
  
  if [ ${#missing_tools[@]} -ne 0 ]; then
    echo -e "${YELLOW}Some tools are missing. Installing...${NC}"
    pacman -S --noconfirm --needed nmap iproute2 arp-scan 2>/dev/null
    
    # Check again after installation
    for tool in "${missing_tools[@]}"; do
      if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}Failed to install $tool. Some functionality may be limited.${NC}"
      fi
    done
  fi
}

# Get local network information
get_network_info() {
  # Get default interface
  DEFAULT_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
  
  if [ -z "$DEFAULT_IFACE" ]; then
    echo -e "${RED}Could not determine default interface.${NC}"
    exit 1
  fi
  
  # Get IP and network info for the default interface
  IP_INFO=$(ip -o -4 addr show dev "$DEFAULT_IFACE" | awk '{print $4}')
  if [ -z "$IP_INFO" ]; then
    echo -e "${RED}Could not determine IP address of $DEFAULT_IFACE.${NC}"
    exit 1
  fi
  
  # Extract IP and prefix
  IP_ADDR=$(echo "$IP_INFO" | cut -d'/' -f1)
  PREFIX=$(echo "$IP_INFO" | cut -d'/' -f2)
  
  # Calculate network address
  IFS=. read -r i1 i2 i3 i4 <<< "$IP_ADDR"
  IFS=. read -r m1 m2 m3 m4 <<< "$(get_netmask "$PREFIX")"
  NETWORK="$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))"
  
  CIDR="$NETWORK/$PREFIX"
  
  echo -e "${YELLOW}Interface:${NC} $DEFAULT_IFACE"
  echo -e "${YELLOW}IP Address:${NC} $IP_ADDR"
  echo -e "${YELLOW}Network:${NC} $CIDR"
  
  return 0
}

# Convert prefix to netmask
get_netmask() {
  local prefix=$1
  local mask=""
  
  for ((i=0; i<4; i++)); do
    if [ $prefix -ge 8 ]; then
      mask="${mask}255."
      prefix=$((prefix-8))
    elif [ $prefix -gt 0 ]; then
      mask="${mask}$((256 - 2**(8-prefix)))."
      prefix=0
    else
      mask="${mask}0."
    fi
  done
  
  echo "${mask%?}" # Remove trailing dot
}

# Scan network using different methods
scan_network() {
  local network=$1
  local temp_file=$(mktemp)
  local results_file=$(mktemp)
  
  echo -e "\n${CYAN}=== Scanning Network: $network ===${NC}"
  echo -e "${YELLOW}This may take a few minutes depending on network size...${NC}\n"
  
  # Method 1: ARP-Scan (fast but may miss some hosts)
  echo -e "${BLUE}Performing ARP scan...${NC}"
  arp-scan --localnet > "$temp_file"
  
  # Extract info from ARP scan
  awk '/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {
    printf "%s\t%s\t%s\n", $1, $2, $3 " " $4 " " $5 " " $6
  }' "$temp_file" > "$results_file"
  
  # Method 2: NMAP scan (more thorough but slower)
  echo -e "${BLUE}Performing nmap ping scan...${NC}"
  nmap -sn "$network" -oG - | grep "Status: Up" -B 1 | grep "Host:" | \
    awk '{print $2}' | while read -r ip; do
    
    # Check if IP already in results
    if ! grep -q "$ip" "$results_file"; then
      # Get MAC if possible
      mac=$(arp -n | grep "$ip" | awk '{print $3}')
      
      # Get hostname if possible
      hostname=$(dig +short -x "$ip" 2>/dev/null)
      if [ -z "$hostname" ]; then
        hostname=$(host "$ip" 2>/dev/null | grep "domain name pointer" | awk '{print $5}')
      fi
      if [ -z "$hostname" ]; then
        hostname="Unknown"
      fi
      
      # Vendor lookup
      vendor="Unknown"
      if [ -n "$mac" ]; then
        vendor_lookup=$(macchanger -l | grep -i "${mac:0:8}" | cut -d' ' -f5-)
        if [ -n "$vendor_lookup" ]; then
          vendor=$vendor_lookup
        fi
      fi
      
      # Add to results
      echo -e "$ip\t$mac\t$vendor\t$hostname" >> "$results_file"
    fi
  done

  # Display results in a nicely formatted table
  echo -e "\n${GREEN}=== Connected Clients ===${NC}"
  echo -e "${CYAN}IP Address\tMAC Address\t\tVendor\t\t\tHostname${NC}"
  echo "-----------------------------------------------------------------------------------------------------------"
  
  sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n "$results_file" | \
  while IFS=$'\t' read -r ip mac vendor hostname; do
    printf "%-15s %-18s %-20s %s\n" "$ip" "${mac:-Unknown}" "${vendor:-Unknown}" "${hostname:-Unknown}"
  done
  
  # Count devices
  local count=$(wc -l < "$results_file")
  echo -e "\n${GREEN}Total devices found: $count${NC}"
  
  # Clean up
  rm "$temp_file" "$results_file"
}

# Perform an active DHCP client discovery
discover_dhcp_clients() {
  echo -e "\n${CYAN}=== DHCP Client Discovery ===${NC}"
  
  if command -v dhcpd &> /dev/null || command -v dnsmasq &> /dev/null; then
    if [ -f /var/lib/dhcp/dhcpd.leases ]; then
      echo -e "${YELLOW}DHCP leases from dhcpd:${NC}"
      grep -E "lease|hostname|hardware ethernet|binding state active" /var/lib/dhcp/dhcpd.leases | \
        grep -B 1 -A 2 "binding state active" | \
        awk 'BEGIN{RS="--"; FS="\n"} {
          for(i=1;i<=NF;i++) {
            if($i ~ /lease/) {ip=$i; gsub(/lease | {/,"",ip)}
            else if($i ~ /hardware ethernet/) {mac=$i; gsub(/hardware ethernet |;/,"",mac)}
            else if($i ~ /hostname/) {host=$i; gsub(/hostname "|";/,"",host)}
          }
          if(ip != "" && (mac != "" || host != "")) printf "%-15s %-18s %s\n", ip, mac, host
          ip=""; mac=""; host=""
        }'
      
    elif [ -f /var/lib/misc/dnsmasq.leases ]; then
      echo -e "${YELLOW}DHCP leases from dnsmasq:${NC}"
      awk '{printf "%-15s %-18s %s\n", $3, $2, $4}' /var/lib/misc/dnsmasq.leases
      
    else
      echo -e "${RED}No DHCP lease files found.${NC}"
    fi
  else
    echo -e "${RED}No DHCP server software detected on this system.${NC}"
  fi
}

# Main execution starts here
check_requirements
get_network_info
scan_network "$CIDR"
discover_dhcp_clients

echo -e "\n${YELLOW}Scan complete!${NC}"
echo -e "${YELLOW}For more detailed information about a specific device:${NC}"
echo -e "  sudo ./device-identifier.sh <ip_address>"
