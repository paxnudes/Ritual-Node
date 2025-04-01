#!/bin/bash

# Source installation path if available
if [ -f ~/.ritual_node_env ]; then
    source ~/.ritual_node_env
else
    # Default path if environment file doesn't exist
    RITUAL_NODE_PATH=~/infernet-container-starter
fi

# Check for command line arguments
if [ "$1" == "--version" ]; then
    echo "Ritual Node Management System v1.0.0"
    exit 0
fi

# Colors and formatting
BOLD="\033[1m"
DIM="\033[2m"
BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
BRIGHT_BLACK="\033[90m"
BRIGHT_RED="\033[91m"
BRIGHT_GREEN="\033[92m"
BRIGHT_YELLOW="\033[93m"
BRIGHT_BLUE="\033[94m"
BRIGHT_MAGENTA="\033[95m"
BRIGHT_CYAN="\033[96m"
BRIGHT_WHITE="\033[97m"
NC="\033[0m"

# Display header
display_header() {
    clear
    echo -e "${BOLD}${BRIGHT_MAGENTA}"
    echo "╭───────────────────────────────────────────────────╮"
    echo "│                                                   │"
    echo "│  ██████╗  ██╗████████╗██╗   ██╗ █████╗ ██╗        │"
    echo "│  ██╔══██╗ ██║╚══██╔══╝██║   ██║██╔══██╗██║        │"
    echo "│  ██████╔╝ ██║   ██║   ██║   ██║███████║██║        │"
    echo "│  ██╔══██╗ ██║   ██║   ██║   ██║██╔══██║██║        │"
    echo "│  ██║  ██║ ██║   ██║   ╚██████╔╝██║  ██║███████╗   │"
    echo "│  ╚═╝  ╚═╝ ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝   │"
    echo "│                                                   │"
    echo "│                NODE MANAGEMENT                    │"
    echo "│                                                   │"
    echo "╰───────────────────────────────────────────────────╯"
    echo -e "${NC}\n"
}

# Main menu function
show_menu() {
    display_header
    
    echo -e "${BOLD}${WHITE}Select an option:${NC}\n"
    
    echo -e "  ${BRIGHT_CYAN}1${NC}  ${WHITE}Initialize Node${NC}           ${BRIGHT_BLACK}Complete Ritual Node setup${NC}"
    echo -e "  ${BRIGHT_CYAN}2${NC}  ${WHITE}Monitor Node${NC}              ${BRIGHT_BLACK}Real-time system monitoring dashboard${NC}"
    echo -e "  ${BRIGHT_CYAN}3${NC}  ${WHITE}Start Node${NC}                ${BRIGHT_BLACK}Start all node containers${NC}"
    echo -e "  ${BRIGHT_CYAN}4${NC}  ${WHITE}Stop Node${NC}                 ${BRIGHT_BLACK}Stop all node containers${NC}"
    echo -e "  ${BRIGHT_CYAN}5${NC}  ${WHITE}View Logs${NC}                 ${BRIGHT_BLACK}Show container logs in real time${NC}"
    echo -e "  ${BRIGHT_CYAN}6${NC}  ${WHITE}Deploy Contract${NC}           ${BRIGHT_BLACK}Deploy consumer contract${NC}"
    echo -e "  ${BRIGHT_CYAN}7${NC}  ${WHITE}Call Contract${NC}             ${BRIGHT_BLACK}Execute sayGM() function${NC}"
    echo -e "  ${BRIGHT_CYAN}8${NC}  ${WHITE}System Information${NC}        ${BRIGHT_BLACK}Display system resource details${NC}"
    echo -e "  ${BRIGHT_CYAN}9${NC}  ${WHITE}Check Node Status${NC}         ${BRIGHT_BLACK}Quick health check${NC}"
    echo -e "  ${BRIGHT_CYAN}U${NC}  ${WHITE}Uninstall Node${NC}            ${BRIGHT_BLACK}Remove containers and configuration${NC}"
    echo -e "  ${BRIGHT_CYAN}0${NC}  ${WHITE}Exit${NC}                      ${BRIGHT_BLACK}Quit the application${NC}"
    
    echo -e "\n${BRIGHT_BLACK}Enter your choice [0-9, U]:${NC} "
    read -r choice
    
    handle_choice "$choice"
}

# Function to handle menu choices
handle_choice() {
    # Get the script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check if secure configuration exists for operations that need it
    local needs_key=false
    if [[ "$1" == "6" || "$1" == "7" ]]; then
        needs_key=true
        # Verify private key is accessible
        if [[ ! -f ~/.ritual-secure/key.enc || ! -f ~/.ritual-secure/salt ]]; then
            echo -e "\n${BRIGHT_RED}Error: Private key not found or not properly configured.${NC}"
            echo -e "${YELLOW}You must initialize the node first to set up your private key.${NC}"
            echo -e "\n${BRIGHT_BLACK}Press Enter to return to menu...${NC}"
            read
            show_menu
            return
        fi
    fi
    
    case $1 in
        1)
            "${SCRIPT_DIR}/run.sh"
            ;;
        2)
            "${SCRIPT_DIR}/monitor.sh"
            ;;
        3)
            start_node
            ;;
        4)
            stop_node
            ;;
        5)
            view_logs
            ;;
        6)
            deploy_contract
            ;;
        7)
            call_contract
            ;;
        8)
            system_info
            ;;
        9)
            node_status
            ;;
        [Uu])
            uninstall_node
            ;;
        0)
            echo -e "\n${BRIGHT_GREEN}Exiting Ritual Management System. Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${BRIGHT_RED}Invalid option. Press Enter to continue...${NC}"
            read
            show_menu
            ;;
    esac
}

# Start node function
start_node() {
    clear
    echo -e "${BOLD}${BRIGHT_CYAN}Starting Ritual Node...${NC}\n"
    
    docker compose -f $RITUAL_NODE_PATH/deploy/docker-compose.yaml up -d
    
    echo -e "\n${BRIGHT_GREEN}Node started successfully!${NC}"
    echo -e "${BRIGHT_BLACK}Press Enter to return to menu...${NC}"
    read
    show_menu
}

# Stop node function
stop_node() {
    clear
    echo -e "${BOLD}${BRIGHT_YELLOW}Stopping Ritual Node...${NC}\n"
    
    docker compose -f $RITUAL_NODE_PATH/deploy/docker-compose.yaml down
    
    echo -e "\n${BRIGHT_GREEN}Node stopped successfully!${NC}"
    echo -e "${BRIGHT_BLACK}Press Enter to return to menu...${NC}"
    read
    show_menu
}

# View logs function
view_logs() {
    clear
    echo -e "${BOLD}${BRIGHT_CYAN}Showing logs (Ctrl+C to exit)...${NC}\n"
    
    docker compose -f $RITUAL_NODE_PATH/deploy/docker-compose.yaml logs -f
    
    show_menu
}

# Deploy contract function
deploy_contract() {
    clear
    echo -e "${BOLD}${BRIGHT_MAGENTA}Deploying Consumer Contract...${NC}\n"
    
    cd $RITUAL_NODE_PATH
    CONTRACT_RESULT=$(project=hello-world make deploy-contracts 2>&1)
    echo "$CONTRACT_RESULT"
    
    # Extract contract address
    CONTRACT_ADDRESS=$(echo "$CONTRACT_RESULT" | grep -oP 'Deployed SaysHello: \K0x[a-fA-F0-9]+')
    
    if [ -n "$CONTRACT_ADDRESS" ]; then
        echo -e "\n${BRIGHT_GREEN}Contract deployed successfully!${NC}"
        echo -e "${WHITE}Contract Address: ${BRIGHT_CYAN}$CONTRACT_ADDRESS${NC}"
        
        # Save contract address for monitor
        echo "$CONTRACT_ADDRESS" > ~/.ritual_contract
        
        # Update CallContract.s.sol with the new contract address
        sed -i "s/SaysGM saysGm = SaysGM(.*);/SaysGM saysGm = SaysGM($CONTRACT_ADDRESS);/" $RITUAL_NODE_PATH/projects/hello-world/contracts/script/CallContract.s.sol
    else
        echo -e "\n${BRIGHT_RED}Failed to deploy contract.${NC}"
    fi
    
    echo -e "\n${BRIGHT_BLACK}Press Enter to return to menu...${NC}"
    read
    show_menu
}

# Call contract function
call_contract() {
    clear
    echo -e "${BOLD}${BRIGHT_BLUE}Calling sayGM() function...${NC}\n"
    
    cd $RITUAL_NODE_PATH
    CALL_RESULT=$(project=hello-world make call-contract 2>&1)
    echo "$CALL_RESULT"
    
    echo -e "\n${BRIGHT_BLACK}Press Enter to return to menu...${NC}"
    read
    show_menu
}

# System information function
system_info() {
    clear
    echo -e "${BOLD}${BRIGHT_CYAN}System Information${NC}\n"
    
    echo -e "${BOLD}${WHITE}CPU Usage:${NC}"
    echo -e "${BRIGHT_BLACK}$(top -bn1 | head -n 5)${NC}\n"
    
    echo -e "${BOLD}${WHITE}Memory Usage:${NC}"
    echo -e "${BRIGHT_BLACK}$(free -h)${NC}\n"
    
    echo -e "${BOLD}${WHITE}Disk Usage:${NC}"
    echo -e "${BRIGHT_BLACK}$(df -h /)${NC}\n"
    
    echo -e "${BOLD}${WHITE}Docker Containers:${NC}"
    echo -e "${BRIGHT_BLACK}$(docker ps)${NC}\n"
    
    echo -e "${BRIGHT_BLACK}Press Enter to return to menu...${NC}"
    read
    show_menu
}

# Node status function
node_status() {
    clear
    echo -e "${BOLD}${BRIGHT_CYAN}Ritual Node Status${NC}\n"
    
    # Check if containers are running
    echo -e "${BOLD}${WHITE}Container Status:${NC}"
    if docker ps | grep -q "ritual-node"; then
        echo -e "  ${BRIGHT_GREEN}✓${NC} ${WHITE}ritual-node${NC}: ${BRIGHT_GREEN}Running${NC}"
    else
        echo -e "  ${BRIGHT_RED}✗${NC} ${WHITE}ritual-node${NC}: ${BRIGHT_RED}Not running${NC}"
    fi
    
    if docker ps | grep -q "ritual-redis"; then
        echo -e "  ${BRIGHT_GREEN}✓${NC} ${WHITE}ritual-redis${NC}: ${BRIGHT_GREEN}Running${NC}"
    else
        echo -e "  ${BRIGHT_RED}✗${NC} ${WHITE}ritual-redis${NC}: ${BRIGHT_RED}Not running${NC}"
    fi
    
    if docker ps | grep -q "ritual-hello-world"; then
        echo -e "  ${BRIGHT_GREEN}✓${NC} ${WHITE}ritual-hello-world${NC}: ${BRIGHT_GREEN}Running${NC}"
    else
        echo -e "  ${BRIGHT_RED}✗${NC} ${WHITE}ritual-hello-world${NC}: ${BRIGHT_RED}Not running${NC}"
    fi
    
    # Check API status
    echo -e "\n${BOLD}${WHITE}API Status:${NC}"
    local api_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/health 2>/dev/null)
    if [ "$api_status" == "200" ]; then
        echo -e "  ${BRIGHT_GREEN}✓${NC} ${WHITE}API${NC}: ${BRIGHT_GREEN}Online${NC} (200 OK)"
    else
        echo -e "  ${BRIGHT_RED}✗${NC} ${WHITE}API${NC}: ${BRIGHT_RED}Offline${NC} ($api_status)"
    fi
    
    echo -e "\n${BRIGHT_BLACK}Press Enter to return to menu...${NC}"
    read
    show_menu
}

# Uninstall function
uninstall_node() {
    clear
    echo -e "${BOLD}${BRIGHT_RED}Uninstalling Ritual Node...${NC}\n"
    
    echo -e "${YELLOW}WARNING: This will remove all containers, images, and configuration files.${NC}"
    echo -e "${RED}IMPORTANT: Your private key backup will be kept in ~/.ritual-secure/backups${NC}"
    echo -e "${RED}            Make sure you have a copy of your private key before continuing!${NC}"
    echo -e "${YELLOW}Are you sure you want to proceed? (yes/no)${NC}"
    read -r confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo -e "\n${BRIGHT_GREEN}Uninstall cancelled.${NC}"
        echo -e "${BRIGHT_BLACK}Press Enter to return to menu...${NC}"
        read
        show_menu
        return
    fi
    
    echo -e "\n${YELLOW}Would you like to keep your private key for future installations? (yes/no)${NC}"
    read -r keep_key
    
    echo -e "\n${BRIGHT_BLACK}Stopping containers...${NC}"
    docker compose -f $RITUAL_NODE_PATH/deploy/docker-compose.yaml down
    
    echo -e "\n${BRIGHT_BLACK}Removing container images...${NC}"
    docker rmi ritualnetwork/infernet-node:v1.4.0 ritualnetwork/hello-world-infernet:latest redis:latest
    
    echo -e "\n${BRIGHT_BLACK}Removing repository files...${NC}"
    rm -rf $RITUAL_NODE_PATH
    
    echo -e "\n${BRIGHT_BLACK}Removing configuration files...${NC}"
    rm -f ~/.ritual_contract
    rm -f ~/.ritual_node_env
    
    if [[ "$keep_key" != "yes" ]]; then
        # If not keeping key, move to backup instead of deleting
        if [ -f ~/.ritual-secure/key.enc ]; then
            mkdir -p ~/.ritual-secure/backups
            BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")
            mv ~/.ritual-secure/key.enc ~/.ritual-secure/backups/key.enc.uninstall.$BACKUP_DATE
            mv ~/.ritual-secure/salt ~/.ritual-secure/backups/salt.uninstall.$BACKUP_DATE
            echo -e "${YELLOW}Private key backup saved to ~/.ritual-secure/backups/key.enc.uninstall.$BACKUP_DATE${NC}"
        fi
    else
        echo -e "${GREEN}Keeping private key for future installations.${NC}"
    fi
    
    echo -e "\n${BRIGHT_GREEN}Uninstall completed successfully!${NC}"
    echo -e "${BRIGHT_BLACK}Press Enter to return to menu...${NC}"
    read
    show_menu
}

# Start the menu
show_menu 