#!/bin/bash
# =============================================================================
# Hubs Local Setup Script for Mac
# This script automates most of the setup process for deploying Hubs locally.
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
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

# =============================================================================
# Check if running on Mac
# =============================================================================
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is for Mac only. Please use setup_windows.ps1 for Windows."
    exit 1
fi

print_header "Hubs Local Setup for Mac"
echo "This script will set up your Mac for running Hubs locally."
echo "Some steps require your password for administrator access."
echo ""
read -p "Press Enter to continue..."

# =============================================================================
# Step 1: Install Homebrew
# =============================================================================
print_header "Step 1: Checking Homebrew"

if command -v brew &> /dev/null; then
    print_success "Homebrew is already installed"
else
    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    print_success "Homebrew installed"
fi

# =============================================================================
# Step 2: Install required tools
# =============================================================================
print_header "Step 2: Installing Required Tools"

# Git
if command -v git &> /dev/null; then
    print_success "Git is already installed"
else
    print_info "Installing Git..."
    brew install git
    print_success "Git installed"
fi

# kubectl
if command -v kubectl &> /dev/null; then
    print_success "kubectl is already installed"
else
    print_info "Installing kubectl..."
    brew install kubectl
    print_success "kubectl installed"
fi

# mkcert
if command -v mkcert &> /dev/null; then
    print_success "mkcert is already installed"
else
    print_info "Installing mkcert..."
    brew install mkcert
    print_success "mkcert installed"
fi

# Node.js
if command -v node &> /dev/null; then
    print_success "Node.js is already installed"
else
    print_info "Installing Node.js..."
    brew install node
    print_success "Node.js installed"
fi

# pem-jwk
if npm list -g pem-jwk &> /dev/null; then
    print_success "pem-jwk is already installed"
else
    print_info "Installing pem-jwk..."
    npm install -g pem-jwk
    print_success "pem-jwk installed"
fi

# =============================================================================
# Step 3: Setup mkcert
# =============================================================================
print_header "Step 3: Setting up SSL Certificates"

print_info "Installing mkcert root CA (you may be asked for your password)..."
mkcert -install
print_success "mkcert root CA installed"

# =============================================================================
# Step 4: Check Docker Desktop
# =============================================================================
print_header "Step 4: Checking Docker Desktop"

if ! command -v docker &> /dev/null; then
    print_warning "Docker Desktop is not installed or not running."
    echo ""
    echo "Please complete these manual steps:"
    echo "1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/"
    echo "2. Install and open Docker Desktop"
    echo "3. Go to Settings > Kubernetes"
    echo "4. Check 'Enable Kubernetes'"
    echo "5. Click 'Apply & Restart'"
    echo "6. Wait for Kubernetes to show green/running status"
    echo ""
    read -p "Press Enter after completing these steps..."
else
    print_success "Docker is installed"

    # Check if Kubernetes is enabled
    if kubectl cluster-info &> /dev/null; then
        print_success "Kubernetes is running"
    else
        print_warning "Kubernetes may not be enabled in Docker Desktop."
        echo ""
        echo "Please ensure:"
        echo "1. Docker Desktop is running"
        echo "2. Kubernetes is enabled (Settings > Kubernetes > Enable Kubernetes)"
        echo ""
        read -p "Press Enter after verifying..."
    fi
fi

# =============================================================================
# Step 5: Configure hosts file
# =============================================================================
print_header "Step 5: Configuring hosts file"

HOSTS_ENTRY="127.0.0.1   hubs.local"
if grep -q "hubs.local" /etc/hosts; then
    print_success "hosts file already configured"
else
    print_info "Adding hubs.local entries to /etc/hosts (requires password)..."
    sudo bash -c 'cat >> /etc/hosts << EOF

# Hubs Local Development
127.0.0.1   hubs.local
127.0.0.1   assets.hubs.local
127.0.0.1   cors.hubs.local
127.0.0.1   stream.hubs.local
EOF'
    print_success "hosts file configured"
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

sed -i '' "s|export HUB_DOMAIN=\".*\"|export HUB_DOMAIN=\"hubs.local\"|" render_hcce.sh
sed -i '' "s|export ADM_EMAIL=\".*\"|export ADM_EMAIL=\"$user_email\"|" render_hcce.sh
sed -i '' "s|export SMTP_SERVER=\".*\"|export SMTP_SERVER=\"$smtp_server\"|" render_hcce.sh
sed -i '' "s|export SMTP_PORT=\".*\"|export SMTP_PORT=\"$smtp_port\"|" render_hcce.sh
sed -i '' "s|export SMTP_USER=\".*\"|export SMTP_USER=\"$smtp_user\"|" render_hcce.sh
sed -i '' "s|export SMTP_PASS=\".*\"|export SMTP_PASS=\"$smtp_pass\"|" render_hcce.sh

print_success "Configuration updated"

# =============================================================================
# Step 8: Verify Kubernetes context
# =============================================================================
print_header "Step 8: Verifying Kubernetes Context"

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
# Step 9: Deploy
# =============================================================================
print_header "Step 9: Deploying Hubs"

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
echo "1. Quit your browser completely (Cmd + Q)"
echo "2. Open your browser and go to: https://hubs.local"
echo ""
echo "If you see an SSL warning, try:"
echo "- Quitting and reopening your browser"
echo "- Clearing your browser cache"
echo ""
print_success "Enjoy using Hubs!"
