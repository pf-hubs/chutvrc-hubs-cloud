# Hubs (Chutvrc / CE) の Kubernetes へのデプロイ: ローカル & Azure AKS マニュアル

このガイドでは、Mozilla Hubs (Community Edition または Chutvrc バージョン) を **ローカル Mac 環境** (Docker Desktop 使用) または **Microsoft Azure AKS** にデプロイする方法について説明します。

## パート 1: 前提条件

デプロイ先のターゲットに基づいて、必要な前提条件を確認してください。

### 1.1. 共通要件 (すべてのデプロイ)

- **Git**: リポジトリをクローンするために必要です。
- **ドメイン名**: クラウド/Azure の場合に必要です (例: `myhub.com`)。ローカルの場合は `hubs.local` でシミュレートします。
- **SMTP サーバー**: ログインメールの送信に必要です (例: Brevo, アプリパスワードを使用した Gmail)。

### 1.2. ローカルデプロイ要件 (Mac / Windows / Linux)

1.  **Docker Desktop**: インストールし、設定で Kubernetes を有効にしてください。(Windows の場合は WSL2 バックエンドの使用を推奨)

#### Windows ユーザー: WSL と ネイティブ PowerShell の比較

Windows をお使いの場合、デプロイスクリプトを実行するには 2 つの方法があります:

| 観点 | ネイティブ Windows (PowerShell/Chocolatey) | WSL (Windows Subsystem for Linux) |
|------|-------------------------------------------|-----------------------------------|
| **セットアップの複雑さ** | シンプル - Windows ネイティブツールを使用 | WSL2 のインストールが必要 |
| **スクリプト互換性** | スクリプトの修正が必要な場合あり | ネイティブ bash スクリプトがそのまま動作 |
| **推奨対象** | Windows ツールに慣れているユーザー | Linux/bash に慣れているユーザー |
| **Docker 統合** | Docker Desktop (Windows コンテナ) | Docker Desktop (WSL2 バックエンド) |
| **mkcert CA 信頼** | Windows ブラウザに自動適用 | Windows への手動 CA インポートが必要 |

**推奨:**
- Linux/bash に慣れている場合は **WSL** を使用してください - デプロイスクリプトは bash 用に書かれており、修正なしで動作します。
- Windows ネイティブツールを好む場合は **PowerShell/Chocolatey** を使用してください。ただし、bash 固有のコマンドを調整する必要がある場合があります。

2.  **コマンドラインツール**:
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
    - **Linux:** パッケージマネージャ (apt, yum 等) を使用して `kubectl` と `mkcert` をインストールしてください。
    - **WSL (Windows Subsystem for Linux):**

      **ステップ 1: WSL2 のインストール (未インストールの場合)**

      管理者として PowerShell を開き、以下を実行:
      ```powershell
      wsl --install
      ```
      これにより、デフォルトで Ubuntu を含む WSL2 がインストールされます。プロンプトが表示されたらコンピュータを再起動してください。

      再起動後、スタートメニューから「Ubuntu」を開いてセットアップを完了します (ユーザー名/パスワードを作成)。

      **ステップ 2: Docker Desktop の WSL2 統合を有効化**

      1. Docker Desktop の設定を開く
      2. 「Resources」→「WSL Integration」に移動
      3. Ubuntu ディストリビューションとの統合を有効化
      4. 「Apply & Restart」をクリック

      **ステップ 3: WSL 内でツールをインストール**

      Ubuntu ターミナルを開いて以下を実行:
      ```bash
      # kubectl のインストール
      sudo apt update && sudo apt install -y kubectl
      # mkcert のインストール
      sudo apt install -y libnss3-tools
      curl -JLO "https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64"
      sudo mv mkcert-v1.4.4-linux-amd64 /usr/local/bin/mkcert
      sudo chmod +x /usr/local/bin/mkcert
      mkcert -install
      ```

      > **WSL ユーザーへの重要な注意:** `mkcert -install` を実行した後、ブラウザが証明書を信頼するように、Windows にも CA 証明書をインストールする必要があります:
      > 1. CA の場所を確認: `mkcert -CAROOT`
      > 2. Windows エクスプローラーでそのパスを開く: `explorer.exe "$(mkcert -CAROOT)"`
      > 3. `rootCA.pem` をダブルクリックして「信頼されたルート証明機関」にインストール

      > **注意:** render スクリプトには Node.js と pem-jwk が必要です。以下でインストールしてください:
      > ```bash
      > sudo apt install -y nodejs npm
      > sudo npm install -g pem-jwk
      > ```

### 1.3. クラウドデプロイ要件 (Azure)

1.  **Azure アカウント**: 有効なサブスクリプションが必要です (従量課金制を推奨)。
2.  **Azure CLI (`az`)**:
    - CLI をダウンロードしてインストールします。
    - ログイン: `az login`

---

## パート 2: デプロイテンプレートの選択

シナリオごとに特定の構成テンプレートを用意しています。目的に合ったファイルの内容で、デフォルトの `hcce.yam` を置き換える必要があります。

**`community-edition` フォルダ内のターミナルで、以下のいずれかのコマンドを 1 つ実行してください:**

### オプション A: **Chutvrc** (カスタムバージョン) のデプロイ

- **ローカル (Mac/Linux/Windows PowerShell) の場合:**
  ```
  cp hcce-chutvrc-local.yam hcce.yam
  ```
  _(Windows コマンドプロンプトの場合は `copy hcce-chutvrc-local.yam hcce.yam`)_
- **Azure クラウドの場合:**
  ```
  cp hcce-chutvrc.yam hcce.yam
  ```

### オプション B: **Community Edition** (標準 CE) のデプロイ

- **ローカル (Mac/Linux/Windows PowerShell) の場合:**
  ```
  cp hcce-ce-local.yam hcce.yam
  ```
  _(Windows コマンドプロンプトの場合は `copy hcce-ce-local.yam hcce.yam`)_
- **Azure クラウドの場合:**
  ```
  cp hcce-ce.yam hcce.yam
  ```

---

## パート 3: `render_hcce.sh` の設定

1.  テキストエディタで `render_hcce.sh` を開きます。
2.  ターゲット環境に基づいて変数を設定します。

### ローカルデプロイの場合

- **`HUB_DOMAIN`**: `hubs.local`
- **`ADM_EMAIL`**: あなたのメールアドレス
- **`SMTP_*`**: 有効な SMTP 認証情報が必要です (ローカルでも必須)。
  - `SMTP_SERVER="smtp.gmail.com"`
  - `SMTP_PORT="587"`
  - `SMTP_USER="your-gmail-address@gmail.com"`
  - `SMTP_PASS="your-app-password"`
    > **Gmail ユーザーへの注意:** Google アカウントで **2 段階認証プロセス** を有効にし、`SMTP_PASS` として使用するための **アプリ パスワード** を生成する必要があります。通常のログインパスワードは使用しないでください。
    > 参照: [アプリ パスワードでログインする](https://support.google.com/mail/answer/185833)

### Azure デプロイの場合

- **`HUB_DOMAIN`**: 実際のドメイン (例: `example.com`)
- **`ADM_EMAIL`**: あなたのメールアドレス
- **`SMTP_*`**: SMTP プロバイダーの詳細 (例: Brevo または上記で説明した Gmail)
- **`DB_PASS` / `DB_USER`**: セキュリティのため、デフォルトから変更してください。

---

## パート 4: 環境セットアップ

選択したオプションに対応するセクションに従ってください。

### オプション A: ローカルセットアップ (Mac / Windows / Linux)

1.  **Hosts ファイルの設定:**

    - **Mac / Linux:** `sudo nano /etc/hosts` を実行します。
    - **Windows:** メモ帳を**管理者として実行**し、`C:\Windows\System32\drivers\etc\hosts` を開きます。
    - **WSL ユーザー:** ブラウザは Windows 上で動作するため、WSL の `/etc/hosts` ではなく **Windows** の hosts ファイルを編集してください。WSL ターミナルから開くには:
      ```bash
      # WSL から管理者として PowerShell を実行
      powershell.exe -Command "Start-Process notepad 'C:\Windows\System32\drivers\etc\hosts' -Verb RunAs"
      ```

    以下の行を追加してください:

    ```
    127.0.0.1   hubs.local
    127.0.0.1   assets.hubs.local
    127.0.0.1   cors.hubs.local
    127.0.0.1   stream.hubs.local
    ```

2.  **パート 5 (デプロイ) へ進んでください。**

### オプション B: Azure AKS セットアップ

1.  **リソースグループの作成:**

    ```
    az group create --name HubsResourceGroup --location westeurope
    ```

2.  **ネットワークセキュリティグループ (NSG) とルールの作成:**
    Hubs の音声/ビデオストリームに必要なポートを開放します。

    ```
    az network nsg create --resource-group HubsResourceGroup --name HubsNSG

    # TCP 4443 を許可 (Stream)
    az network nsg rule create --resource-group HubsResourceGroup --nsg-name HubsNSG --name AllowStream --priority 1000 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes '*' --destination-port-ranges 4443

    # TCP 5349 を許可 (Turn)
    az network nsg rule create --resource-group HubsResourceGroup --nsg-name HubsNSG --name AllowTurn --priority 1001 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes '*' --destination-port-ranges 5349

    # UDP 35000-60000 を許可 (Media)
    az network nsg rule create --resource-group HubsResourceGroup --nsg-name HubsNSG --name AllowUDP --priority 1002 --direction Inbound --access Allow --protocol Udp --source-address-prefixes '*' --destination-port-ranges 35000-60000
    ```

3.  **Kubernetes クラスターの作成:**

    - _個人利用:_ `Standard_F2s_v2`
    - _大規模イベント:_ `Standard_F8s_v2`

    ```
    az aks create -g HubsResourceGroup -s Standard_F2s_v2 -n HubsCluster -l westeurope --enable-node-public-ip --node-count 2 --network-plugin azure
    ```

4.  **Kubectl を Azure に接続:**

    ```
    az aks get-credentials --resource-group HubsResourceGroup --name HubsCluster
    ```

5.  **パート 5 (デプロイ) へ進んでください。**

---

## パート 4.5: Kubernetes コンテキストの確認と切り替え (重要)

デプロイコマンドを実行する前に、`kubectl` が正しいクラスター (ローカルの Docker Desktop または Azure AKS) を指していることを確認してください。誤ったクラスターへのデプロイを防ぐために重要です。

1.  **現在のコンテキストを確認:**

    ```bash
    kubectl config current-context
    ```

    - **ローカルの場合:** `docker-desktop` (または `minikube` など) と表示されるはずです。
    - **Azure の場合:** `HubsCluster` (または作成したクラスター名) と表示されるはずです。

2.  **コンテキストの切り替え (必要な場合):**
    利用可能なコンテキストを一覧表示:
    ```bash
    kubectl config get-contexts
    ```
    コンテキストを切り替え:
    ```bash
    kubectl config use-context <context-name>
    ```
    _(例: `kubectl config use-context docker-desktop`)_

## パート 5: デプロイ

> **Linux/WSL ユーザーへの注意:** `render_hcce.sh` スクリプトは macOS 固有の `base64 -i` 構文を使用しています。実行前にスクリプトを編集して以下を変更してください:
> ```bash
> # 以下の行を:
> export initCert=$(base64 -i cert.pem | tr -d '\n')
> export initKey=$(base64 -i key.pem | tr -d '\n')
> # 以下に変更:
> export initCert=$(base64 cert.pem | tr -d '\n')
> export initKey=$(base64 key.pem | tr -d '\n')
> ```

### 5.1. ローカルへのデプロイ

SSL の生成と適用を処理する提供済みのヘルパースクリプトを実行します:

```
chmod +x deploy-local.sh
./deploy-local.sh
```

デプロイ後: ブラウザを完全に終了して SSL キャッシュをクリアし、https://hubs.local にアクセスしてください。

### 5.2. Azure へのデプロイ

1.  **設定の適用:**
    ローカルスクリプトは使用しないため、標準の render および apply コマンドを実行します:
    ```
    bash render_hcce.sh && kubectl apply -f hcce.yaml
    ```

2)  **外部 IP の取得:**
    ロードバランサーが IP を割り当てるのを待ちます:

    ```
    kubectl get svc -n hcce
    ```

    `service/lb` エントリを探し、**EXTERNAL-IP** をコピーします。

3)  **DNS の設定 (A レコード):**
    ドメインレジストラ (例: Namecheap) に移動し、その IP を指す 4 つのレコードを作成します:
    - `@` (ルート)
    - `assets`
    - `cors`
    - `stream`

4.  **SSL 証明書 (Certbotbot):**
    Azure テンプレート (`hcce-chutvrc.yam` または `hcce-ce.yam` をコピーした場合) は、実際の SSL 証明書用に `certbotbot` を使用するように構成されています。
    - `cbb.sh` をあなたのメールアドレスとドメインで編集します。
    - `bash cbb.sh` を実行します。
    - 証明書が生成されたら、新しい証明書を使用するようにデプロイを更新します (設定内で `$Namespace/cert-hcce` を `$Namespace/cert-$HUB_DOMAIN` に置き換えていない場合は置き換えてください)。

---

## パート 6: トラブルシューティングと管理

### 一般的な問題

- **503 エラー / Reticulum のクラッシュ (ローカル):** 通常はボリュームマウントの問題です。`hcce.yam` から `mountPropagation: HostToContainer` が削除されていることを確認してください (パート 2 で提供されたローカルテンプレートでは既に対処されています)。
- **メールリンクが送信されない:** `render_hcce.sh` の `SMTP` 設定を確認してください。`hcce.yam` 内の "From" アドレスが、認証された SMTP ユーザーと一致していることを確認してください。
- **ボイスチャットが失敗する (Azure):** パート 4 で作成した NSG が、Azure ポータルで AKS クラスターの **サブネット** に関連付けられていることを確認してください。

### コスト管理 (Azure)

- **クラスターの一時停止:** 使用していないときにお金を節約するには:
  ```
  kubectl scale --replicas=0 deployment --all -n hcce
  ```

* **クラスターの再開:**
  ```
  kubectl scale --replicas=1 deployment --all -n hcce
  ```

- **コストの監視:** Azure ポータルの "Cost Management" を確認してください。標準的な F2s セットアップで 24 時間 365 日稼働させた場合、月額約 $80-100 程度かかります。
