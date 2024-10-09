#!/bin/bash

# Function to display an error and exit
function error_exit {
    echo "$1" >&2
    exit 1
}

# Parse and validate the arguments
argument=$1
package=$2

if [ "$argument" != "--package" ]; then
    error_exit "Invalid value for argument. The argument name is --package."
fi

if [ "$package" != "all" ] && [ "$package" != "arkcase" ] && [ "$package" != "config" ]; then
    error_exit "Invalid value for --package. Possible values: all, arkcase, config. You entered: [$package]"
fi

echo "Deploy ArkCase"

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

# Path to minikube id_rsa key
id_rsa_path="$localHomeDir/.minikube/machines/minikube/id_rsa"

# Path to save the PEM file that we need for running the command SCP
pem_key_path="$localHomeDir/.ssh/minikube_key.pem"

# Ensure the .ssh directory exists, create it if it doesn't
mkdir -p "$localHomeDir/.ssh"

# Copy id_rsa to a new PEM file
cp "$id_rsa_path" "$pem_key_path"
echo "PEM file generated at $pem_key_path"

# Get Minikube IP and set Minikube user
minikube_ip=$(minikube ip)
minikube_user="docker"
known_hosts_file="$localHomeDir/.ssh/known_hosts"

# Define paths for ArkCase app and config in Minikube
minikube_app_path="/home/docker/arkcase/app"
minikube_config_path="/home/docker/arkcase/config"

if [ "$OS" = "Windows" ]; then
    local_app_path="/c/work/arkcase/acm-standard-applications/war/arkcase/target/*.war"
    local_config_path="/c/work/acm-config/target/*.zip"
fi #TODO: Do it for Linux and Mac

# If a folder exists in Minikube, remove it and his content if it does, and then create it again
function recreate_folder {
    minikube_path=$1

    # Check if the folder exists in Minikube
    folder_exists=$(minikube ssh "[ -d $minikube_path ] && echo 'exists' || echo 'not exists'")

    if [ "$folder_exists" = "exists" ]; then
        echo "Folder $minikube_path already exists. Removing it."
        minikube ssh "rm -rf $minikube_path"
    fi

    echo "Creating folder $minikube_path"
    minikube ssh "mkdir -p $minikube_path"
}

# Move package file from local Windows (arkcase.war and config.zip) to Minikube and extract it
function move_and_extract_package_file {
    local_package_path=$1
    minikube_path=$2

    echo "Moving package file from $local_package_path to $minikube_path"

    # Add Minikube IP to known hosts to avoid authenticity check
    ssh-keyscan -H "$minikube_ip" >> "$known_hosts_file"

    # Expand wildcard and handle files individually
    for file in $local_package_path; do
        if [ -e "$file" ]; then
            scp -i "$pem_key_path" "$file" "$minikube_user@$minikube_ip:$minikube_path"
            package_file_name=$(basename "$file")
            extract_command="unzip -o ${minikube_path}/${package_file_name} -d ${minikube_path} && rm ${minikube_path}/${package_file_name}"
            minikube ssh "$extract_command"
        else
            echo "File not found: $file"
        fi
    done

    echo "Package file has been extracted and removed from Minikube."
}

# Delete ArkCase pod to be able to start ArkCase successfully after deploying ArkCase and/or Config
function delete-arkcase-core-0-pod {
  echo "Delete arkcase-core-0 pod to trigger restarting the same pod"
  if kubectl delete pod arkcase-core-0; then
    echo "The pod arkcase-core-0 is deleted successfully. Restarting the pod is initiated."
  else
    echo "The pod arkcase-core-0 is not deleted successfully. Restarting the pod is not initiated."
  fi
}

# Deploy options: all (deploy both arkcase and configuration), arkcase (deploy only ArkCase), config (deploy only configuration)
case $package in
    "all")
        # Recreate and process both app and config
        recreate_folder "$minikube_app_path"
        recreate_folder "$minikube_config_path"

        move_and_extract_package_file "$local_app_path" "$minikube_app_path"
        move_and_extract_package_file "$local_config_path" "$minikube_config_path"

        delete-arkcase-core-0-pod
        ;;
    "arkcase")
        # Recreate and process only arkcase
        recreate_folder "$minikube_app_path"
        move_and_extract_package_file "$local_app_path" "$minikube_app_path"

        delete-arkcase-core-0-pod
        ;;
    "config")
        # Recreate and process only configuration
        recreate_folder "$minikube_config_path"
        move_and_extract_package_file "$local_config_path" "$minikube_config_path"

        delete-arkcase-core-0-pod
        ;;
esac

echo "Script execution completed."
