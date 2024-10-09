#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Delete the existing Minikube cluster
echo -e "${YELLOW}Deleting existing Minikube cluster...${NC}"
minikube delete

# Run the installation script
scriptDir=$(dirname "$(realpath "$0")")
bash "$scriptDir/install-arkcase.sh"

echo -e "${GREEN}Installation and setup completed successfully.${NC}"
