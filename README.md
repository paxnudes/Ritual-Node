# Ritual Node - Management System

![Ritual Node](https://img.shields.io/badge/Ritual-Node-magenta)
![Shell Script](https://img.shields.io/badge/Shell_Script-100%25-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)

An elegant management system for deploying, monitoring, and managing Ritual Nodes with encrypted key storage and professional terminal interfaces.

A comprehensive toolset for deploying, managing, and monitoring a Ritual Node with an elegant terminal interface.

## Overview

This system provides a streamlined, one-click approach to deploying and managing a Ritual Node. It features elegant terminal interfaces, real-time monitoring, and simplified management commands.

## Features

- **Elegant Terminal UI**: Advanced terminal interfaces with clean styling
- **One-Click Deployment**: Streamlined node setup process
- **Real-Time Monitoring**: System resource and node health monitoring
- **Contract Management**: Deploy and interact with consumer contracts
- **Simplified Commands**: Easy-to-use menu system for all operations
- **Enhanced Security**: Encrypted private key storage with automatic backups

## Requirements

- Ubuntu 22.04 or newer
- Sudo privileges
- Internet connection
- Private key for Base network
- OpenSSL for key encryption

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/paxnudes/Ritual-Node.git
   cd Ritual-Node
   ```

2. Run the main CLI interface:
   ```
   ./Ritual-Node-cli.sh
   ```

## Usage

The main CLI provides the following options:

1. **Initialize Node** - Complete setup of the Ritual Node
2. **Monitor Node** - Real-time monitoring dashboard
3. **Start Node** - Start all node containers
4. **Stop Node** - Stop all node containers
5. **View Logs** - Show container logs
6. **Deploy Contract** - Deploy consumer contract
7. **Call Contract** - Execute sayGM() function
8. **System Information** - View resource usage
9. **Check Node Status** - Quick health check
U. **Uninstall Node** - Remove containers and configuration
0. **Exit** - Quit the application

## Node Configuration

The node is configured with:

- Base mainnet RPC URL
- Registry address: 0x3B1554f346DFe5c482Bb4BA31b880c1C18412170
- Node version v1.4.0
- Hello World container

## Security Features

- Private key is stored encrypted with AES-256-CBC
- Restricted file permissions (600) for all sensitive files
- Secure directory with 700 permissions
- Automatic key backups during updates and uninstallation
- No plaintext keys in configuration files
- Environment variables for runtime key usage

## Backup and Recovery

The system automatically creates backups of your encrypted private key:

- During initialization if a previous key exists
- Before uninstallation (when selecting to not keep your key)

Backups are stored in `~/.ritual-secure/backups/` with timestamps.

## Troubleshooting

If you encounter issues:

1. Check container logs using option 5
2. Verify network connectivity
3. Ensure Docker is installed and running properly
4. Check system resources with option 8

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Ritual Network for node protocols
- Docker for containerization
- Foundry for smart contract tooling 