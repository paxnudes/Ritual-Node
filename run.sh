#!/bin/bash

# Colors for output
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
NC="\033[0m" # No Color / Reset

echo -e "${GREEN}====== RITUAL INFERNET NODE ONE-CLICK SETUP ======${NC}"

# Update system packages
echo -e "${YELLOW}Step 1: Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt -qy install curl git jq lz4 build-essential screen

# Install Docker
echo -e "${YELLOW}Step 2: Installing Docker...${NC}"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo docker run hello-world

# Docker Compose
echo -e "${YELLOW}Step 3: Installing Docker Compose...${NC}"
sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
sudo usermod -aG docker $USER
echo -e "${YELLOW}NOTE: You might need to log out and log back in for Docker group permissions to take effect${NC}"

# Clone repository
echo -e "${YELLOW}Step 4: Setting up infernet-container-starter...${NC}"
cd ~
git clone https://github.com/ritual-net/infernet-container-starter
cd infernet-container-starter

# Get private key
echo -e "${YELLOW}Step 5: Please enter your private key with 0x prefix:${NC}"
read -s PRIVATE_KEY

if [[ ! "$PRIVATE_KEY" =~ ^0x[a-fA-F0-9]{64}$ ]]; then
    echo -e "${RED}Invalid private key format. Must start with 0x followed by 64 hex characters.${NC}"
    exit 1
fi

# Create config files
echo -e "${YELLOW}Step 6: Creating configuration files...${NC}"
mkdir -p deploy
cat > deploy/config.json << EOL
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

chmod 600 deploy/config.json
mkdir -p projects/hello-world/container
cp deploy/config.json projects/hello-world/container/config.json

# Update Docker Compose to use latest image
cat > deploy/docker-compose.yaml << EOL
version: "3.8"

services:
  node:
    image: ritualnetwork/infernet-node:latest
    container_name: ritual-node
    restart: always
    ports:
      - "4000:4000"
    depends_on:
      - redis
    volumes:
      - ./config.json:/app/config.json
    networks:
      - infernet

  redis:
    image: redis:7.0.12-alpine
    container_name: ritual-redis
    restart: always
    networks:
      - infernet

  hello-world:
    image: ritualnetwork/hello-world-infernet:latest
    container_name: ritual-hello-world
    restart: always
    networks:
      - infernet

networks:
  infernet:
    driver: bridge
EOL

# Install Foundry
echo -e "${YELLOW}Step 7: Installing Foundry...${NC}"
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
~/.foundry/bin/foundryup

# Setup contracts directory properly
echo -e "${YELLOW}Step 8: Setting up contracts...${NC}"
mkdir -p projects/hello-world/contracts/script
mkdir -p projects/hello-world/contracts/src

# Create Deploy.s.sol
cat > projects/hello-world/contracts/script/Deploy.s.sol << EOL
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

# Create SaysGM.sol
cat > projects/hello-world/contracts/src/SaysGM.sol << EOL
// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.13;

import {Infernet} from "infernet-sdk/Infernet.sol";
import {InfernetConsumer} from "infernet-sdk/InfernetConsumer.sol";

contract SaysGM is InfernetConsumer {
    // Emitted when sayGM is called
    event GMReceived(bytes data);

    // Constructor
    constructor(address registry) InfernetConsumer(registry) {}

    // Say GM to someone
    function sayGM(
        address container,
        string calldata name
    ) external returns (bytes memory) {
        bytes memory encoded = abi.encode(name);
        bytes memory response = _callInfernet(container, encoded);
        emit GMReceived(response);
        return response;
    }
}
EOL

# Create CallContract.s.sol
cat > projects/hello-world/contracts/script/CallContract.s.sol << EOL
// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {SaysGM} from "../src/SaysGM.sol";

contract CallContract is Script {
    function run() public {
        // Setup wallet
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Log address
        address deployerAddress = vm.addr(deployerPrivateKey);
        console2.log("Loaded deployer: ", deployerAddress);

        // Call contract
        // This will be updated with the actual contract address after deployment
        SaysGM saysGm = SaysGM(0x0000000000000000000000000000000000000000);
        console2.log("Calling sayGM...");
        bytes memory res = saysGm.sayGM(0x8ad64fa5a5e1bd7f0eb750e45baf3e0a1499a549, "Ritual");
        console2.log("Response: ", string(res));

        vm.stopBroadcast();
    }
}
EOL

# Create Makefile
cat > projects/hello-world/contracts/Makefile << EOL
# phony targets are targets that don't actually create a file
.phony: deploy

# Private key from environment
PRIVATE_KEY := ${PRIVATE_KEY}
RPC_URL := https://mainnet.base.org/

# deploying the contract
deploy:
	@PRIVATE_KEY=\$(PRIVATE_KEY) forge script script/Deploy.s.sol:Deploy --broadcast --rpc-url \$(RPC_URL)

# calling sayGM()
call-contract:
	@PRIVATE_KEY=\$(PRIVATE_KEY) forge script script/CallContract.s.sol:CallContract --broadcast --rpc-url \$(RPC_URL)
EOL

# Create root Makefile
cat > Makefile << EOL
# Default project
project ?= hello-world

# Deploy container
deploy-container:
	@cd deploy && docker-compose up -d

# Stop container
stop-container:
	@cd deploy && docker-compose down

# Deploy contracts
deploy-contracts:
	@cd projects/\$(project)/contracts && make deploy

# Call contract
call-contract:
	@cd projects/\$(project)/contracts && make call-contract
EOL

# Initialize git for contracts directory and install dependencies
echo -e "${YELLOW}Step 9: Installing dependencies...${NC}"
cd projects/hello-world/contracts
git init
~/.foundry/bin/forge install --no-commit foundry-rs/forge-std
~/.foundry/bin/forge install --no-commit ritual-net/infernet-sdk
cd ~/infernet-container-starter

# Deploy containers
echo -e "${YELLOW}Step 10: Deploying containers...${NC}"
make deploy-container

echo -e "${YELLOW}Step 11: Waiting for node to initialize (15 seconds)...${NC}"
sleep 15

# Deploy contracts
echo -e "${YELLOW}Step 12: Deploying contracts...${NC}"
export PRIVATE_KEY
make deploy-contracts

echo -e "${YELLOW}Step 13: Extracting contract address...${NC}"
CONTRACT_ADDRESS=$(grep -o "Deployed SaysHello: 0x[a-fA-F0-9]\{40\}" ~/.foundry/forge-cache/forge-script-logs/latest.txt | cut -d' ' -f3)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo -e "${RED}Failed to extract contract address.${NC}"
    echo -e "${YELLOW}You'll need to manually update the contract address in CallContract.s.sol${NC}"
else
    echo -e "${GREEN}Contract deployed at: $CONTRACT_ADDRESS${NC}"
    
    # Update CallContract.s.sol with contract address
    sed -i "s/SaysGM saysGm = SaysGM(0x[a-fA-F0-9]\{40\});/SaysGM saysGm = SaysGM($CONTRACT_ADDRESS);/" projects/hello-world/contracts/script/CallContract.s.sol
    
    # Call contract
    echo -e "${YELLOW}Step 14: Calling contract...${NC}"
    export PRIVATE_KEY
    make call-contract
fi

echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}RITUAL INFERNET NODE SETUP COMPLETE!${NC}"
echo -e "${GREEN}Your node is running at: http://localhost:4000${NC}"
if [ ! -z "$CONTRACT_ADDRESS" ]; then
    echo -e "${GREEN}Contract deployed at: $CONTRACT_ADDRESS${NC}"
fi
echo -e "${GREEN}===============================================${NC}"
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "${YELLOW}- View logs: docker logs -f ritual-node${NC}"
echo -e "${YELLOW}- Stop node: cd ~/infernet-container-starter && make stop-container${NC}"
echo -e "${YELLOW}- Start node: cd ~/infernet-container-starter && make deploy-container${NC}" 