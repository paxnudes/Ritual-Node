#!/bin/bash

clear
echo -e "\033[1m\033[95m"
echo "╭───────────────────────────────────────────────────╮"
echo "│                                                   │"
echo "│  ██████╗  ██╗████████╗██╗   ██╗ █████╗ ██╗        │"
echo "│  ██╔══██╗ ██║╚══██╔══╝██║   ██║██╔══██╗██║        │"
echo "│  ██████╔╝ ██║   ██║   ██║   ██║███████║██║        │"
echo "│  ██╔══██╗ ██║   ██║   ██║   ██║██╔══██║██║        │"
echo "│  ██║  ██║ ██║   ██║   ╚██████╔╝██║  ██║███████╗   │"
echo "│  ╚═╝  ╚═╝ ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝   │"
echo "│                                                   │"
echo "│                NODE SETUP                         │"
echo "│                                                   │"
echo "╰───────────────────────────────────────────────────╯"
echo -e "\033[0m"

echo -e "\033[96mThis script will guide you through the setup of your Ritual Node.\033[0m"
echo -e "\033[93mYou will need your private key (with 0x prefix) to complete the setup.\033[0m"
echo ""
echo -e "\033[97mPress ENTER to continue or CTRL+C to cancel...\033[0m"
read

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute the setup script
"${SCRIPT_DIR}/setup.sh" 