#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Get the script directory and adjust for configs directory
scriptDir=$(dirname "$(realpath "$0")")
configsDir=$(realpath "$scriptDir/../configs")

# Ensure the work directory exists, create it if it doesn't
if [ "${OS}" == "Windows" ]; then
    mkdir -p "/c/work"
fi #TODO: Do it for Linux and Mac

# Function to install packages on Windows using Chocolatey
install_packages_with_choco() {
    # Install Chocolatey (if not already installed)
    if ! command -v /c/ProgramData/chocolatey/bin/choco &> /dev/null; then
        echo -e "${YELLOW}Chocolatey not found. Installing Chocolatey...${NC}"
        powershell -NoProfile -ExecutionPolicy Bypass -Command \
            "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
    fi

    # Install jq
    echo -e "${GREEN}Installing jq...${NC}"
    if /c/ProgramData/chocolatey/bin/choco install jq -y; then
		  echo -e "${GREEN}jq installed sucessfully${NC}"
    else
      echo -e "${RED}Failed to install jq${NC}"
    fi

    # Install Java 11
    echo -e "${GREEN}Installing Java 11...${NC}"
    if /c/ProgramData/chocolatey/bin/choco install openjdk11 --version=11.0.15 -y; then
      echo -e "${GREEN}Java 11 installed sucessfully${NC}"

      # Set JAVA_HOME environment variable
      javaHome="C:\\Program Files\\OpenJDK\\openjdk-11.0.15_10"
      powershell -NoProfile -ExecutionPolicy Bypass -Command \
        "[System.Environment]::SetEnvironmentVariable('JAVA_HOME', '$javaHome', 'Machine'); \
        [System.Environment]::SetEnvironmentVariable('Path', [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';$javaHome\\bin', 'Machine')"
    else
      echo -e "${RED}Failed to install Java 11${NC}"
    fi

    # Install Maven 3.9.9
    echo -e "${GREEN}Installing Maven 3.9.9...${NC}"
    if /c/ProgramData/chocolatey/bin/choco install maven --version=3.9.9 -y; then
      echo -e "${GREEN}Maven 3.9.9 installed sucessfully${NC}"
    else
      echo -e "${RED}Failed to install Maven 3.9.9q${NC}"
    fi

    # Install Node.js 16.20.2
    echo -e "${GREEN}Installing Node.js 16.20.1...${NC}"
    if /c/ProgramData/chocolatey/bin/choco install nodejs --version=16.20.1 -y; then
      echo -e "${GREEN}Node.js 16.20.1 installed sucessfully${NC}"
    else
      echo -e "${RED}Failed to install Node.js 16.20.1${NC}"
    fi

    # Install Yarn 1.22.19
    echo -e "${GREEN}Installing Yarn 1.22.19...${NC}"
    if /c/ProgramData/chocolatey/bin/choco install yarn --version=1.22.19 -y; then
      echo -e "${GREEN}Yarn 1.22.19 installed sucessfully${NC}"
    else
      echo -e "${RED}Failed to install Yarn 1.22.19${NC}"
    fi

    # Install OpenSSL
    echo -e "${GREEN}Installing OpenSSL...${NC}"
    if /c/ProgramData/chocolatey/bin/choco install openssl -y; then
      echo -e "${GREEN}OpenSSL installed sucessfully${NC}"
    else
      echo -e "${RED}Failed to install OpenSSL${NC}"
    fi

    # Install Tomcat 9
    echo -e "${GREEN}Installing Tomcat 9...${NC}"
    if /c/ProgramData/chocolatey/bin/choco install tomcat --version=9.0.93 -y; then
      echo -e "${GREEN}Tomcat 9 installed sucessfully${NC}"
      unzip -o "/c/ProgramData/chocolatey/lib/Tomcat/tools/apache-tomcat-9.0.93-windows-x64.zip" -d "/c/work"
    else
      echo -e "${RED}Failed to install Tomcat 9${NC}"
    fi

    # Define paths
    customServerXml="$configsDir/server.xml"
    tomcatServerXml="/c/work/apache-tomcat-9.0.93/conf/server.xml"

    # Replace the default server.xml with the custom one
    if [ -f "$customServerXml" ]; then
        echo -e "${YELLOW}Replacing Tomcat server.xml with custom server.xml...${NC}"
        cp "$customServerXml" "$tomcatServerXml"
        echo -e "${GREEN}Tomcat server.xml has been replaced.${NC}"
    else
        echo -e "${RED}Custom server.xml not found in configs directory. Skipping replacement.${NC}"
    fi

    # Set PdfTron DLL
    echo -e "${GREEN}Setting up PdfTron...${NC}"
    pdfTronDllPath="$configsDir/PDFNetC.dll"
    pdfTronTargetPath="/c/Windows/System32/PDFNetC.dll"

    if [ -f "$pdfTronDllPath" ]; then
        echo -e "${YELLOW}Copying PDFNetC.dll to /c/Windows/System32...${NC}"
        cp "$pdfTronDllPath" "$pdfTronTargetPath"
        echo -e "${GREEN}PDFNetC.dll has been copied.${NC}"
    else
        echo -e "${RED}PDFNetC.dll not found in configs directory. Skipping copying.${NC}"
    fi

    # Clean up unused packages
    echo -e "${GREEN}Cleaning up...${NC}"
    /c/ProgramData/chocolatey/bin/choco clean

    echo -e "${GREEN}Installation completed successfully!${NC}"
	  echo -e "${RED}PLEASE RESTART THIS SESSION TO BE ABLE ALL CHANGES TO TAKE EFFECT${NC}"
}

# Execute installation based on the detected OS
if [ "$OS" == "Windows" ]; then
	install_packages_with_choco
fi #TODO: Do it for Linux and Mac
