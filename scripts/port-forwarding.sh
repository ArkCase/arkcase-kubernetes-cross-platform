#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory
scriptDir=$(dirname "$(realpath "$0")")
lockFile="$scriptDir/port-forwarding.lock"

# Define the services and their respective ports to forward
declare -A servicesToForward
servicesToForward=(
    ["core"]="8443 8888"
    ["search"]="8983"
    ["rdbms"]="3306"
    ["messaging"]="61613 61616"
    ["ldap"]="636"
    ["content-main"]="9000 9001"
)

# Function to handle cleanup
cleanup() {
    echo "Cleaning up..."
    rm -f "$lockFile"
    echo "Port forwarding stopped."
}

# Trap any exit signal to ensure cleanup is performed
trap cleanup EXIT

# Write the current PID to the lock file
echo $$ > "$lockFile"

# Get all services in the default namespace (adjust namespace if needed)
servicesJson=$(kubectl get svc -n default -o json)

# Extract the number of services fetched
servicesCount=$(echo "$servicesJson" | jq '.items | length')
echo -e "${GREEN}================================== Services fetched: $servicesCount${NC}"

# Loop through each service and set up port forwarding
for service in $(echo "$servicesJson" | jq -r '.items[].metadata.name'); do
    # Trim any leading or trailing whitespace from the service name
    service=$(echo -e "${service}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    # Check if the service is in the list of services to forward
    if [[ -z "${servicesToForward[$service]}" ]]; then
        continue
    fi

    echo -e "${GREEN}================================== Processing service: $service${NC}"

    # Get the service ports
    ports=$(echo "$servicesJson" | jq -c ".items[] | select(.metadata.name==\"$service\") | .spec.ports[]")
    IFS=' ' read -r -a portsArray <<< "${servicesToForward[$service]}"

    for p1 in "${portsArray[@]}"; do
      # Trim any leading/trailing whitespace from p1
      p1=$(echo "$p1" | tr -d '[:space:]')

      # Iterate through extracted ports
      while IFS= read -r p2; do
        # Trim any leading/trailing whitespace from p2
        p2=$(echo "$p2" | tr -d '[:space:]')

        # Compare ports
        if [ "$p1" == "$p2" ]; then
          # Set local port to be the same as service port
          localPort=$p1

          echo -e "${GREEN}Setting up port forwarding for service $service on local port $localPort to service port $p1${NC}"

          # Start port forwarding in the background
          kubectl port-forward svc/$service ${localPort}:${p1} > /dev/null 2>&1 &
          pid=$!
          if [ $? -eq 0 ]; then
              echo -e "${GREEN}Port forwarding started for service $service on port $localPort (PID $pid)${NC}"
          else
              echo -e "${RED}Failed to start port forwarding for service $service on port $localPort${NC}"
          fi

          break
        fi
      done <<< "$(echo "$ports" | jq -r '.port')"
    done
done

echo -e "${GREEN}================================== Port forwarding setup initiated. Check for active jobs.${NC}"
read -p "Port forwarding started. Press Enter to stop and close the window..."

# Remove the lock file when stopping port forwarding
rm -f "$lockFile" 2>/dev/null
