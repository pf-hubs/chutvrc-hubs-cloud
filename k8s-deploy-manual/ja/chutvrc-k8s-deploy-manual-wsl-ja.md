# Hubs (Chutvrc / CE) を Kubernetes にデプロイ: WSL マニュアル

このガイドでは、Mozilla Hubs（Community Edition または Chutvrc バージョン）を **ローカル環境**（WSL2 での Docker Desktop 使用）または **Microsoft Azure AKS** に Windows Subsystem for Linux からデプロイする方法を説明します。

> **ターミナル初心者の方へ:** ご安心ください！このガイドでは、すべての手順を詳しく説明します。入力するコマンドはグレーのボックスに表示されます。コピーして貼り付けるだけです。

> **なぜ WSL？** WSL（Windows Subsystem for Linux）を使うと、Windows 上で Linux を実行できます。デプロイスクリプトは Linux/bash 用に書かれているため、WSL では修正なしで完璧に動作します。

---

## パート 1: 前提条件

### 1.1. WSL2 のインストール

WSL を使うと、Windows 内で Linux を実行できます。

#### ステップ 1: 管理者として PowerShell を開く

1. `Win + X`（Windows キー + X）を押す
2. 「Windows ターミナル（管理者）」または「PowerShell（管理者）」をクリック
3. 「このアプリがデバイスに変更を加えることを許可しますか？」と表示されたら「はい」をクリック

#### ステップ 2: WSL をインストール

```powershell
wsl --install
```
> デフォルトで WSL2 と Ubuntu がインストールされます。数分かかる場合があります。

#### ステップ 3: コンピュータを再起動

インストールが完了したら、コンピュータを再起動してください。

#### ステップ 4: Ubuntu のセットアップ

1. 再起動後、「Ubuntu」というタイトルのウィンドウが自動的に開きます
2. 開かない場合は、`Win` キーを押して「Ubuntu」と入力し、クリックして開きます
3. Ubuntu のインストールが完了するまで待ちます（数分かかります）
4. プロンプトが表示されたら、ユーザー名を作成（小文字、スペースなし）
5. パスワードを作成（入力中は文字が表示されません - これは正常です）
6. このパスワードを覚えておいてください - `sudo` コマンドで必要になります

> **ヒント:** セットアップ中はこの Ubuntu ウィンドウを開いたままにしてください。

### 1.2. Docker Desktop のインストール

Docker Desktop は Hubs アプリケーションをコンテナで実行します。

1. https://www.docker.com/products/docker-desktop/ にアクセス
2. 「Download for Windows」をクリック
3. ダウンロードしたインストーラーを実行
4. インストールウィザードに従う（デフォルトオプションのまま）
5. **重要:** 「Use WSL 2 instead of Hyper-V」にチェックが入っていることを確認
6. 求められたらコンピュータを再起動

### 1.3. Docker WSL 統合を有効化

Docker Desktop が起動したら：

1. システムトレイ（画面右下）のクジラアイコンを右クリック
2. 「Settings」をクリック
3. 「Resources」>「WSL Integration」に移動
4. 「Ubuntu」（またはお使いの WSL ディストリビューション）をオンに切り替え
5. 「Apply & Restart」をクリック
6. 左メニューの「Kubernetes」に移動
7. 「Enable Kubernetes」にチェック
8. 「Apply & Restart」をクリック
9. Docker と Kubernetes の両方が緑色/実行中のステータスになるまで待つ（左下）

> **注意:** 初めて Kubernetes を有効にする場合、数分かかることがあります。

### 1.4. Ubuntu にツールをインストール

Ubuntu を開きます（`Win` キーを押して「Ubuntu」と入力し、クリックして開く）。

パッケージリストを更新：
```bash
sudo apt update
```
> `sudo` は管理者としてコマンドを実行します。プロンプトが表示されたら Ubuntu のパスワードを入力してください。

kubectl をインストール：
```bash
sudo apt install -y kubectl
```
> Kubernetes クラスターを制御する kubectl をインストールします。

mkcert の依存関係をインストール：
```bash
sudo apt install -y libnss3-tools
```

mkcert をダウンロードしてインストール：
```bash
curl -JLO "https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64"
sudo mv mkcert-v1.4.4-linux-amd64 /usr/local/bin/mkcert
sudo chmod +x /usr/local/bin/mkcert
```
> SSL 証明書を作成する mkcert をインストールします。

mkcert をセットアップ：
```bash
mkcert -install
```

Node.js と npm をインストール：
```bash
sudo apt install -y nodejs npm
```

pem-jwk をインストール（render スクリプトに必要）：
```bash
sudo npm install -g pem-jwk
```

### 1.5. CA 証明書を Windows にインポート（重要！）

ブラウザは Windows で実行されるため、WSL で作成された証明書を信頼するように Windows に伝える必要があります。

#### ステップ 1: CA の場所を確認

Ubuntu で実行：
```bash
mkcert -CAROOT
```
> `/home/yourname/.local/share/mkcert` のようなパスが表示されます

#### ステップ 2: Windows エクスプローラーでフォルダを開く

```bash
cd $(mkcert -CAROOT) && explorer.exe .
```
> Windows エクスプローラーでフォルダが開きます。

#### ステップ 3: ファイルパスをコピー

1. 開いたエクスプローラーウィンドウに `rootCA.pem` というファイルがあります
2. 上部のアドレスバーをクリック
3. 完全なパスをコピー（`\\wsl.localhost\Ubuntu\home\yourname\.local\share\mkcert\rootCA.pem` のような形式）

#### ステップ 4: 証明書を Windows にインポート

1. `Win + R` を押して「ファイル名を指定して実行」ダイアログを開く
2. `certmgr.msc` と入力して Enter を押す
3. 左パネルで「信頼されたルート証明機関」を展開
4. 「証明書」をクリック
5. 右パネルで右クリック >「すべてのタスク」>「インポート...」
6. 「次へ」をクリック
7. 「参照...」をクリックし、ファイル名フィールドにコピーしたパスを貼り付け
8. 「開く」をクリック、次に「次へ」
9. 「証明書をすべて次のストアに配置する」が選択されていることを確認
10. ストアが「信頼されたルート証明機関」と表示されていることを確認
11. 「次へ」をクリック、次に「完了」
12. 確認を求められたら「はい」をクリック、次に「OK」

### 1.6. 共通要件

- **SMTP サーバー**: ログインメールの送信に必要です。Gmail を使用できます：
  1. Google アカウント > セキュリティ にアクセス
  2. 「2段階認証プロセス」を有効化
  3. セキュリティ > 2段階認証プロセス > アプリパスワード にアクセス
  4. 「メール」用のアプリパスワードを作成
  5. この16文字のパスワードを保存 - 後で必要になります

---

## パート 2: リポジトリのクローン

Hubs のコードをコンピュータにダウンロードしましょう。

### 2.1. Ubuntu ターミナルを開く

`Win` キーを押して「Ubuntu」と入力し、クリックして開きます。

### 2.2. プロジェクトの保存場所を選択

プロジェクトをホームフォルダに保存します：

```bash
cd ~
```
> このコマンドでホームフォルダ（例：`/home/yourname`）に移動します。

### 2.3. コードをダウンロード

```bash
git clone https://github.com/pf-hubs/chutvrc-hubs-cloud.git
```
> すべてのコードをダウンロードします。1分ほどかかる場合があります。

### 2.4. プロジェクトフォルダに移動

```bash
cd chutvrc-hubs-cloud/community-edition
```
> デプロイファイルがあるプロジェクトフォルダに移動します。

正しい場所にいるか確認するには：
```bash
ls
```
> `deploy_local.sh`、`render_hcce.sh`、`hcce.yam` などのファイルが表示されるはずです。

---

## パート 3: デプロイテンプレートの選択

異なるシナリオ用の設定ファイルがあります。

### ローカルデプロイメントの場合

**Chutvrc（カスタムバージョン）をデプロイする場合：**
```bash
cp hcce-chutvrc-local.yam hcce.yam
```

**Community Edition（標準版）をデプロイする場合：**
```bash
cp hcce-ce-local.yam hcce.yam
```

### Azure クラウドデプロイメントの場合

**Chutvrc をデプロイする場合：**
```bash
cp hcce-chutvrc.yam hcce.yam
```

**Community Edition をデプロイする場合：**
```bash
cp hcce-ce.yam hcce.yam
```

> **`cp` とは？** ファイルをコピーするコマンドです。ここではテンプレートファイルをコピーして `hcce.yam` という名前にしています。これはスクリプトが期待するファイル名です。

---

## パート 4: 設定の構成

### 4.1. base64 コマンドの修正（WSL/Linux では重要）

render スクリプトは Mac 固有のコマンドを使用しているため、Linux 用に変更が必要です。

ファイルを開く：
```bash
nano render_hcce.sh
```

以下の行を見つけます（`Ctrl + W` で検索）：
```bash
export initCert=$(base64 -i cert.pem | tr -d '\n')
export initKey=$(base64 -i key.pem | tr -d '\n')
```

以下のように変更（`-i` フラグを削除）：
```bash
export initCert=$(base64 cert.pem | tr -d '\n')
export initKey=$(base64 key.pem | tr -d '\n')
```

> **なぜ？** Mac の `base64` コマンドは入力ファイルに `-i` を使用しますが、Linux 版では必要ありません。

### 4.2. 設定を編集

エディタを開いたまま、以下の設定を見つけて変更してください：

#### ローカルデプロイメントの場合

以下の行を見つけて更新：
```bash
export HUB_DOMAIN="hubs.local"
export ADM_EMAIL="your-email@example.com"
```
> `your-email@example.com` を実際のメールアドレスに変更してください。

SMTP 設定を見つけて更新（Gmail の例）：
```bash
export SMTP_SERVER="smtp.gmail.com"
export SMTP_PORT="587"
export SMTP_USER="your-gmail@gmail.com"
export SMTP_PASS="your-16-char-app-password"
```
> Gmail アドレスと先ほど作成したアプリパスワードに置き換えてください。

#### Azure デプロイメントの場合

```bash
export HUB_DOMAIN="yourdomain.com"
export ADM_EMAIL="your-email@example.com"
```
> 実際のドメインとメールアドレスに変更してください。

以下も更新してください：
- `SMTP_*` 設定をメールプロバイダーの詳細に
- `DB_PASS` - セキュリティのためデフォルトから変更

### 4.3. 保存して閉じる

1. `Ctrl + O`（O はゼロではなく文字の O）を押して保存
2. `Enter` を押して確認
3. `Ctrl + X` を押して終了

---

## パート 5: 環境セットアップ

### オプション A: ローカルセットアップ

#### 5.1. hosts ファイルの設定

hosts ファイルは、`hubs.local` が自分のマシンを指すようにコンピュータに伝えます。

**重要:** ブラウザは Windows で実行されるため、**Windows** の hosts ファイル（WSL 内のものではなく）を編集します。

Ubuntu から以下のコマンドを実行して Windows の hosts ファイルを開く：
```bash
powershell.exe -Command "Start-Process notepad 'C:\Windows\System32\drivers\etc\hosts' -Verb RunAs"
```
> 管理者としてメモ帳が開きます。確認メッセージが表示されたら「はい」をクリックしてください。

ファイルの最後に以下の行を追加：
```
127.0.0.1   hubs.local
127.0.0.1   assets.hubs.local
127.0.0.1   cors.hubs.local
127.0.0.1   stream.hubs.local
```

ファイルを保存（Ctrl + S）してメモ帳を閉じてください。

#### 5.2. パート 6（デプロイ）に進む

### オプション B: Azure AKS セットアップ

#### 5.1. Azure CLI のインストール

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```
> Azure CLI をダウンロードしてインストールします。1分ほどかかる場合があります。

#### 5.2. Azure にログイン

```bash
az login
```
> URL とコードを含むメッセージが表示されます。
> 1. ブラウザを開いて表示された URL にアクセス
> 2. ターミナルに表示されたコードを入力
> 3. Azure アカウントでログイン

#### 5.3. リソースグループの作成

```bash
az group create --name HubsResourceGroup --location westeurope
```
> Azure リソースのコンテナを作成します。`westeurope` をお近くのリージョンに変更できます。

#### 5.4. ネットワークセキュリティグループの作成

Hubs に必要なポートを開くコマンド：

```bash
az network nsg create --resource-group HubsResourceGroup --name HubsNSG
```

```bash
az network nsg rule create --resource-group HubsResourceGroup --nsg-name HubsNSG --name AllowStream --priority 1000 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes '*' --destination-port-ranges 4443
```

```bash
az network nsg rule create --resource-group HubsResourceGroup --nsg-name HubsNSG --name AllowTurn --priority 1001 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes '*' --destination-port-ranges 5349
```

```bash
az network nsg rule create --resource-group HubsResourceGroup --nsg-name HubsNSG --name AllowUDP --priority 1002 --direction Inbound --access Allow --protocol Udp --source-address-prefixes '*' --destination-port-ranges 35000-60000
```

#### 5.5. Kubernetes クラスターの作成

```bash
az aks create -g HubsResourceGroup -s Standard_F2s_v2 -n HubsCluster -l westeurope --enable-node-public-ip --node-count 2 --network-plugin azure
```
> クラスターを作成します。5〜10分かかります。完了するまでお待ちください。

#### 5.6. kubectl を Azure に接続

```bash
az aks get-credentials --resource-group HubsResourceGroup --name HubsCluster
```
> kubectl が Azure クラスターと通信できるように設定します。

---

## パート 5.5: Kubernetes コンテキストの確認

デプロイ前に、kubectl が正しいクラスターを指しているか確認してください。

```bash
kubectl config current-context
```

表示されるべき内容：
- **ローカルの場合:** `docker-desktop`
- **Azure の場合:** `HubsCluster`

切り替えが必要な場合：
```bash
kubectl config get-contexts
```
> 利用可能なすべてのクラスターをリストします。

```bash
kubectl config use-context docker-desktop
```
> `docker-desktop` を使用したいクラスター名に変更してください。

---

## パート 6: デプロイ

### 6.1. ローカルへのデプロイ

正しいフォルダにいることを確認：
```bash
cd ~/chutvrc-hubs-cloud/community-edition
```

デプロイスクリプトを実行：
```bash
chmod +x deploy_local.sh
./deploy_local.sh
```
> 最初のコマンドはスクリプトを実行可能にします。2番目のコマンドで実行します。

デプロイが完了するまで待ちます。証明書の作成やサービスのデプロイに関するメッセージが表示されます。

#### デプロイ後

1. **ブラウザを完全に閉じる**（Windows タスクバーのブラウザアイコンを右クリック > すべてのウィンドウを閉じる）
2. ブラウザを開いて **https://hubs.local** にアクセス
3. Hubs のホームページが表示されるはずです！

> **注意:** 初回はすべてのサービスが起動するまで1分ほどかかる場合があります。

> **SSL 警告が表示される場合** パート 1.5（CA 証明書の Windows へのインポート）を完了したか確認してください。

### 6.2. Azure へのデプロイ

正しいフォルダにいることを確認：
```bash
cd ~/chutvrc-hubs-cloud/community-edition
```

デプロイを実行：
```bash
bash render_hcce.sh && kubectl apply -f hcce.yaml
```

サービスの起動を待つ：
```bash
kubectl get svc -n hcce
```
> `lb` サービスの `EXTERNAL-IP` に IP アドレスが表示されるまで、30秒ごとにこのコマンドを実行してください。

#### ドメインの設定

1. `EXTERNAL-IP` アドレスをコピー
2. ドメインレジストラ（ドメインを購入した場所）にアクセス
3. その IP を指す以下の DNS A レコードを作成：
   - `@`（またはルートドメインの場合は空白）
   - `assets`
   - `cors`
   - `stream`

#### SSL 証明書のセットアップ

1. `cbb.sh` をテキストエディタで開く：
   ```bash
   nano cbb.sh
   ```
2. メールアドレスとドメインを更新
3. 保存して終了（`Ctrl + O`、`Enter`、`Ctrl + X`）
4. 実行：
   ```bash
   bash cbb.sh
   ```

---

## パート 7: トラブルシューティング

### よくある問題

**「command not found」エラー**
- パート 1 ですべてのツールをインストールしたか確認
- Ubuntu ターミナルを閉じて再度開いてみる

**https://hubs.local にアクセスできない**
- Docker Desktop が実行中か確認（Windows システムトレイのクジラアイコン）
- Kubernetes が有効で実行中か確認（Docker Desktop で緑色のステータス）
- Docker Desktop の設定で Ubuntu の WSL 統合が有効か確認
- すべてのブラウザウィンドウを閉じて再度試す
- hosts ファイルのエントリを **Windows** の hosts ファイルに追加したか確認

**SSL 証明書が信頼されない（ブラウザ警告）**
- パート 1.5（CA 証明書の Windows へのインポート）を完了したか確認
- ブラウザを完全に閉じて再度開いてみる

**503 エラー**
- 数分待つ - サービスがまだ起動中の可能性があります
- Pod のステータスを確認：`kubectl get pods -n hcce`
- すべての Pod が「Running」ステータスを表示するはずです

**メールリンクが機能しない**
- `render_hcce.sh` の SMTP 設定を再確認
- Gmail の場合、通常のパスワードではなくアプリパスワードを使用しているか確認

**「base64: invalid option -- 'i'」エラー**
- パート 4.1 で base64 コマンドの修正を忘れています
- `render_hcce.sh` を編集して base64 コマンドから `-i` を削除してください

### 便利なコマンド

実行中のものを確認：
```bash
kubectl get pods -n hcce
```

特定のサービスのログを見る：
```bash
kubectl logs -n hcce deployment/reticulum
```

デプロイを再実行：
```bash
./deploy_local.sh
```

---

## パート 8: コスト管理（Azure のみ）

### クラスターを一時停止（節約）

Hubs を使用していないとき：
```bash
kubectl scale --replicas=0 deployment --all -n hcce
```

### クラスターを再開

再び使用したいとき：
```bash
kubectl scale --replicas=1 deployment --all -n hcce
```

### 予想コスト

Standard_F2s_v2 クラスターを24時間365日稼働させると、月額約80〜100ドルかかります。使用していないときに一時停止すると、コストを大幅に削減できます。
