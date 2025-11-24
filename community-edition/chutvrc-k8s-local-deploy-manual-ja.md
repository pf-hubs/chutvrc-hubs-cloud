# Hubs (Chutvrc / CE) のローカル Kubernetes デプロイマニュアル

このガイドでは、Mozilla Hubs (Community Edition または Chutvrc バージョン) を **ローカル Mac / Windows / Linux 環境** (Docker Desktop 使用) にデプロイする方法について説明します。

## パート 1: 前提条件

### 1.1. 共通要件

- **Git**: リポジトリをクローンするために必要です。
- **SMTP サーバー**: ログインメールの送信に必要です (例: Brevo, アプリパスワードを使用した Gmail)。

### 1.2. ツール要件

1.  **Docker Desktop**: インストールし、設定で Kubernetes を有効にしてください。(Windows の場合は WSL2 バックエンドの使用を推奨)
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

---

## パート 2: デプロイテンプレートの選択

シナリオごとに特定の構成テンプレートを用意しています。目的に合ったファイルの内容で、デフォルトの `hcce.yam` を置き換える必要があります。

**`community-edition` フォルダ内のターミナルで、以下のいずれかのコマンドを 1 つ実行してください:**

### オプション A: **Chutvrc** (カスタムバージョン) のデプロイ

- **Mac/Linux/Windows PowerShell:**
  ```
  cp hcce-chutvrc-local.yam hcce.yam
  ```
  _(Windows コマンドプロンプトの場合は `copy hcce-chutvrc-local.yam hcce.yam`)_

### オプション B: **Community Edition** (標準 CE) のデプロイ

- **Mac/Linux/Windows PowerShell:**
  ```
  cp hcce-ce-local.yam hcce.yam
  ```
  _(Windows コマンドプロンプトの場合は `copy hcce-ce-local.yam hcce.yam`)_

---

## パート 3: `render_hcce.sh` の設定

1.  テキストエディタで `render_hcce.sh` を開きます。
2.  以下の変数を設定します。

- **`HUB_DOMAIN`**: `hubs.local`
- **`ADM_EMAIL`**: あなたのメールアドレス
- **`SMTP_*`**: 有効な SMTP 認証情報が必要です (ローカルでも必須)。
  - `SMTP_SERVER="smtp.gmail.com"`
  - `SMTP_PORT="587"`
  - `SMTP_USER="your-gmail-address@gmail.com"`
  - `SMTP_PASS="your-app-password"`
    > **Gmail ユーザーへの注意:** Google アカウントで **2 段階認証プロセス** を有効にし、`SMTP_PASS` として使用するための **アプリ パスワード** を生成する必要があります。通常のログインパスワードは使用しないでください。
    > 参照: [アプリ パスワードでログインする](https://support.google.com/mail/answer/185833)

---

## パート 4: 環境セットアップ (Hosts ファイル)

1.  **Hosts ファイルの設定:**

    - **Mac / Linux:** `sudo nano /etc/hosts` を実行します。
    - **Windows:** メモ帳を**管理者として実行**し、`C:\Windows\System32\drivers\etc\hosts` を開きます。

    以下の行を追加してください:

    ```
    127.0.0.1   hubs.local
    127.0.0.1   assets.hubs.local
    127.0.0.1   cors.hubs.local
    127.0.0.1   stream.hubs.local
    ```

---

## パート 5: Kubernetes コンテキストの確認

デプロイコマンドを実行する前に、`kubectl` がローカルクラスターを指していることを確認してください。

1.  **現在のコンテキストを確認:**

    ```bash
    kubectl config current-context
    ```

    `docker-desktop` (または `minikube` など) と表示されるはずです。

2.  **コンテキストの切り替え (必要な場合):**
    ```bash
    kubectl config use-context docker-desktop
    ```

---

## パート 6: デプロイ実行

SSL の生成と適用を処理する提供済みのヘルパースクリプトを実行します:

```bash
chmod +x deploy-local.sh
./deploy-local.sh
```

デプロイ後: ブラウザを完全に終了して SSL キャッシュをクリアし、https://hubs.local にアクセスしてください。

---

## トラブルシューティング

- **503 エラー / Reticulum のクラッシュ:** 通常はボリュームマウントの問題です。`hcce.yam` から `mountPropagation: HostToContainer` が削除されていることを確認してください (パート 2 で提供されたローカルテンプレートでは既に対処されています)。
- **メールリンクが送信されない:** `render_hcce.sh` の `SMTP` 設定を確認してください。`hcce.yam` 内の "From" アドレスが、認証された SMTP ユーザーと一致していることを確認してください。
