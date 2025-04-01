#!/bin/bash

# Source installation path if available
if [ -f ~/.ritual_node_env ]; then
    source ~/.ritual_node_env
else
    # Default path if environment file doesn't exist
    RITUAL_NODE_PATH=~/infernet-container-starter
fi

# Colors and formatting
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
WHITE="\033[37m"
BRIGHT_BLACK="\033[90m"
BRIGHT_CYAN="\033[96m"
BRIGHT_GREEN="\033[92m"
BRIGHT_RED="\033[91m"
BRIGHT_WHITE="\033[97m"
BRIGHT_YELLOW="\033[93m"
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
    echo "│               MONITORING SYSTEM                   │"
    echo "│                                                   │"
    echo "╰───────────────────────────────────────────────────╯"
    echo -e "${NC}"
}

# Function to display section headers
section() {
    echo -e "\n${BOLD}${BLUE}$1${NC}"
    echo -e "${BRIGHT_BLACK}──────────────────────────────────────────────────────────────${NC}"
}

# Function to check if a container is running
check_container() {
    local container=$1
    local status=$(docker ps --filter name=$container --format "{{.Status}}" 2>/dev/null)
    
    if [ -n "$status" ]; then
        echo -e "  ${BRIGHT_GREEN}✓${NC} ${WHITE}$container${NC}: ${BRIGHT_GREEN}Running${NC} - $status"
        return 0
    else
        local stopped=$(docker ps -a --filter name=$container --format "{{.Status}}" 2>/dev/null)
        if [ -n "$stopped" ]; then
            echo -e "  ${BRIGHT_RED}✗${NC} ${WHITE}$container${NC}: ${BRIGHT_RED}Stopped${NC} - $stopped"
        else
            echo -e "  ${BRIGHT_RED}✗${NC} ${WHITE}$container${NC}: ${BRIGHT_RED}Not found${NC}"
        fi
        return 1
    fi
}

# Function to get node metrics
get_node_metrics() {
    local api_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/health 2>/dev/null)
    
    if [ "$api_status" == "200" ]; then
        echo -e "  ${BRIGHT_GREEN}✓${NC} ${WHITE}API Status${NC}: ${BRIGHT_GREEN}Online${NC} (200 OK)"
        
        # Get metrics data
        local metrics=$(curl -s http://localhost:4000/metrics 2>/dev/null)
        if [ -n "$metrics" ]; then
            # Extract metrics using grep and awk
            local uptime=$(echo "$metrics" | grep "uptime" | awk '{print $2}')
            local requests=$(echo "$metrics" | grep "request_count" | awk '{print $2}')
            local containers=$(echo "$metrics" | grep "container_count" | awk '{print $2}')
            
            echo -e "  ${BRIGHT_WHITE}•${NC} ${WHITE}Uptime${NC}: ${BRIGHT_YELLOW}$uptime${NC} seconds"
            echo -e "  ${BRIGHT_WHITE}•${NC} ${WHITE}Total Requests${NC}: ${BRIGHT_YELLOW}$requests${NC}"
            echo -e "  ${BRIGHT_WHITE}•${NC} ${WHITE}Active Containers${NC}: ${BRIGHT_YELLOW}$containers${NC}"
        else
            echo -e "  ${BRIGHT_YELLOW}!${NC} ${WHITE}Metrics${NC}: ${BRIGHT_YELLOW}Not available${NC}"
        fi
    else
        echo -e "  ${BRIGHT_RED}✗${NC} ${WHITE}API Status${NC}: ${BRIGHT_RED}Offline${NC} ($api_status)"
    fi
}

# Main monitoring function
monitor_node() {
    display_header
    
    section "CONTAINER STATUS"
    check_container "ritual-node"
    check_container "ritual-redis"
    check_container "ritual-hello-world"
    
    section "NODE HEALTH"
    get_node_metrics
    
    section "CONTRACT INFORMATION"
    if [ -f ~/.ritual_contract ]; then
        contract=$(cat ~/.ritual_contract)
        echo -e "  ${BRIGHT_WHITE}•${NC} ${WHITE}Contract Address${NC}: ${BRIGHT_CYAN}$contract${NC}"
        echo -e "  ${BRIGHT_WHITE}•${NC} ${WHITE}Explorer${NC}: ${BRIGHT_CYAN}https://basescan.org/address/$contract${NC}"
    else
        echo -e "  ${BRIGHT_YELLOW}!${NC} ${WHITE}Contract information not available${NC}"
        echo -e "  ${BRIGHT_BLACK}   Run deployment process to generate contract information${NC}"
    fi
    
    section "SYSTEM RESOURCES"
    # Get system metrics
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    memory=$(free -m | awk 'NR==2{printf "%.1f/%.1f GB (%.1f%%)", $3/1024, $2/1024, $3*100/$2}')
    disk=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')
    
    echo -e "  ${BRIGHT_WHITE}•${NC} ${WHITE}CPU Usage${NC}: ${BRIGHT_YELLOW}$cpu_usage%${NC}"
    echo -e "  ${BRIGHT_WHITE}•${NC} ${WHITE}Memory${NC}: ${BRIGHT_YELLOW}$memory${NC}"
    echo -e "  ${BRIGHT_WHITE}•${NC} ${WHITE}Disk${NC}: ${BRIGHT_YELLOW}$disk${NC}"
    
    section "NODE MANAGEMENT"
    echo -e "  ${BRIGHT_WHITE}1.${NC} ${CYAN}Start Node${NC}    - docker compose -f $RITUAL_NODE_PATH/deploy/docker-compose.yaml up -d"
    echo -e "  ${BRIGHT_WHITE}2.${NC} ${CYAN}Stop Node${NC}     - docker compose -f $RITUAL_NODE_PATH/deploy/docker-compose.yaml down"
    echo -e "  ${BRIGHT_WHITE}3.${NC} ${CYAN}View Logs${NC}     - docker compose -f $RITUAL_NODE_PATH/deploy/docker-compose.yaml logs -f"
    echo -e "  ${BRIGHT_WHITE}4.${NC} ${CYAN}Restart Node${NC}  - docker compose -f $RITUAL_NODE_PATH/deploy/docker-compose.yaml restart"
    
    echo -e "\n${BRIGHT_BLACK}Press Ctrl+C to exit or wait for next refresh (10s)${NC}"
}

# Save contract address if provided as argument
if [ -n "$1" ]; then
    echo "$1" > ~/.ritual_contract
fi

# Run monitoring in a loop
while true; do
    monitor_node
    sleep 10
done 