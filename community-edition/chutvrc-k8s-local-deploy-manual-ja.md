# Chutvrc / Hubs Community Edition のローカル Kubernetes デプロイマニュアル

このガイドでは、Mozilla Hubs (Community Edition または Chutvrc バージョン) を **ローカル Mac / Windows / Linux 環境** (Docker Desktop 使用) にデプロイする方法について説明します。

## ステップ 1: 事前準備

1.  **二段階認証付きのGmailアカウント**を用意し、**アプリ パスワード** を一つ生成してメモしておく
    - 参照: [アプリ パスワードでログインする](https://support.google.com/mail/answer/185833)
2.  **Docker Desktop**: [インストール](https://www.docker.com/products/docker-desktop/)し、設定で Kubernetes を有効にしてください。(Windows の場合は WSL2 バックエンドの使用を推奨)
    <img width="989" height="564" alt="image" src="https://github.com/user-attachments/assets/db9712f8-3471-4e26-a758-599b4008b400" />
3.  **コマンドラインツールのインストール**:
    - **Mac:** ターミナルを開き、[Homebrew](https://brew.sh/)でインストールする
      ```bash
      brew install kubectl mkcert
      mkcert -install
      ```
    - **Windows:**
        1. [Chocolatelyをインストール](https://chocolatey.org/install) （メールアドレスの登録は不要）
        2. Powershellを開き、このコマンドを実行してmkcertをインストールする：
      ```
      choco install mkcert
      mkcert -install
      ```
        3. kubectlはDocker Desktopインストール時に自動的に追加されるため、追加のインストールは不要。インストールされていない場合は[こちら](https://codeeaze.com/how-to-install-kubectl-on-windows-10-11-step-by-step-guide)を参照してインストールする
    - **Linux:** パッケージマネージャ (apt, yum 等) を使用して `kubectl` と `mkcert` をインストールしてください。
4. **スクリプトを入手する**
    - Gitでリポジトリをクローンする:
      ```bash
      git clone https://github.com/pf-hubs/chutvrc-hubs-cloud.git
      ```
    - もしくはDownload ZipでGitを介さずにダウンロードする
5. `community-edition`フォルダーの中に移動:
    ```bash
    cd chutvrc-hubs-cloud/community-edition
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

- **Mac / Linux:**
  ```bash
  chmod +x deploy-local.sh
  ./deploy-local.sh
  ```
- **Windows:**
  ```bash
  ./deploy-local.sh
  ```

デプロイ後: ブラウザを完全に終了して SSL キャッシュをクリアし、https://hubs.local にアクセスしてください。

---

## 便利なコマンド

デプロイメントの状態を確認したり、リソースを管理するための便利な `kubectl` コマンドをいくつか紹介します。

### ポッドの状態を確認する

`hcce` ネームスペースで実行されているすべてのポッドのリストと状態を表示します。

```bash
kubectl get pods -n hcce
```

### デプロイメントをスケールダウンする (一時停止)

chutvrc/Hubs のすべてのコンポーネントを一時的に停止したい場合は、すべてのデプロイメントのレプリカ数を 0 にスケールダウンできます。

```bash
kubectl scale deployment --all -n hcce --replicas=0
```

### デプロイメントをスケールアップする (再開)

サービスを再開するには、レプリカ数を 1 に戻すか、再度デプロイします。

```bash
kubectl scale deployment --all -n hcce --replicas=1
# もしくは再びデプロイ
./deploy-local.sh
```
