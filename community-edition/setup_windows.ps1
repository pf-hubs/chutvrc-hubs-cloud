# =============================================================================
# Hubs Local Setup Script for Windows
# This script automates most of the setup process for deploying Hubs locally.
#
# HOW TO RUN:
# 1. Right-click on this file
# 2. Select "Run with PowerShell"
# 3. If prompted about execution policy, type 'Y' and press Enter
# =============================================================================

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Yellow
    Write-Host "Restarting as Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Set execution policy for this session
Set-ExecutionPolicy Bypass -Scope Process -Force

function Write-Header {
    param([string]$text)
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host $text -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$text)
    Write-Host "[OK] $text" -ForegroundColor Green
}

function Write-Warning2 {
    param([string]$text)
    Write-Host "[!] $text" -ForegroundColor Yellow
}

function Write-Error2 {
    param([string]$text)
    Write-Host "[X] $text" -ForegroundColor Red
}

function Write-Info {
    param([string]$text)
    Write-Host "[-] $text" -ForegroundColor Cyan
}

# =============================================================================
# Start
# =============================================================================
Write-Header "Hubs Local Setup for Windows"
Write-Host "This script will set up your Windows PC for running Hubs locally."
Write-Host "Please follow the prompts and wait for each step to complete."
Write-Host ""
Read-Host "Press Enter to continue"

# =============================================================================
# Step 1: Install Chocolatey
# =============================================================================
Write-Header "Step 1: Checking Chocolatey"

if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Success "Chocolatey is already installed"
} else {
    Write-Info "Installing Chocolatey..."
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Success "Chocolatey installed"
}

# =============================================================================
# Step 2: Install required tools
# =============================================================================
Write-Header "Step 2: Installing Required Tools"

# Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Success "Git is already installed"
} else {
    Write-Info "Installing Git..."
    choco install git -y
    Write-Success "Git installed"
}

# kubectl
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    Write-Success "kubectl is already installed"
} else {
    Write-Info "Installing kubectl..."
    choco install kubernetes-cli -y
    Write-Success "kubectl installed"
}

# mkcert
if (Get-Command mkcert -ErrorAction SilentlyContinue) {
    Write-Success "mkcert is already installed"
} else {
    Write-Info "Installing mkcert..."
    choco install mkcert -y
    Write-Success "mkcert installed"
}

# Node.js
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Success "Node.js is already installed"
} else {
    Write-Info "Installing Node.js..."
    choco install nodejs -y
    Write-Success "Node.js installed"
}

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# pem-jwk
Write-Info "Installing pem-jwk..."
npm install -g pem-jwk 2>$null
Write-Success "pem-jwk installed"

# =============================================================================
# Step 3: Setup mkcert
# =============================================================================
Write-Header "Step 3: Setting up SSL Certificates"

Write-Info "Installing mkcert root CA..."
mkcert -install
Write-Success "mkcert root CA installed"

# =============================================================================
# Step 4: Check Docker Desktop
# =============================================================================
Write-Header "Step 4: Checking Docker Desktop"

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Success "Docker is installed"

    # Check if Kubernetes is enabled
    $kubeCheck = kubectl cluster-info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Kubernetes is running"
    } else {
        Write-Warning2 "Kubernetes may not be enabled in Docker Desktop."
        Write-Host ""
        Write-Host "Please ensure:" -ForegroundColor Yellow
        Write-Host "1. Docker Desktop is running" -ForegroundColor Yellow
        Write-Host "2. Kubernetes is enabled (Settings > Kubernetes > Enable Kubernetes)" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter after verifying"
    }
} else {
    Write-Warning2 "Docker Desktop is not installed or not running."
    Write-Host ""
    Write-Host "Please complete these manual steps:" -ForegroundColor Yellow
    Write-Host "1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    Write-Host "2. Install and open Docker Desktop" -ForegroundColor Yellow
    Write-Host "3. Go to Settings > Kubernetes" -ForegroundColor Yellow
    Write-Host "4. Check 'Enable Kubernetes'" -ForegroundColor Yellow
    Write-Host "5. Click 'Apply & Restart'" -ForegroundColor Yellow
    Write-Host "6. Wait for Kubernetes to show green/running status" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter after completing these steps"
}

# =============================================================================
# Step 5: Configure hosts file
# =============================================================================
Write-Header "Step 5: Configuring hosts file"

$hostsPath = "$env:windir\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsPath -Raw

if ($hostsContent -match "hubs\.local") {
    Write-Success "hosts file already configured"
} else {
    Write-Info "Adding hubs.local entries to hosts file..."
    $newEntries = @"

# Hubs Local Development
127.0.0.1   hubs.local
127.0.0.1   assets.hubs.local
127.0.0.1   cors.hubs.local
127.0.0.1   stream.hubs.local
"@
    Add-Content -Path $hostsPath -Value $newEntries
    Write-Success "hosts file configured"
}

# =============================================================================
# Step 6: Get script directory and change to it
# =============================================================================
Write-Header "Step 6: Preparing Deployment"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir
Write-Info "Working directory: $scriptDir"

# =============================================================================
# Step 7: Select deployment template
# =============================================================================
Write-Header "Step 7: Select Deployment Template"

Write-Host "Which version would you like to deploy?"
Write-Host "1) Chutvrc (Custom Version)"
Write-Host "2) Community Edition (Standard)"
Write-Host ""
$templateChoice = Read-Host "Enter your choice (1 or 2)"

switch ($templateChoice) {
    "1" {
        Copy-Item "hcce-chutvrc-local.yam" "hcce.yam" -Force
        Write-Success "Chutvrc template selected"
    }
    "2" {
        Copy-Item "hcce-ce-local.yam" "hcce.yam" -Force
        Write-Success "Community Edition template selected"
    }
    default {
        Write-Warning2 "Invalid choice, defaulting to Chutvrc"
        Copy-Item "hcce-chutvrc-local.yam" "hcce.yam" -Force
    }
}

# =============================================================================
# Step 8: Configure SMTP settings
# =============================================================================
Write-Header "Step 8: Configure Email Settings"

Write-Host "Hubs requires SMTP settings to send login emails."
Write-Host "You can use Gmail with an App Password."
Write-Host ""
Write-Host "To get a Gmail App Password:" -ForegroundColor Cyan
Write-Host "1. Go to Google Account > Security" -ForegroundColor Cyan
Write-Host "2. Enable 2-Step Verification" -ForegroundColor Cyan
Write-Host "3. Go to Security > 2-Step Verification > App passwords" -ForegroundColor Cyan
Write-Host "4. Create an app password for 'Mail'" -ForegroundColor Cyan
Write-Host ""

$userEmail = Read-Host "Enter your email address"
$smtpServer = Read-Host "Enter SMTP server (default: smtp.gmail.com)"
if ([string]::IsNullOrWhiteSpace($smtpServer)) { $smtpServer = "smtp.gmail.com" }
$smtpPort = Read-Host "Enter SMTP port (default: 587)"
if ([string]::IsNullOrWhiteSpace($smtpPort)) { $smtpPort = "587" }
$smtpUser = Read-Host "Enter SMTP username (your email)"
$smtpPass = Read-Host "Enter SMTP password (App Password)" -AsSecureString
$smtpPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($smtpPass))

# Update render_hcce.sh
Write-Info "Updating configuration..."

$renderContent = Get-Content "render_hcce.sh" -Raw
$renderContent = $renderContent -replace 'export HUB_DOMAIN="[^"]*"', 'export HUB_DOMAIN="hubs.local"'
$renderContent = $renderContent -replace 'export ADM_EMAIL="[^"]*"', "export ADM_EMAIL=`"$userEmail`""
$renderContent = $renderContent -replace 'export SMTP_SERVER="[^"]*"', "export SMTP_SERVER=`"$smtpServer`""
$renderContent = $renderContent -replace 'export SMTP_PORT="[^"]*"', "export SMTP_PORT=`"$smtpPort`""
$renderContent = $renderContent -replace 'export SMTP_USER="[^"]*"', "export SMTP_USER=`"$smtpUser`""
$renderContent = $renderContent -replace 'export SMTP_PASS="[^"]*"', "export SMTP_PASS=`"$smtpPassPlain`""
Set-Content "render_hcce.sh" -Value $renderContent -NoNewline

Write-Success "Configuration updated"

# =============================================================================
# Step 9: Verify Kubernetes context
# =============================================================================
Write-Header "Step 9: Verifying Kubernetes Context"

$currentContext = kubectl config current-context 2>$null
Write-Info "Current Kubernetes context: $currentContext"

if ($currentContext -ne "docker-desktop") {
    Write-Warning2 "Switching to docker-desktop context..."
    kubectl config use-context docker-desktop
    if ($LASTEXITCODE -ne 0) {
        Write-Error2 "Could not switch to docker-desktop context."
        Write-Error2 "Make sure Docker Desktop is running with Kubernetes enabled."
        Read-Host "Press Enter to exit"
        exit 1
    }
}
Write-Success "Kubernetes context verified"

# =============================================================================
# Step 10: Deploy using Git Bash
# =============================================================================
Write-Header "Step 10: Deploying Hubs"

Write-Host "Ready to deploy Hubs locally."
Write-Host ""
Write-Host "The deployment will run in Git Bash." -ForegroundColor Yellow
Read-Host "Press Enter to start deployment"

# Find Git Bash
$gitBashPath = "C:\Program Files\Git\bin\bash.exe"
if (-not (Test-Path $gitBashPath)) {
    $gitBashPath = "C:\Program Files (x86)\Git\bin\bash.exe"
}

if (Test-Path $gitBashPath) {
    # Run deploy script in Git Bash
    $deployScript = @"
cd '$scriptDir'
chmod +x deploy_local.sh
./deploy_local.sh
echo ''
echo 'Deployment complete! Press Enter to close...'
read
"@
    $deployScript | & $gitBashPath
} else {
    Write-Error2 "Git Bash not found. Please run the following commands manually in Git Bash:"
    Write-Host ""
    Write-Host "cd '$scriptDir'" -ForegroundColor Yellow
    Write-Host "chmod +x deploy_local.sh" -ForegroundColor Yellow
    Write-Host "./deploy_local.sh" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter after running the deployment"
}

# =============================================================================
# Done!
# =============================================================================
Write-Header "Setup Complete!"

Write-Host "Hubs has been deployed locally!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Close your browser completely"
Write-Host "2. Open your browser and go to: https://hubs.local"
Write-Host ""
Write-Host "If you see an SSL warning, try:"
Write-Host "- Closing and reopening your browser"
Write-Host "- Clearing your browser cache"
Write-Host ""
Write-Success "Enjoy using Hubs!"
Write-Host ""
Read-Host "Press Enter to exit"
