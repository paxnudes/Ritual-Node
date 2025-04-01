#!/bin/bash

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
NC="\033[0m" # No Color / Reset

echo -e "${GREEN}====== RITUAL NODE FORGE DEPENDENCIES FIX ======${NC}"

# Get repository path
echo -e "${YELLOW}Enter the path to your infernet-container-starter directory (default: ~/infernet-container-starter):${NC}"
read REPO_PATH
REPO_PATH=${REPO_PATH:-~/infernet-container-starter}

if [ ! -d "$REPO_PATH" ]; then
    echo -e "${RED}Directory not found: $REPO_PATH${NC}"
    echo -e "${YELLOW}Would you like to create it and clone the repository? (y/n)${NC}"
    read CREATE_REPO
    if [[ "$CREATE_REPO" =~ ^[Yy]$ ]]; then
        mkdir -p "$REPO_PATH"
        cd "$REPO_PATH/.."
        rm -rf "$(basename "$REPO_PATH")"
        git clone https://github.com/ritual-net/infernet-container-starter "$(basename "$REPO_PATH")"
    else
        echo -e "${RED}Exiting...${NC}"
        exit 1
    fi
fi

cd "$REPO_PATH"

# Check for foundry
echo -e "${YELLOW}Checking for Foundry...${NC}"
if ! command -v foundryup &> /dev/null; then
    echo -e "${YELLOW}Foundry not found. Installing...${NC}"
    curl -L https://foundry.paradigm.xyz | bash
    source ~/.bashrc
    ~/.foundry/bin/foundryup
    FORGE_CMD="$HOME/.foundry/bin/forge"
else
    echo -e "${GREEN}Foundry found!${NC}"
    FORGE_CMD="forge"
fi

# Create contracts directory structure if it doesn't exist
echo -e "${YELLOW}Setting up contracts directory...${NC}"
mkdir -p projects/hello-world/contracts/script
mkdir -p projects/hello-world/contracts/src

# Fix forge dependencies
echo -e "${YELLOW}Fixing forge dependencies...${NC}"
cd projects/hello-world/contracts

echo -e "${YELLOW}Initializing git repository for forge dependencies...${NC}"
# Clean up existing broken repos
rm -rf lib

# Initialize a fresh git repo
git init

echo -e "${YELLOW}Installing forge-std...${NC}"
$FORGE_CMD install --no-commit foundry-rs/forge-std

echo -e "${YELLOW}Installing infernet-sdk...${NC}"
$FORGE_CMD install --no-commit ritual-net/infernet-sdk

echo -e "${GREEN}Dependencies have been fixed!${NC}"
cd "$REPO_PATH"

echo -e "${YELLOW}Would you like to update the Docker image version to latest? (y/n)${NC}"
read UPDATE_DOCKER
if [[ "$UPDATE_DOCKER" =~ ^[Yy]$ ]]; then
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
    echo -e "${GREEN}Docker compose file updated!${NC}"
fi

echo -e "${YELLOW}Would you like to restart the Docker containers now? (y/n)${NC}"
read RESTART_DOCKER
if [[ "$RESTART_DOCKER" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Stopping containers...${NC}"
    cd "$REPO_PATH"
    if [ -f "Makefile" ]; then
        make stop-container
    else
        cd deploy
        docker-compose down
        cd ..
    fi
    
    echo -e "${YELLOW}Starting containers...${NC}"
    if [ -f "Makefile" ]; then
        make deploy-container
    else
        cd deploy
        docker-compose up -d
        cd ..
    fi
    
    echo -e "${GREEN}Containers restarted!${NC}"
fi

echo -e "${GREEN}====== FIX COMPLETE ======${NC}"
echo -e "${YELLOW}You should now be able to deploy contracts using:${NC}"
echo -e "${YELLOW}cd $REPO_PATH && make deploy-contracts${NC}" 