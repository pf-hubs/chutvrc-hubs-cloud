# Deploy Hubs (Chutvrc / CE) to Kubernetes: Local & Azure AKS Manual

This guide covers deploying Mozilla Hubs (Community Edition or Chutvrc version) to either a **Local Mac Environment** (using Docker Desktop) or **Microsoft Azure AKS**.

## Part 1: Prerequisites

Select the prerequisites based on your intended deployment target.

### 1.1. Common Requirements (All Deployments)

- **Git**: To clone repositories.
- **A Domain Name**: Required for Cloud/Azure (e.g., `myhub.com`). For local, we will simulate this with `hubs.local`.
- **SMTP Server**: Required for login emails (e.g., Brevo, Gmail with App Password).

### 1.2. Local Deployment Requirements (Mac / Windows / Linux)

1.  **Docker Desktop**: Install and enable Kubernetes in Settings. (WSL2 backend recommended for Windows).
2.  **Command Line Tools**:
    - **Mac (Homebrew):**
      ```bash
      brew install kubectl mkcert
      mkcert -install
      ```
    - **Windows (Chocolatey):**
      ```powershell
      choco install kubernetes-cli mkcert
      mkcert -install
      ```
    - **Linux:** Install `kubectl` and `mkcert` using your package manager.

### 1.3. Cloud Deployment Requirements (Azure)

1.  **Azure Account**: You need an active subscription (Pay-As-You-Go recommended).
2.  **Azure CLI (`az`)**:
    - Download and install the CLI.
    - Login: `az login`

---

## Part 2: Select Your Deployment Template

We have prepared specific configuration templates for different scenarios. You must replace the default `hcce.yam` with the content of the file matching your goal.

**Run ONE of the following commands in your terminal inside the `community-edition` folder:**

### Option A: Deploying **Chutvrc** (Custom Version)

- **For Local (Mac/Linux/Windows PowerShell):**
  ```bash
  cp hcce-chutvrc-local.yam hcce.yam
  ```
  _(For Windows Command Prompt: `copy hcce-chutvrc-local.yam hcce.yam`)_
- **For Azure Cloud:**
  ```
  cp hcce-chutvrc.yam hcce.yam
  ```

### Option B: Deploying **Community Edition** (Standard CE)

- **For Local (Mac/Linux/Windows PowerShell):**
  ```bash
  cp hcce-ce-local.yam hcce.yam
  ```
  _(For Windows Command Prompt: `copy hcce-ce-local.yam hcce.yam`)_
- **For Azure Cloud:**
  ```
  cp hcce-ce.yam hcce.yam
  ```

---

## Part 3: Configure `render_hcce.sh`

1.  Open `render_hcce.sh` in a text editor.
2.  Set the variables based on your target environment.

### For Local Deployment

- **`HUB_DOMAIN`**: `hubs.local`.
- **`ADM_EMAIL`**: Your email address.
- **`SMTP_*`**: Valid SMTP credentials are required (even for local).
  - `SMTP_SERVER="smtp.gmail.com"`
  - `SMTP_PORT="587"`
  - `SMTP_USER="your-gmail-address@gmail.com"`
  - `SMTP_PASS="your-app-password"`
    > **Note for Gmail Users:** You must enable **2-Step Verification** on your Google Account and then generate an **App Password** to use as your `SMTP_PASS`. Do not use your regular login password.
    > See: [Sign in with App Passwords](https://support.google.com/mail/answer/185833)

### For Azure Deployment

- **`HUB_DOMAIN`**: Your actual domain (e.g., `example.com`).
- **`ADM_EMAIL`**: Your email address.
- **`SMTP_*`**: Your SMTP provider details (e.g., Brevo or Gmail as described above).
- **`DB_PASS` / `DB_USER`**: Change these from defaults for security.

---

## Part 4: Environment Setup

Follow the section corresponding to your choice.

### Option A: Local Setup (Mac / Windows / Linux)

1.  **Configure Hosts File:**

    - **Mac / Linux:** Run `sudo nano /etc/hosts`.
    - **Windows:** Run Notepad as **Administrator** and open `C:\Windows\System32\drivers\etc\hosts`.

    Add the following lines:

    ```
    127.0.0.1   hubs.local
    127.0.0.1   assets.hubs.local
    127.0.0.1   cors.hubs.local
    127.0.0.1   stream.hubs.local
    ```

2.  **Proceed to Part 5 (Deployment).**

### Option B: Azure AKS Setup

1.  **Create Resource Group:**

    ```
    az group create --name HubsResourceGroup --location westeurope
    ```

2.  **Create Network Security Group & Rules:**
    Open ports required for Hubs audio/video streams.

    ```
    az network nsg create --resource-group HubsResourceGroup --name HubsNSG

    # Allow TCP 4443 (Stream)
    az network nsg rule create --resource-group HubsResourceGroup --nsg-name HubsNSG --name AllowStream --priority 1000 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes '*' --destination-port-ranges 4443

    # Allow TCP 5349 (Turn)
    az network nsg rule create --resource-group HubsResourceGroup --nsg-name HubsNSG --name AllowTurn --priority 1001 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes '*' --destination-port-ranges 5349

    # Allow UDP 35000-60000 (Media)
    az network nsg rule create --resource-group HubsResourceGroup --nsg-name HubsNSG --name AllowUDP --priority 1002 --direction Inbound --access Allow --protocol Udp --source-address-prefixes '*' --destination-port-ranges 35000-60000
    ```

3.  **Create Kubernetes Cluster:**

    - _Personal Use:_ `Standard_F2s_v2`
    - _Large Event:_ `Standard_F8s_v2`

    ```
    az aks create -g HubsResourceGroup -s Standard_F2s_v2 -n HubsCluster -l westeurope --enable-node-public-ip --node-count 2 --network-plugin azure
    ```

4.  **Connect Kubectl to Azure:**

    ```
    az aks get-credentials --resource-group HubsResourceGroup --name HubsCluster
    ```

5.  **Proceed to Part 5 (Deployment).**

---

## Part 4.5: Verify & Switch Kubernetes Context (Important)

Before running any deployment commands, ensure `kubectl` is pointing to the correct cluster (Local Docker Desktop or Azure AKS). This prevents accidental deployment to the wrong environment.

1.  **Check Current Context:**

    ```bash
    kubectl config current-context
    ```

    - **For Local:** Should say `docker-desktop` (or `minikube`, etc.).
    - **For Azure:** Should say `HubsCluster` (or whatever you named it).

2.  **Switch Context (If needed):**
    List available contexts:
    ```bash
    kubectl config get-contexts
    ```
    Switch context:
    ```bash
    kubectl config use-context <context-name>
    ```
    _(e.g., `kubectl config use-context docker-desktop`)_

## Part 5: Deployment

### 5.1. Deploying to Local

Run the provided helper script which handles SSL generation and application:

```
chmod +x deploy-local.sh
./deploy-local.sh
```

After deploy: Quit your browser completely to clear SSL cache, then visit https://hubs.local.

### 5.2. Deploying to Azure

1.  **Apply Configuration:**
    Since we are not using the local script, run the standard render and apply command:
    ```
    bash render_hcce.sh && kubectl apply -f hcce.yaml
    ```

2)  **Get External IP:**
    Wait for the Load Balancer to assign an IP:

    ```
    kubectl get svc -n hcce
    ```

    Look for the `service/lb` entry and copy the **EXTERNAL-IP**.

3)  **Configure DNS (A Records):**
    Go to your domain registrar (e.g., Namecheap) and create 4 records pointing to that IP:
    - `@` (Root)
    - `assets`
    - `cors`
    - `stream`

4.  **SSL Certificates (Certbotbot):**
    The Azure templates (if you copied `hcce-chutvrc.yam` or `hcce-ce.yam`) are configured to use `certbotbot` for real SSL certificates.
    - Edit `cbb.sh` with your email and domain.
    - Run `bash cbb.sh`.
    - Once certs are generated, update your deployment to use the new certs (replace `$Namespace/cert-hcce` with `$Namespace/cert-$HUB_DOMAIN` in your config if not already done).

---

## Part 6: Troubleshooting & Management

### Common Issues

- **503 Error / Reticulum Crash (Local):** Usually a volume mount issue. Ensure `mountPropagation: HostToContainer` is removed from the `hcce.yam` (the local templates provided in Part 2 should already handle this).
- **Email Links Not Sending:** Check your `SMTP` settings in `render_hcce.sh`. Ensure the "From" address in `hcce.yam` matches your authenticated SMTP user.
- **Voice Chat Fails (Azure):** Ensure you associated the NSG created in Part 4 with the **Subnet** of your AKS cluster in the Azure Portal.

### Cost Management (Azure)

- **Pause Cluster:** To save money when not in use:
  ```
  kubectl scale --replicas=0 deployment --all -n hcce
  ```

* **Resume Cluster:**
  ```
  kubectl scale --replicas=1 deployment --all -n hcce
  ```

- **Monitor Costs:** Check "Cost Management" in the Azure Portal. Expect ~\$80-100/month for a standard F2s setup if left running 24/7.
