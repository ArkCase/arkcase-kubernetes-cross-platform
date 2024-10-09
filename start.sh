#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Detect the operating system
OS=""
case "$(uname -s)" in
    Linux*)     OS="Linux";;
    Darwin*)    OS="Mac";;
    CYGWIN*|MINGW*|MSYS*|MINGW32*|MINGW64*) OS="Windows";;
    *)          echo "Unsupported operating system: $(uname -s)"; exit 1;;
esac
echo -e "${YELLOW}Detected OS: ${OS}${NC}"

# Paths to your scripts (adjusted to point to the 'scripts' directory)
scriptDir=$(dirname "$(readlink -f "$0")")/scripts
lockFile="$scriptDir/port-forwarding.lock"

# Function to display the menu
function Show_Menu {
    echo -e "${YELLOW}Select an option:${NC}"
    echo "********* Prepare Development Environment ********* :"
    echo "1. Install Development Tools (Java, Maven, NodeJS, Yarn, etc.)"
    echo ""
    echo "********* Running ArkCase in cluster - Remote Debug (OOTB) ********* :"
    echo "2. Install Environment (Minikube, kubectl, Helm, hyperV)"
    echo "3. Install ArkCase (Start Minikube, install ArkCase using Helm, add host names in \"host\" file)"
    echo "4. Deploy ArkCase (Deploy ArkCase and Config server to Minikube. ArkCase/Config path should be updated in the script)"
    echo ""
    echo "********* Running ArkCase and Config outside the cluster - Local Debug ********* :"
    echo "NOTE: ALL PREVIOUS COMMANDS FROM 1-4 MUST BE FINISHED SUCCESSFULLY FIRST TO BE ABLE TO RUN ANY COMMAND BELOW"
    echo "5. Prepare Local Environment (pull arkcase configuration from cluster, get and install necessary certificates on Windows, etc.)"
    echo "6. Start port forwarding for configured services (services can be found in the script)"
    echo "7. Stop port forwarding for configured services (services can be found in the script)"
    echo ""
    echo "********* Helpers ********* :"
    echo "8. Import certificates"
    echo "9. Delete port forwarding lock file"
    echo "10. Restart Environment (delete Minikube and start again)"
    echo "11. Print IntelliJ Run Configuration Example"
    echo "12. Print hosts in \"host\" file configured on the 127.0.0.1"
    echo "e. Exit"
}

# Function to run a script
function Run_Script {
    scriptPath="$1"

    if [ -f "$scriptPath" ]; then
        echo -e "${GREEN}Running script $scriptPath...${NC}"
        bash "$scriptPath"
        echo -e "${GREEN}Script $scriptPath completed.${NC}"
    else
        echo -e "${RED}Script not found: $scriptPath${NC}"
    fi
}

# Start port forwarding
function Start_PortForwarding {
    if [ -f "$lockFile" ]; then
        echo -e "${RED}Port forwarding is already running.${NC}"
    else
        echo -e "${GREEN}Starting port forwarding for all services...${NC}"

        case "$OS" in
            Linux|Mac)
                # Start port forwarding in the background
                #TODO: Do it for Linux and Mac
                ;;
            Windows)
                # On Windows, start port forwarding in a new Git Bash window
                gitBashPath=$(where bash | grep "Git" | head -n 1)
                if [ -z "$gitBashPath" ]; then
                    echo -e "${RED}Git Bash not found. Please ensure Git Bash is installed and in your PATH.${NC}"
                    return
                fi

                # Convert scriptDir to a Windows-compatible path
                windowsPortForwardingScript=$(cygpath -w "$scriptDir/port-forwarding.sh")

                # Use `start` directly in Git Bash to open a new window
                echo "Executing: start \"Port Forwarding\" \"$gitBashPath\" -c 'bash \"$windowsPortForwardingScript\"'"
                start "Port Forwarding" "$gitBashPath" -c "bash \"$windowsPortForwardingScript\""
                ;;
            *)
                echo -e "${RED}Unsupported operating system: $OS${NC}"
                return
                ;;
        esac

        echo -e "${GREEN}Port forwarding started.${NC}"
    fi
}

# Stop port forwarding
function Stop_PortForwarding {
    if [ -f "$lockFile" ]; then
        pid=$(cat "$lockFile")
        if [ -n "$pid" ]; then
            echo -e "${YELLOW}Stopping port forwarding...${NC}"

            # Attempt to stop the process using the stored PID
            if kill "$pid" 2>/dev/null; then
                rm -f "$lockFile"
                echo -e "${GREEN}Port forwarding stopped.${NC}"
            else
                echo -e "${RED}Failed to stop process with PID $pid. It might not be running.${NC}"
                rm -f "$lockFile"  # Clean up the lock file even if the process is not running
            fi
        else
            echo -e "${RED}No valid PID found in lock file.${NC}"
        fi
    else
        echo -e "${RED}Port forwarding is not currently running.${NC}"
    fi
}

# Delete the port forwarding lock file
function Delete_LockFile {
    # Try to stop any existing running PID
    Stop_PortForwarding
    if [ -f "$lockFile" ]; then
        rm -f "$lockFile"
        echo -e "${GREEN}Lock file deleted.${NC}"
    else
        echo -e "${RED}No lock file found.${NC}"
    fi
}

# Function to print IntelliJ Run Configuration example
function Print_RunConfigurationExample {
    echo -e "\n${GREEN}Example IntelliJ Run Configuration for ArkCase:${NC}"
    echo -e "${CYAN}URL: https://core.default.svc.cluster.local:8843/arkcase/"
    echo "-Djava.net.preferIPv4Stack=true"
    echo "-Duser.timezone=GMT"
    echo "-Djavax.net.ssl.trustStorePassword=password"
    echo "-Djavax.net.ssl.trustStore=\${user.home}/.arkcase/acm/private/arkcase.ts"
    echo "-Dspring.profiles.active=ldap"
    echo "-Dacm.configurationserver.propertyfile=\${user.home}/.arkcase/acm/conf.yml"
    echo "-DJAVA_KEYSTORE=\${user.home}/.arkcase/acm/private/arkcase.ks"
    echo "-DJAVA_KEYSTORE_PASS=AcMd3v\$"
    echo "-DJAVA_TRUSTSTORE=\${user.home}/.arkcase/acm/private/arkcase.ts"
    echo "-DJAVA_TRUSTSTORE_PASS=password"
    echo "-DJAVA_KEYSTORE_TYPE=jks"
    echo "-DJAVA_TRUSTSTORE_TYPE=jks"
    echo -e "${YELLOW}Application Context: arkcase-exploaded.war\n${NC}"
}

# Function to print IntelliJ Run Configuration example
function Print_Hosts {
    echo -e "\n${GREEN}The following host are added to \"host\" file for IP 127.0.0.1 during executing the command number \"3. Install ArkCase\":${NC}"
    echo -e "${CYAN}core"
    echo "messaging"
    echo "rdbms"
    echo "ldap"
    echo "search"
    echo "content-main"
    echo "core.default.svc.cluster.local"
    echo "messaging.default.svc.cluster.local"
    echo "rdbms.default.svc.cluster.local"
    echo "ldap.default.svc.cluster.local"
    echo "search.default.svc.cluster.local"
    echo "content-main.default.svc.cluster.local${NC}"
}

# Exit the script
function Exit_Script {
    rm -f "$lockFile" 2>/dev/null
    echo -e "${GREEN}Exiting.${NC}"
    exit 0
}

# Import certificates
function Import_Certificates {
    if [ -f "$lockFile" ]; then
        Run_Script "$scriptDir/import-certificates.sh"
    else
        echo -e "${RED}Port forwarding must be active to import certificates.${NC}"
    fi
}

function Prepare_Local_Environment {
    # Execute the prepare-local-environment.sh script
    Run_Script "$scriptDir/prepare-local-environment.sh"

    # After pulling the configuration, execute the port forwarding function
    Start_PortForwarding
    sleep 1;

    # After starting the port forwarding, execute the import certificates function
    Import_Certificates
}


# Function to deploy ArkCase
function Invoke_DeployArkCase {
    read -p "Enter package type (all, arkcase, config): " package

    if [ -z "$package" ]; then
        echo -e "${RED}No package type provided. Exiting deployment.${NC}"
        return
    fi

    validPackages=("all" "arkcase" "config")
    valid=false
    for validPackage in "${validPackages[@]}"; do
        if [ "$validPackage" == "$package" ]; then
            valid=true
            break
        fi
    done

    if [ "$valid" == false ]; then
        echo -e "${RED}Invalid package type provided. Possible values: all, arkcase, config.${NC}"
        return
    fi

    # Define the script path
    scriptPath="$scriptDir/deploy-arkcase.sh"

    # Run the deployment script with the selected package argument
    if [ -f "$scriptPath" ]; then
        echo -e "${GREEN}Running script $scriptPath with --package $package...${NC}"
        bash "$scriptPath" --package "$package"
        echo -e "${GREEN}Deployment completed successfully.${NC}"
    else
        echo -e "${RED}Script not found: $scriptPath${NC}"
    fi
}

# Main loop to display the menu and handle user input
while true; do
    Show_Menu
    read -p "Enter your choice (1-11), 'e' for exit: " choice

    case $choice in
        1) Run_Script "$scriptDir/install-dev-tools.sh" ;;
        2) Run_Script "$scriptDir/install-environment.sh" ;;
        3) Run_Script "$scriptDir/install-arkcase.sh" ;;
        4) Invoke_DeployArkCase ;;
        5) Prepare_Local_Environment ;;
        6) Start_PortForwarding ;;
        7) Stop_PortForwarding ;;
        8) Import_Certificates ;;
        9) Delete_LockFile ;;
        10) Run_Script "$scriptDir/restart-arkcase.sh" ;;
        11) Print_RunConfigurationExample ;;
        12) Print_Hosts ;;
        e) Exit_Script ;;
        *) echo -e "${RED}Invalid choice. Please select a number between 1 and 11 or 'e' for exit.${NC}" ;;
    esac
done
