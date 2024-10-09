#!/bin/bash

# Define color codes for the text in the console
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define the services and their respective ports to take the certificates
servicesToTakeCertificates=(
    "rdbms:3306"
    "messaging:61613 61616"
    "search:8983"
    "ldap:636"
    "content-main:9001"
)

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

# Keystore/Truststore paths and passwords
keystore="$localHomeDir/.arkcase/acm/private/arkcase.ks"
keystorePass="AcMd3v$"
truststore="$localHomeDir/.arkcase/acm/private/arkcase.ts"
truststorePass="password"
certsPath="certs"

# Create a directory to store certificates temporary if it doesn't exist
if [ ! -d "$certsPath" ]; then
    mkdir -p "$certsPath"
fi

# Retrieve the certificate for a service
retrieve_certificate() {
    local serviceName="$1"
    local ports=("$2")

    for port in "${ports[@]}"; do
        echo -e "${CYAN}Retrieving certificate for $serviceName on port $port...${NC}"

        # Run openssl to get the certificate and save the response
        response=$(echo | openssl s_client -connect localhost:$port -showcerts 2>&1)

        # Check if the response contains any certificates
        if [[ "$response" != *"-----BEGIN CERTIFICATE-----"* ]]; then
            echo -e "${YELLOW}No certificates found for $serviceName on port $port.${NC}"
            continue
        fi

        # Parse certificates from the response
        certificates=()
        currentCert=""
        inCert=false

        while IFS= read -r line; do
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')  # Trim leading and trailing whitespace
            if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
                inCert=true
                currentCert="$line"
            elif $inCert; then
                currentCert+=$'\n'"$line"
                if [[ "$line" == "-----END CERTIFICATE-----" ]]; then
                    certificates+=("$currentCert")
                    inCert=false
                    currentCert=""
                fi
            fi
        done <<< "$response"

        if [ ${#certificates[@]} -eq 0 ]; then
            echo -e "${YELLOW}No certificates found for $serviceName on port $port.${NC}"
            continue
        fi

        # Save certificates to file (overwrite if it exists)
        crtFile="${certsPath}/arkcase-${serviceName}.crt"
        printf "%s\n" "${certificates[@]}" > "$crtFile"

        echo -e "${GREEN}Certificates for $serviceName on port $port saved to $crtFile.${NC}"
        break  # Break the loop if a certificate is successfully retrieved
    done
}

# Retrieve certificates for all services
for service in "${servicesToTakeCertificates[@]}"; do
    IFS=":" read -r serviceName ports <<< "$service"
    IFS=" " read -r -a portsArray <<< "$ports"
    retrieve_certificate "$serviceName" "${portsArray[@]}"
done

echo -e "${CYAN}Certificates retrieved. Importing certificates to keystores...${NC}"

# Import a certificate into a keystore
import_certificate() {
    local serviceName="$1"
    local crtFile="$2"
    local keystore="$3"
    local storePass="$4"

    local alias="arkcase-$serviceName-file"

    # Delete existing alias if it exists
    keytool -delete -alias "$alias" -keystore "$keystore" -storepass "$storePass" -noprompt 2>/dev/null

    # Run keytool command to import the certificate
    keytool -import -alias "$alias" -file "$crtFile" -keystore "$keystore" -storepass "$storePass" -noprompt

    echo -e "${GREEN}Certificate $crtFile imported to $keystore.${NC}"
}

# Import certificates for all services
for service in "${servicesToTakeCertificates[@]}"; do
    IFS=":" read -r serviceName _ <<< "$service"
    crtFile="${certsPath}/arkcase-${serviceName}.crt"

    if [ -f "$crtFile" ]; then
        echo -e "${CYAN}Importing $crtFile for service $serviceName to keystore $keystore and truststore $truststore.${NC}"
        import_certificate "$serviceName" "$crtFile" "$keystore" "$keystorePass"
        import_certificate "$serviceName" "$crtFile" "$truststore" "$truststorePass"
    else
        echo -e "${YELLOW}Certificate file $crtFile not found. Skipping import for $serviceName.${NC}"
    fi
done

echo -e "${GREEN}Certificates imported.${NC}"

# Delete temp certificates
rm -rf "$certsPath"
echo -e "${GREEN}Temp Certificates are deleted.${NC}"
