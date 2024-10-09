#!/bin/bash

echo "Install Environment"

# Detect the operating system
OS=""
case "$(uname -s)" in
    Linux*)     OS="Linux";;
    Darwin*)    OS="Mac";;
    CYGWIN*|MINGW*|MSYS*|MINGW32*|MINGW64*) OS="Windows";;
    *)          echo "Unsupported operating system: $(uname -s)"; exit 1;;
esac
echo "Detected OS: ${OS}"

# Get the directory where the scripts are located
scriptDir="$(dirname "$(realpath "$0")")"
# Go one level up from the script directory
parentDir=$(dirname "$scriptDir")
logsDir="$parentDir/logs"

# Create the logs directory if it doesn't exist
mkdir -p "$logsDir"

# Define log file path inside the logs directory
logPath="$logsDir/setup.logs"

# Clear the log file if it already exists, otherwise create a new one
> "$logPath"

# Start logging (redirect stdout and stderr to the log file)
exec > >(tee -a "$logPath") 2>&1

# Ensure the script is running with elevated privileges
if [ "${OS}" == "Windows" ]; then
    if ! net session > /dev/null 2>&1; then
        echo "This script must be run as Administrator on Windows!" >&2
        exit 1
    fi
fi #TODO: Do it for Linux and Mac

# Ensure the work directory exists, create it if it doesn't
if [ "${OS}" == "Windows" ]; then
    mkdir -p "/c/work"
fi #TODO: Do it for Linux and Mac

# Set Minikube directory based on OS
minikubeDir=""

if [ "$OS" = "Windows" ]; then
    minikubeDir="/c/work/minikube"  # Use forward slashes for Git Bash on Windows
fi #TODO: Do it for Linux and Mac

echo "Creating Minikube directory at $minikubeDir..."

# Create the directory
if mkdir -p "$minikubeDir"; then
    echo "Minikube directory created successfully."
else
    echo "Failed to create Minikube directory." >&2
    exit 1
fi

# Define the Minikube download URL based on the OS
if [ "$OS" = "Windows" ]; then
    minikubeUrl="https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe"
    minikubePath="$minikubeDir/minikube.exe"
fi #TODO: Do it for Linux and Mac

# Download Minikube
echo "Downloading Minikube from $minikubeUrl to $minikubePath..."

if curl -Lo "$minikubePath" "$minikubeUrl"; then
    echo "Minikube downloaded successfully."
    if [ "${OS}" != "Windows" ]; then
        chmod +x "$minikubePath"
    fi
else
    echo "Failed to download Minikube." >&2
    exit 1
fi

# Update System Path
if [ "${OS}" == "Windows" ]; then
    echo "Updating System Path for Minikube on Windows..."

	powershell.exe -NoProfile -Command "
	\$oldPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
	if (\$oldPath -notlike '*C:\work\minikube*') {
		\$newPath = \$oldPath + ';C:\work\minikube'
		[Environment]::SetEnvironmentVariable('Path', \$newPath, [EnvironmentVariableTarget]::Machine)
		Write-Output 'System Path updated successfully.'
	} else {
		Write-Output 'Minikube path already exists in System Path.'
	}
	"
fi #TODO: Do it for Linux and Mac

echo "Installing kubectl..."

if [ "${OS}" == "Windows" ]; then
    echo "Installing kubectl on Windows..."
    
    # Install kubectl using winget
    if winget install -e --id Kubernetes.kubectl --accept-source-agreements --accept-package-agreements; then
        echo "kubectl installed successfully."
    else
        echo "Failed to install kubectl." >&2
        exit 1
    fi
fi #TODO: Do it for Linux and Mac

# Install Helm
echo "Installing Helm..."

if [ "${OS}" == "Windows" ]; then
    echo "Installing Helm on Windows..."
    
    # Install Helm using winget
    if winget install Helm.Helm --accept-source-agreements --accept-package-agreements; then
        echo "Helm installed successfully."
    else
        echo "Failed to install Helm." >&2
        exit 1
    fi
fi #TODO: Do it for Linux and Mac

if [ "${OS}" == "Windows" ]; then
    echo "Enabling Hyper-V on Windows..."

    # Call PowerShell to enable Hyper-V
    powershell.exe -Command "Start-Process powershell -ArgumentList 'Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart' -Verb RunAs"

    # Check if Hyper-V was enabled successfully
    if [ $? -eq 0 ]; then
        echo "Hyper-V enabled successfully."
    else
        echo "Failed to enable Hyper-V." >&2
        exit 1
    fi

else
    echo "Hyper-V is only applicable to Windows. Skipping this step." >&2
fi

if [ "${OS}" == "Windows" ]; then
    echo "The system requires a restart to apply the changes. Do you want to restart? (y/n)"
    read -r restart
    if [ "$restart" = "y" ]; then
        echo "Restarting Windows to apply changes..."
        powershell.exe -Command "Start-Process powershell -ArgumentList 'Restart-Computer -Force' -Verb RunAs"
        exit 0
    else
        echo "Restart skipped. Please restart manually at some point for the changes to be applied."
        exit 0
    fi
fi
