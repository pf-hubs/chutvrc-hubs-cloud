# Chutvrc / Hubs Community Edition のローカル Kubernetes デプロイマニュアル

このガイドでは、Mozilla Hubs (Community Edition または Chutvrc バージョン) を **ローカル Mac / Windows / Linux 環境** (Docker Desktop 使用) にデプロイする方法について説明します。

## ステップ 1: 事前準備

1.  **二段階認証付きのGmailアカウント**を用意し、**アプリ パスワード** を一つ生成してメモしておく
    - 参照: [アプリ パスワードでログインする](https://support.google.com/mail/answer/185833)
2.  **Docker Desktop**: インストールし、設定で Kubernetes を有効にしてください。(Windows の場合は WSL2 バックエンドの使用を推奨)
3.  **コマンドラインツールのインストール**:
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
4. **スクリプトを入手する**
    - Gitでリポジトリをクローンする:
      ```bash
      git clone https://github.com/pf-hubs/chutvrc-hubs-cloud.git
      ```
    - もしくはDownload ZipでGitを介さずにダウンロードする
5. `community-edition`フォルダーの中に移動:
    ```bash
    cd community-edition
    ```

---

## ステップ 2: デプロイテンプレートの選択

シナリオごとに特定の構成テンプレートを用意しています。目的に合ったファイルの内容で、デフォルトの `hcce.yam` を置き換える必要があります。

**`community-edition` フォルダ内のターミナルで、以下のいずれかのコマンドを 1 つ実行してください:**

### オプション A: **Chutvrc** のデプロイ

- **Mac/Linux/Windows PowerShell:**
  ```
  cp hcce-chutvrc-local.yam hcce.yam
  ```
  _(Windows コマンドプロンプトの場合は `copy hcce-chutvrc-local.yam hcce.yam`)_

### オプション B: **Hubs Community Edition** のデプロイ

- **Mac/Linux/Windows PowerShell:**
  ```
  cp hcce-ce-local.yam hcce.yam
  ```
  _(Windows コマンドプロンプトの場合は `copy hcce-ce-local.yam hcce.yam`)_

---

## ステップ 3: `render_hcce.sh` の設定

1.  テキストエディタで `render_hcce.sh` を開きます。
2.  以下の変数を設定します。

- `HUB_DOMAIN`: `hubs.local`
- `ADM_EMAIL`: あなたのメールアドレス
- `SMTP_SERVER="smtp.gmail.com"`
- `SMTP_PORT="587"`
- `SMTP_USER="二段階認証付きのGmailアカウントのメールアドレス@gmail.com"`
- `SMTP_PASS="そのGmailアカウントのアプリパスワード(16桁)"`

---

## ステップ 4: Hosts ファイルの設定

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

## ステップ 5: Kubernetes コンテキストの確認

デプロイコマンドを実行する前に、`kubectl` がローカルクラスターを指していることを確認してください。

1.  **現在のコンテキストを確認:**

    ```bash
    kubectl config current-context
    ```

    `* docker-desktop` (または `* minikube` など) と表示されるはずです。

2.  **コンテキストの切り替え (必要な場合):**
    ```bash
    kubectl config use-context docker-desktop
    ```

---

## ステップ 6: デプロイ実行

SSL の生成と適用を処理する提供済みのヘルパースクリプトを実行します:

```bash
chmod +x deploy-local.sh
./deploy-local.sh
```

デプロイ後: ブラウザを完全に終了して SSL キャッシュをクリアし、https://hubs.local にアクセスしてください。
