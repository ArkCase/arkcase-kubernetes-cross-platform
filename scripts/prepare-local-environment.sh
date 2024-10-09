#!/bin/bash
echo "Pull ArkCase configuration"

# Detect the operating system
OS=""
case "$(uname -s)" in
    Linux*)     OS="Linux";;
    Darwin*)    OS="Mac";;
    CYGWIN*|MINGW*|MSYS*|MINGW32*|MINGW64*) OS="Windows";;
    *)          echo "Unsupported operating system: $(uname -s)"; exit 1;;
esac
echo "Detected OS: ${OS}"

# Determine the local home directory
localHomeDir="$HOME"
if [ "${OS}" == "Windows" ]; then
    localHomeDir=$(echo "$localHomeDir" | tr -d '\r')  # Remove trailing carriage return
fi #TODO: Do it for Linux and Mac

# Define the pod and folder details
podName="arkcase-core-0"
configFolderInPod="/app/home/.arkcase"
zipFileName="arkcase.zip"
zipPathInPod="/app/home/$zipFileName"
localFolderPath="$localHomeDir/.arkcase"
localZipPath="$localHomeDir/$zipFileName"
logFilePath="$localHomeDir/.arkcase/acm/log4j2.xml"
arkCaseServerFile="$localHomeDir/.arkcase/acm/acm-config-server-repo/arkcase-server.yaml"
confFilePath="$localHomeDir/.arkcase/acm/conf.yml"

# Remove existing .arkcase folder from local home directory if it exists
if [ -d "$localFolderPath" ]; then
    echo "Removing folder $localFolderPath"
    rm -rf "$localFolderPath"
    echo "Existing .arkcase folder removed from $localHomeDir"
fi

# Zip the folder in the pod arkcase-core-0
echo "Zipping folder $configFolderInPod"
if ! kubectl exec "$podName" -- bash -c "cd /app/home && zip -r $zipFileName .arkcase"; then
    echo "Failed to zip folder $configFolderInPod"
    exit 1
fi
echo "Zipping folder $configFolderInPod finished"

# Copy arkcase.zip file from the pod
echo "Copying ${podName}:${zipPathInPod} to local machine"
if ! kubectl cp "${podName}:${zipPathInPod}" "$zipFileName"; then
    echo "Failed to copy file to local machine"
    exit 1
fi
echo "Copy finished"

# Extract arkcase.zip file to the local home directory
echo "Extracting $zipFileName to $localHomeDir"
if ! unzip -o "$zipFileName" -d "$localHomeDir"; then
    echo "Failed to extract zip on local machine"
    exit 1
fi
echo "Extract finished"

# Clean up - remove arkcase.zip file from the pod arkcase-core-0
echo "Removing $zipPathInPod from the pod"
if ! kubectl exec "$podName" -- bash -c "rm $zipPathInPod"; then
    echo "Failed to remove zip from the pod"
    exit 1
fi
echo "$zipPathInPod removed"

# Clean up - remove arkcase.zip file from the local machine
echo "Removing $zipFileName"
if ! rm -f "$zipFileName"; then
    echo "Failed to remove zip from local machine"
    exit 1
fi
echo "$zipFileName removed"

# Modify database string to not support SSL
echo "Replacing database string in the configuration - remove SSL requirement"
if ! sed -i.bak -E 's|(url: "jdbc:mariadb://[^?]*)(\?.*)?"|\1"|g' "$arkCaseServerFile"; then
    echo "Failed to replace database URL string"
    exit 1
fi
if [ -f "$arkCaseServerFile.bak" ]; then
    rm -f "$arkCaseServerFile.bak"
fi
echo "Replace database string finished successfully"

# Change config server URL from https to http
echo "Replacing conf.yaml - change https to http"
if ! sed -i.bak 's/https:\/\//http:\/\//g' "$confFilePath"; then
    echo "Failed to replace conf.yaml URL with http"
    exit 1
fi
if [ -f "$confFilePath.bak" ]; then
    rm -f "$confFilePath.bak"
fi
echo "Replace conf.yaml finished successfully"

# Update log4j2.xml - sys:catalina.base instead of env:LOGS_DIR
echo "Replacing log4j2.xml"
if ! sed -i.bak 's|\${env:LOGS_DIR}|\${sys:catalina.base}/logs|g' "$logFilePath"; then
    echo "Failed to replace log4j2.xml"
    exit 1
fi
if [ -f "$logFilePath.bak" ]; then
    rm -f "$logFilePath.bak"
fi
echo "Replace log4j2.xml finished successfully"

echo "Folder .arkcase has been successfully migrated from arkcase-core-0 pod to local machine"
