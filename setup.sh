#!/bin/bash

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RITUAL NODE INSTALLER v1.0.0
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Terminal colors and formatting
BOLD="\033[1m"
DIM="\033[2m"
UNDERLINE="\033[4m"
BLINK="\033[5m"
REVERSE="\033[7m"
HIDDEN="\033[8m"
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
BG_BLACK="\033[40m"
BG_RED="\033[41m"
BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
BG_BLUE="\033[44m"
BG_MAGENTA="\033[45m"
BG_CYAN="\033[46m"
BG_WHITE="\033[47m"
NC="\033[0m" # No Color / Reset

# ASCII Art Header
display_header() {
    clear
    echo -e "${BOLD}${BRIGHT_MAGENTA}"
    echo -e "╭───────────────────────────────────────────────────╮"
    echo -e "│                                                   │"
    echo -e "│  ██████╗  ██╗████████╗██╗   ██╗ █████╗ ██╗        │"
    echo -e "│  ██╔══██╗ ██║╚══██╔══╝██║   ██║██╔══██╗██║        │"
    echo -e "│  ██████╔╝ ██║   ██║   ██║   ██║███████║██║        │"
    echo -e "│  ██╔══██╗ ██║   ██║   ██║   ██║██╔══██║██║        │"
    echo -e "│  ██║  ██║ ██║   ██║   ╚██████╔╝██║  ██║███████╗   │"
    echo -e "│  ╚═╝  ╚═╝ ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝   │"
    echo -e "│                                                   │"
    echo -e "╰───────────────────────────────────────────────────╯${NC}"
    echo
}

# Progress bar
progress_bar() {
    local duration=$1
    local steps=20
    local sleep_time=$(bc <<< "scale=2; $duration/$steps")
    
    echo -ne "${BRIGHT_BLACK}[${NC}"
    for ((i=0; i<steps; i++)); do
        echo -ne "${BRIGHT_CYAN}▓${NC}"
        sleep $sleep_time
    done
    echo -e "${BRIGHT_BLACK}]${NC} ${GREEN}Complete${NC}"
}

# Section headers
section() {
    echo -e "\n${BOLD}${BG_BLUE}${WHITE} $1 ${NC}"
    echo -e "${BRIGHT_BLACK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Status messages
status_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

status_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

status_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

status_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Command execution with logging and error handling
execute_command() {
    local cmd="$1"
    local description="$2"
    local max_retries=3
    local retry_count=0
    
    echo -e "${BRIGHT_BLACK}$ ${cmd}${NC}"
    
    while [ $retry_count -lt $max_retries ]; do
        if eval "$cmd" > /tmp/cmd_output.log 2>&1; then
            status_success "$description"
            if [ -n "$3" ] && [ "$3" == "show_output" ]; then
                echo -e "${DIM}$(cat /tmp/cmd_output.log)${NC}"
            fi
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                status_warning "$description failed, retrying ($retry_count/$max_retries)..."
                sleep 2
            else
                status_error "$description failed after $max_retries attempts"
                echo -e "${DIM}$(cat /tmp/cmd_output.log)${NC}"
                
                # For critical commands, offer to abort
                if [ -n "$4" ] && [ "$4" == "critical" ]; then
                    echo -e "${RED}This error is critical. Would you like to abort the installation? (y/n)${NC}"
                    read -r abort_choice
                    if [[ "$abort_choice" =~ ^[Yy]$ ]]; then
                        echo -e "${RED}Installation aborted.${NC}"
                        exit 1
                    fi
                fi
                
                return 1
            fi
        fi
    done
}

# Get private key from user with secure handling
get_private_key() {
    echo -e "${YELLOW}Please enter your private key (with 0x prefix):${NC}"
    read -s PRIVATE_KEY
    
    if [[ ! "$PRIVATE_KEY" =~ ^0x[a-fA-F0-9]{64}$ ]]; then
        status_error "Invalid private key format. Must start with 0x followed by 64 hex characters."
        get_private_key
    else
        # Generate a secure random salt
        SALT=$(openssl rand -hex 8)
        
        # Create a secure directory for key storage with restricted permissions
        mkdir -p ~/.ritual-secure
        chmod 700 ~/.ritual-secure
        
        # Encrypt the private key with a simple reversible encryption using the salt
        # This is more secure than plain text but still requires proper system security
        ENCRYPTED_KEY=$(echo "$PRIVATE_KEY" | openssl enc -aes-256-cbc -a -salt -pass pass:"$SALT" 2>/dev/null)
        
        # Store the encrypted key and salt
        echo "$ENCRYPTED_KEY" > ~/.ritual-secure/key.enc
        echo "$SALT" > ~/.ritual-secure/salt
        
        # Set strict permissions
        chmod 600 ~/.ritual-secure/key.enc
        chmod 600 ~/.ritual-secure/salt
        
        # Set an environment variable for use in this session
        export RITUAL_PRIVATE_KEY="$PRIVATE_KEY"
        
        status_success "Private key securely stored"
    fi
}

# Function to get the private key when needed
get_stored_private_key() {
    if [ -n "$RITUAL_PRIVATE_KEY" ]; then
        # Use the key from environment if available
        echo "$RITUAL_PRIVATE_KEY"
    elif [ -f ~/.ritual-secure/key.enc ] && [ -f ~/.ritual-secure/salt ]; then
        # Decrypt the stored key
        SALT=$(cat ~/.ritual-secure/salt)
        ENCRYPTED_KEY=$(cat ~/.ritual-secure/key.enc)
        echo "$ENCRYPTED_KEY" | openssl enc -aes-256-cbc -d -a -salt -pass pass:"$SALT" 2>/dev/null
    else
        status_error "No stored private key found"
        return 1
    fi
}

# Main installation function
install_ritual_node() {
    display_header
    
    # Check for prerequisites
    section "SYSTEM VALIDATION"
    
    # Check internet connectivity with multiple fallbacks
    status_info "Checking internet connectivity"
    if ping -c 1 google.com > /dev/null 2>&1 || ping -c 1 cloudflare.com > /dev/null 2>&1 || ping -c 1 github.com > /dev/null 2>&1 || curl -s --connect-timeout 5 https://api.github.com > /dev/null 2>&1; then
        status_success "Internet connection is available"
    else
        status_warning "Internet connectivity check failed"
        echo -e "${YELLOW}Would you like to continue anyway? This is not recommended unless you're sure you have internet access. (y/n)${NC}"
        read -r continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            status_error "Installation aborted due to no internet connection detected."
            echo -e "${YELLOW}Please check your connection and try again.${NC}"
            exit 1
        else
            status_warning "Proceeding without confirmed internet connectivity - this may cause errors later"
        fi
    fi
    
    # Check disk space
    status_info "Checking available disk space"
    AVAILABLE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$AVAILABLE_SPACE" -lt 10 ]; then
        status_warning "Low disk space detected: ${AVAILABLE_SPACE}GB available"
        echo -e "${YELLOW}At least 10GB of free space is recommended. Continue anyway? (y/n)${NC}"
        read -r disk_choice
        if [[ ! "$disk_choice" =~ ^[Yy]$ ]]; then
            echo -e "${RED}Installation aborted.${NC}"
            exit 1
        fi
    else
        status_success "Disk space is sufficient: ${AVAILABLE_SPACE}GB available"
    fi
    
    # Get private key
    get_private_key
    
    # Create a backup of configuration
    if [ -f ~/.ritual-secure/key.enc ]; then
        mkdir -p ~/.ritual-secure/backups
        BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")
        cp ~/.ritual-secure/key.enc ~/.ritual-secure/backups/key.enc.$BACKUP_DATE
        cp ~/.ritual-secure/salt ~/.ritual-secure/backups/salt.$BACKUP_DATE
        status_success "Created backup of existing configuration"
    fi
    
    section "SYSTEM PREPARATION"
    
    status_info "Updating system packages"
    execute_command "sudo apt update && sudo apt upgrade -y" "System update"
    
    status_info "Installing dependencies"
    execute_command "sudo apt -qy install curl git jq lz4 build-essential screen" "Dependencies installation"
    
    section "DOCKER INSTALLATION"
    
    status_info "Setting up Docker repository"
    execute_command "sudo apt-get update" "APT update"
    execute_command "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release" "Docker prerequisites"
    execute_command "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg" "Docker GPG key"
    execute_command "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null" "Docker repository"
    
    status_info "Installing Docker"
    execute_command "sudo apt-get update" "APT update"
    execute_command "sudo apt-get install -y docker-ce docker-ce-cli containerd.io" "Docker installation" "" "critical"
    execute_command "sudo docker run hello-world" "Docker test"
    
    # Validate Docker installation
    validate_docker
    
    status_info "Installing Docker Compose"
    execute_command "sudo curl -L \"https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose" "Docker Compose download"
    execute_command "sudo chmod +x /usr/local/bin/docker-compose" "Docker Compose permissions"
    
    execute_command "mkdir -p $HOME/.docker/cli-plugins" "Docker plugins directory"
    execute_command "curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o $HOME/.docker/cli-plugins/docker-compose" "Docker Compose plugin"
    execute_command "chmod +x $HOME/.docker/cli-plugins/docker-compose" "Docker Compose plugin permissions"
    
    status_info "Verifying Docker Compose installation"
    execute_command "docker compose version" "Docker Compose version" "show_output"
    
    status_info "Adding user to Docker group"
    execute_command "sudo usermod -aG docker $USER" "User permissions"
    
    section "NODE SETUP"
    
    status_info "Cloning repository"
    execute_command "git clone https://github.com/ritual-net/infernet-container-starter" "Repository clone"
    execute_command "cd infernet-container-starter" "Change directory"
    
    status_info "Setting up configuration files"
    
    # Get the stored key for configuration
    PRIVATE_KEY=$(get_stored_private_key)
    
    # Create config.json with provided private key
    cat > ~/infernet-container-starter/deploy/config.json << EOL
{
    "log_path": "infernet_node.log",
    "server": {
        "port": 4000,
        "rate_limit": {
            "num_requests": 100,
            "period": 100
        }
    },
    "chain": {
        "enabled": true,
        "trail_head_blocks": 3,
        "rpc_url": "https://mainnet.base.org/",
        "registry_address": "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170",
        "wallet": {
          "max_gas_limit": 4000000,
          "private_key": "${PRIVATE_KEY}",
          "allowed_sim_errors": []
        },
        "snapshot_sync": {
          "sleep": 3,
          "batch_size": 10000,
          "starting_sub_id": 180000,
          "sync_period": 30
        }
    },
    "startup_wait": 1.0,
    "redis": {
        "host": "redis",
        "port": 6379
    },
    "forward_stats": true,
    "containers": [
        {
            "id": "hello-world",
            "image": "ritualnetwork/hello-world-infernet:latest",
            "external": true,
            "port": "3000",
            "allowed_delegate_addresses": [],
            "allowed_addresses": [],
            "allowed_ips": [],
            "command": "--bind=0.0.0.0:3000 --workers=2",
            "env": {},
            "volumes": [],
            "accepted_payments": {},
            "generates_proofs": false
        }
    ]
}
EOL
    status_success "Created deploy/config.json"
    
    # Set secure permissions on config files
    execute_command "chmod 600 ~/infernet-container-starter/deploy/config.json" "Set secure config permissions"
    
    # Copy the same content to the container config
    execute_command "cp ~/infernet-container-starter/deploy/config.json ~/infernet-container-starter/projects/hello-world/container/config.json" "Container config"
    execute_command "chmod 600 ~/infernet-container-starter/projects/hello-world/container/config.json" "Set secure container config permissions"
    
    # Update the Deploy.s.sol
    cat > ~/infernet-container-starter/projects/hello-world/contracts/script/Deploy.s.sol << EOL
// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {SaysGM} from "../src/SaysGM.sol";

contract Deploy is Script {
    function run() public {
        // Setup wallet
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Log address
        address deployerAddress = vm.addr(deployerPrivateKey);
        console2.log("Loaded deployer: ", deployerAddress);

        address registry = 0x3B1554f346DFe5c482Bb4BA31b880c1C18412170;
        // Create consumer
        SaysGM saysGm = new SaysGM(registry);
        console2.log("Deployed SaysHello: ", address(saysGm));

        // Execute
        vm.stopBroadcast();
        vm.broadcast();
    }
}
EOL
    status_success "Updated Deploy.s.sol"
    
    # Update the Makefile
    cat > ~/infernet-container-starter/projects/hello-world/contracts/Makefile << EOL
# phony targets are targets that don't actually create a file
.phony: deploy

# Get private key from secure storage
include ~/.ritual_node_env
PRIVATE_KEY := $(shell bash -c 'if [ -f ~/.ritual-secure/key.enc ] && [ -f ~/.ritual-secure/salt ]; then SALT=$$(cat ~/.ritual-secure/salt); ENCRYPTED_KEY=$$(cat ~/.ritual-secure/key.enc); echo "$${ENCRYPTED_KEY}" | openssl enc -aes-256-cbc -d -a -salt -pass pass:"$${SALT}" 2>/dev/null; else echo "PRIVATE_KEY_NOT_FOUND"; fi')
RPC_URL := https://mainnet.base.org/

# deploying the contract
deploy:
	@PRIVATE_KEY=$(PRIVATE_KEY) forge script script/Deploy.s.sol:Deploy --broadcast --rpc-url $(RPC_URL)

# calling sayGM()
call-contract:
	@PRIVATE_KEY=$(PRIVATE_KEY) forge script script/CallContract.s.sol:CallContract --broadcast --rpc-url $(RPC_URL)
EOL
    status_success "Updated Makefile with secure key handling"
    
    # Update Docker Compose to use v1.4.0 and rename containers
    execute_command "sed -i 's/ritualnetwork\\/infernet-node:latest/ritualnetwork\\/infernet-node:v1.4.0/g' ~/infernet-container-starter/deploy/docker-compose.yaml" "Update node version to 1.4.0"
    execute_command "sed -i '/image: ritualnetwork\\/infernet-node:v1.4.0/a\\    container_name: ritual-node' ~/infernet-container-starter/deploy/docker-compose.yaml" "Set container name"
    execute_command "sed -i '/image: redis/a\\    container_name: ritual-redis' ~/infernet-container-starter/deploy/docker-compose.yaml" "Set Redis container name"
    execute_command "sed -i '/image: ritualnetwork\\/hello-world-infernet/a\\    container_name: ritual-hello-world' ~/infernet-container-starter/deploy/docker-compose.yaml" "Set Hello World container name"
    
    # Store installation path in environment file for consistency
    execute_command "echo 'RITUAL_NODE_PATH=~/infernet-container-starter' > ~/.ritual_node_env" "Save installation path"
    execute_command "chmod +x ~/.ritual_node_env" "Make environment file executable"
    
    section "FOUNDRY INSTALLATION"
    
    status_info "Installing Foundry"
    execute_command "mkdir -p ~/foundry" "Create Foundry directory"
    execute_command "curl -L https://foundry.paradigm.xyz | bash" "Download Foundry" "show_output"
    execute_command "source ~/.bashrc" "Reload shell"
    execute_command "foundryup" "Install Foundry" "show_output"
    
    section "INSTALLING DEPENDENCIES"
    
    status_info "Installing required libraries"
    execute_command "cd ~/infernet-container-starter/projects/hello-world/contracts && forge install --no-commit foundry-rs/forge-std" "Install forge-std" "show_output"
    execute_command "cd ~/infernet-container-starter/projects/hello-world/contracts && forge install --no-commit ritual-net/infernet-sdk" "Install infernet-sdk" "show_output"
    
    section "DEPLOYING NODE"
    
    status_info "Starting Docker containers"
    execute_command "cd ~/infernet-container-starter && project=hello-world make deploy-container" "Deploy container" "show_output"
    
    status_info "Waiting for node to initialize"
    progress_bar 5
    
    section "DEPLOYING CONSUMER CONTRACT"
    
    status_info "Deploying contract"
    CONTRACT_RESULT=$(cd ~/infernet-container-starter && project=hello-world make deploy-contracts 2>&1)
    echo "$CONTRACT_RESULT"
    
    # Extract contract address
    CONTRACT_ADDRESS=$(echo "$CONTRACT_RESULT" | grep -oP 'Deployed SaysHello: \K0x[a-fA-F0-9]+')
    
    if [ -n "$CONTRACT_ADDRESS" ]; then
        status_success "Contract deployed at: ${BRIGHT_GREEN}$CONTRACT_ADDRESS${NC}"
        
        # Update CallContract.s.sol with the new contract address
        sed -i "s/SaysGM saysGm = SaysGM(.*);/SaysGM saysGm = SaysGM($CONTRACT_ADDRESS);/" ~/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol
        
        section "TESTING NODE"
        
        status_info "Calling contract"
        execute_command "cd ~/infernet-container-starter && project=hello-world make call-contract" "Call contract" "show_output"
        
        section "COMPLETION"
        
        echo -e "\n${BOLD}${BG_GREEN}${WHITE} RITUAL NODE SETUP COMPLETE ${NC}\n"
        echo -e "${BRIGHT_CYAN}Your node is now running!${NC}"
        echo -e "\n${WHITE}Contract Address: ${BRIGHT_GREEN}$CONTRACT_ADDRESS${NC}"
        echo -e "${WHITE}Node Interface: ${BRIGHT_GREEN}http://localhost:4000${NC}"
        
        echo -e "\n${BRIGHT_BLACK}Use the following commands to manage your node:${NC}"
        echo -e "${BRIGHT_BLACK}• ${BRIGHT_WHITE}docker compose -f ~/infernet-container-starter/deploy/docker-compose.yaml down${NC} - Stop the node"
        echo -e "${BRIGHT_BLACK}• ${BRIGHT_WHITE}docker compose -f ~/infernet-container-starter/deploy/docker-compose.yaml up${NC} - Start the node"
        echo -e "${BRIGHT_BLACK}• ${BRIGHT_WHITE}docker compose -f ~/infernet-container-starter/deploy/docker-compose.yaml logs -f${NC} - View logs"
    else
        status_error "Could not extract contract address. Deployment may have failed."
    fi
}

# Function to validate docker installation
validate_docker() {
    if ! docker --version > /dev/null 2>&1; then
        status_error "Docker installation failed"
        echo -e "${RED}Unable to proceed without Docker. Please check the error log and try again.${NC}"
        exit 1
    else
        status_success "Docker installed successfully"
    fi
}

# Run the installation
install_ritual_node 