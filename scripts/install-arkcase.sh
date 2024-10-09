#!/bin/bash

echo "Install ArkCase using Helm"

# Detect the operating system
OS=""
case "$(uname -s)" in
    Linux*)     OS="Linux";;
    Darwin*)    OS="Mac";;
    CYGWIN*|MINGW*|MSYS*|MINGW32*|MINGW64*) OS="Windows";;
    *)          echo "Unsupported operating system: $(uname -s)"; exit 1;;
esac
echo "Detected OS: ${OS}"

hostsFilePath=""
hostsEntry="127.0.0.1 core messaging rdbms ldap search content-main messaging.default.svc.cluster.local rdbms.default.svc.cluster.local ldap.default.svc.cluster.local search.default.svc.cluster.local content-main.default.svc.cluster.local core.default.svc.cluster.local"

if [ "${OS}" == "Windows" ]; then
    hostsFilePath="/c/Windows/System32/drivers/etc/hosts"
else
    hostsFilePath="/etc/hosts"
fi

# Get the directory where the script is located
scriptDir=$(dirname "$(realpath "$0")")
# Go one level up from the script directory
parentDir=$(dirname "$scriptDir")

logsDir="$parentDir/logs"

# Create the logs directory if it doesn't exist
mkdir -p "$logsDir"

# Define log file path inside the logs directory
logPath="$logsDir/install.logs"

# Clear the log file if it already exists, otherwise create a new one
> "$logPath"

# Start logging
exec > >(tee -a "$logPath") 2>&1

# Add Helm Repo
echo 'Add arkcase Helm repo'
if helm repo add arkcase https://arkcase.github.io/ark_helm_charts/; then
    echo 'Helm repo added successfully.'
else
    echo "Failed to add arkcase Helm repo" >&2
    exit 1
fi

# Update Helm Repos
echo 'Update Helm repos'
if helm repo update; then
    echo 'Helm repos updated successfully.'
else
    echo "Failed to update Helm repos" >&2
    exit 1
fi

if [ "${OS}" == "Linux" ] || [ "${OS}" == "Mac" ]; then
    driver="virtualbox"
elif [ "${OS}" == "Windows" ]; then
    driver="hyperv"
else
    echo "Unsupported OS: ${OS}"
    exit 1
fi

echo "Starting Minikube: minikube start --vm=true --driver=$driver --cpus=6 --memory=16000m"
if minikube start --vm=true --driver=$driver --cpus=6 --memory=16000m; then
    echo "Minikube started successfully."
else
    echo "Failed to start Minikube" >&2
    exit 1
fi

# Install ArkCase using Helm
configsDir="$parentDir/configs"
devArkcase="$configsDir/dev-arkcase.yml"

echo "Install or Upgrade ArkCase"
if helm install arkcase arkcase/app -f "$devArkcase" 2>&1 | tee -a "$logPath" | grep -q "Error: INSTALLATION FAILED: cannot re-use a name that is still in use"; then
    echo "ArkCase was already installed previously. Upgrading..."
    if helm upgrade arkcase arkcase/app -f "$devArkcase"; then
        echo "ArkCase upgraded successfully."
    else
        echo "Failed to upgrade ArkCase" >&2
        exit 1
    fi
else
    echo "ArkCase installed successfully."
fi

# Update hosts file if on Windows
if [ "${OS}" == "Windows" ]; then
    echo "Updating host file..."
    if ! grep -q "messaging.default.svc.cluster.local" "$hostsFilePath"; then
        echo "Adding entry to hosts file..."
        echo "$hostsEntry" | tee -a "$hostsFilePath" > /dev/null
        echo "Entry added to hosts file."
    else
        echo "Entry already exists in hosts file."
    fi
fi

echo "Installation and setup completed successfully."
