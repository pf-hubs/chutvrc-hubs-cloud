#!/bin/bash
# =============================================================================
# Hubs Local Setup Script for WSL (Windows Subsystem for Linux)
# This script automates most of the setup process for deploying Hubs locally.
#
# HOW TO RUN:
# 1. Open Ubuntu (or your WSL distro) terminal
# 2. Navigate to the community-edition folder
# 3. Run: chmod +x setup_wsl.sh && ./setup_wsl.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[X] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[-] $1${NC}"
}

# =============================================================================
# Check if running in WSL
# =============================================================================
if ! grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
    print_error "This script is for WSL (Windows Subsystem for Linux) only."
    print_error "For native Linux, please use setup_mac.sh with minor modifications."
    print_error "For Windows, please use setup_windows.ps1."
    exit 1
fi

print_header "Hubs Local Setup for WSL"
echo "This script will set up your WSL environment for running Hubs locally."
echo ""
echo "Important: Since your browser runs on Windows (not in WSL), this script"
echo "will guide you through importing certificates to Windows and editing the"
echo "Windows hosts file."
echo ""
read -p "Press Enter to continue..."

# =============================================================================
# Step 1: Install tools via apt
# =============================================================================
print_header "Step 1: Installing Required Tools"

print_info "Updating package lists..."
sudo apt update

# Git
if command -v git &> /dev/null; then
    print_success "Git is already installed"
else
    print_info "Installing Git..."
    sudo apt install -y git
    print_success "Git installed"
fi

# kubectl
if command -v kubectl &> /dev/null; then
    print_success "kubectl is already installed"
else
    print_info "Installing kubectl..."
    sudo apt install -y kubectl || {
        # If kubectl is not in apt, install via snap or download
        print_warning "kubectl not found in apt, trying alternative installation..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    }
    print_success "kubectl installed"
fi

# libnss3-tools (for mkcert)
print_info "Installing libnss3-tools..."
sudo apt install -y libnss3-tools
print_success "libnss3-tools installed"

# mkcert
if command -v mkcert &> /dev/null; then
    print_success "mkcert is already installed"
else
    print_info "Downloading mkcert..."
    curl -JLO "https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64"
    sudo mv mkcert-v1.4.4-linux-amd64 /usr/local/bin/mkcert
    sudo chmod +x /usr/local/bin/mkcert
    print_success "mkcert installed"
fi

# Node.js
if command -v node &> /dev/null; then
    print_success "Node.js is already installed"
else
    print_info "Installing Node.js..."
    sudo apt install -y nodejs npm
    print_success "Node.js installed"
fi

# pem-jwk
if npm list -g pem-jwk &> /dev/null 2>&1; then
    print_success "pem-jwk is already installed"
else
    print_info "Installing pem-jwk..."
    sudo npm install -g pem-jwk
    print_success "pem-jwk installed"
fi

# =============================================================================
# Step 2: Setup mkcert
# =============================================================================
print_header "Step 2: Setting up SSL Certificates"

print_info "Installing mkcert root CA in WSL..."
mkcert -install
print_success "mkcert root CA installed in WSL"

# =============================================================================
# Step 3: Guide user through Windows CA import
# =============================================================================
print_header "Step 3: Import CA Certificate to Windows (Important!)"

echo "Since your browser runs on Windows, you need to import the mkcert CA"
echo "certificate to Windows for your browser to trust it."
echo ""

CA_ROOT=$(mkcert -CAROOT)
print_info "Your CA root is located at: $CA_ROOT"
echo ""

echo "Opening the CA folder in Windows Explorer..."
cd "$CA_ROOT" && explorer.exe . 2>/dev/null || {
    print_warning "Could not open Explorer. Please navigate to this folder manually:"
    echo "  $CA_ROOT"
}
cd - > /dev/null

echo ""
echo "Please follow these steps to import the certificate to Windows:"
echo ""
echo "  1. In the Explorer window, you should see 'rootCA.pem'"
echo "  2. Click on the address bar and copy the full path"
echo "     (looks like: \\\\wsl.localhost\\Ubuntu\\home\\...\\rootCA.pem)"
echo ""
echo "  3. Press Win + R to open the Run dialog"
echo "  4. Type 'certmgr.msc' and press Enter"
echo ""
echo "  5. In the left panel, expand 'Trusted Root Certification Authorities'"
echo "  6. Click on 'Certificates'"
echo "  7. Right-click in the right panel > 'All Tasks' > 'Import...'"
echo ""
echo "  8. Click 'Next'"
echo "  9. Click 'Browse...', paste the path you copied, click 'Open', then 'Next'"
echo "  10. Make sure 'Place all certificates in the following store' is selected"
echo "  11. Store should say 'Trusted Root Certification Authorities'"
echo "  12. Click 'Next', then 'Finish'"
echo "  13. Click 'Yes' to confirm the security warning, then 'OK'"
echo ""
read -p "Press Enter after you have imported the certificate to Windows..."
print_success "CA certificate import step completed"

# =============================================================================
# Step 4: Check Docker Desktop
# =============================================================================
print_header "Step 4: Checking Docker Desktop"

if command -v docker &> /dev/null; then
    print_success "Docker is accessible from WSL"

    # Check if Kubernetes is enabled
    if kubectl cluster-info &> /dev/null 2>&1; then
        print_success "Kubernetes is running"
    else
        print_warning "Kubernetes may not be enabled in Docker Desktop."
        echo ""
        echo "Please ensure:"
        echo "1. Docker Desktop is running on Windows"
        echo "2. WSL Integration is enabled for your distro (Settings > Resources > WSL Integration)"
        echo "3. Kubernetes is enabled (Settings > Kubernetes > Enable Kubernetes)"
        echo ""
        read -p "Press Enter after verifying..."
    fi
else
    print_warning "Docker is not accessible from WSL."
    echo ""
    echo "Please complete these steps:"
    echo "1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/"
    echo "2. Install and open Docker Desktop on Windows"
    echo "3. Go to Settings > Resources > WSL Integration"
    echo "4. Enable integration for your WSL distro (e.g., Ubuntu)"
    echo "5. Go to Settings > Kubernetes"
    echo "6. Check 'Enable Kubernetes'"
    echo "7. Click 'Apply & Restart'"
    echo "8. Wait for both Docker and Kubernetes to show green/running status"
    echo ""
    read -p "Press Enter after completing these steps..."
fi

# =============================================================================
# Step 5: Configure Windows hosts file
# =============================================================================
print_header "Step 5: Configuring Windows hosts file"

echo "Checking if hubs.local is already in Windows hosts file..."

# Check if hosts file already has hubs.local
if powershell.exe -Command "Get-Content 'C:\Windows\System32\drivers\etc\hosts'" 2>/dev/null | grep -q "hubs.local"; then
    print_success "Windows hosts file already configured"
else
    print_info "Adding hubs.local entries to Windows hosts file..."
    echo ""
    echo "This requires Administrator privileges on Windows."
    echo "A PowerShell window will open asking for permission."
    echo ""

    # Use PowerShell to add entries with admin privileges
    powershell.exe -Command "Start-Process powershell -Verb RunAs -ArgumentList '-Command', 'Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value \"\`n# Hubs Local Development\`n127.0.0.1   hubs.local\`n127.0.0.1   assets.hubs.local\`n127.0.0.1   cors.hubs.local\`n127.0.0.1   stream.hubs.local\"'" 2>/dev/null || {
        print_warning "Could not automatically edit hosts file."
        echo ""
        echo "Please manually add these lines to C:\\Windows\\System32\\drivers\\etc\\hosts:"
        echo ""
        echo "127.0.0.1   hubs.local"
        echo "127.0.0.1   assets.hubs.local"
        echo "127.0.0.1   cors.hubs.local"
        echo "127.0.0.1   stream.hubs.local"
        echo ""
        echo "You can run this command to open the file:"
        echo "  powershell.exe -Command \"Start-Process notepad 'C:\\Windows\\System32\\drivers\\etc\\hosts' -Verb RunAs\""
        echo ""
    }

    read -p "Press Enter after the hosts file has been updated..."
    print_success "Windows hosts file configuration step completed"
fi

# =============================================================================
# Step 6: Select deployment template
# =============================================================================
print_header "Step 6: Select Deployment Template"

echo "Which version would you like to deploy?"
echo "1) Chutvrc (Custom Version)"
echo "2) Community Edition (Standard)"
echo ""
read -p "Enter your choice (1 or 2): " template_choice

case $template_choice in
    1)
        cp hcce-chutvrc-local.yam hcce.yam
        print_success "Chutvrc template selected"
        ;;
    2)
        cp hcce-ce-local.yam hcce.yam
        print_success "Community Edition template selected"
        ;;
    *)
        print_warning "Invalid choice, defaulting to Chutvrc"
        cp hcce-chutvrc-local.yam hcce.yam
        ;;
esac

# =============================================================================
# Step 7: Configure SMTP settings
# =============================================================================
print_header "Step 7: Configure Email Settings"

echo "Hubs requires SMTP settings to send login emails."
echo "You can use Gmail with an App Password."
echo ""
echo "To get a Gmail App Password:"
echo "1. Go to Google Account > Security"
echo "2. Enable 2-Step Verification"
echo "3. Go to Security > 2-Step Verification > App passwords"
echo "4. Create an app password for 'Mail'"
echo ""

read -p "Enter your email address: " user_email
read -p "Enter SMTP server (default: smtp.gmail.com): " smtp_server
smtp_server=${smtp_server:-smtp.gmail.com}
read -p "Enter SMTP port (default: 587): " smtp_port
smtp_port=${smtp_port:-587}
read -p "Enter SMTP username (your email): " smtp_user
read -s -p "Enter SMTP password (App Password): " smtp_pass
echo ""

# Update render_hcce.sh
print_info "Updating configuration..."

sed -i "s|export HUB_DOMAIN=\".*\"|export HUB_DOMAIN=\"hubs.local\"|" render_hcce.sh
sed -i "s|export ADM_EMAIL=\".*\"|export ADM_EMAIL=\"$user_email\"|" render_hcce.sh
sed -i "s|export SMTP_SERVER=\".*\"|export SMTP_SERVER=\"$smtp_server\"|" render_hcce.sh
sed -i "s|export SMTP_PORT=\".*\"|export SMTP_PORT=\"$smtp_port\"|" render_hcce.sh
sed -i "s|export SMTP_USER=\".*\"|export SMTP_USER=\"$smtp_user\"|" render_hcce.sh
sed -i "s|export SMTP_PASS=\".*\"|export SMTP_PASS=\"$smtp_pass\"|" render_hcce.sh

print_success "Configuration updated"

# =============================================================================
# Step 8: Fix base64 command for Linux
# =============================================================================
print_header "Step 8: Fixing base64 Command for Linux"

print_info "Checking render_hcce.sh for Mac-specific base64 syntax..."

if grep -q "base64 -i" render_hcce.sh; then
    print_info "Fixing base64 commands (removing -i flag for Linux compatibility)..."
    sed -i 's/base64 -i cert\.pem/base64 cert.pem/g' render_hcce.sh
    sed -i 's/base64 -i key\.pem/base64 key.pem/g' render_hcce.sh
    print_success "base64 commands fixed for Linux"
else
    print_success "base64 commands are already Linux-compatible"
fi

# =============================================================================
# Step 9: Verify Kubernetes context
# =============================================================================
print_header "Step 9: Verifying Kubernetes Context"

current_context=$(kubectl config current-context 2>/dev/null || echo "none")
print_info "Current Kubernetes context: $current_context"

if [[ "$current_context" != "docker-desktop" ]]; then
    print_warning "Switching to docker-desktop context..."
    kubectl config use-context docker-desktop || {
        print_error "Could not switch to docker-desktop context."
        print_error "Make sure Docker Desktop is running with Kubernetes enabled."
        exit 1
    }
fi
print_success "Kubernetes context verified"

# =============================================================================
# Step 10: Deploy
# =============================================================================
print_header "Step 10: Deploying Hubs"

echo "Ready to deploy Hubs locally."
read -p "Press Enter to start deployment..."

chmod +x deploy_local.sh
./deploy_local.sh

# =============================================================================
# Done!
# =============================================================================
print_header "Setup Complete!"

echo -e "${GREEN}Hubs has been deployed locally!${NC}"
echo ""
echo "Next steps:"
echo "1. Close your browser completely on Windows"
echo "2. Open your browser and go to: https://hubs.local"
echo ""
echo "If you see an SSL warning:"
echo "- Make sure you completed Step 3 (importing CA certificate to Windows)"
echo "- Try closing and reopening your browser completely"
echo "- Clear your browser cache"
echo ""
print_success "Enjoy using Hubs!"
