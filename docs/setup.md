# 初期セットアップガイド

このガイドでは、PaperMC 1.21.1 を Docker Compose で運用するための初期セットアップ手順を説明します。

---

## 前提条件

以下のソフトウェアを事前にインストールしてください。

- Docker および Docker Compose
- Tailscale（管理アクセス用 VPN）
- mcrcon（RCON 接続テスト用）
- playit.gg アカウント（外部公開用トンネル）

---

## リポジトリ取得

```bash
git clone <リポジトリURL>
cd minecraft-server
```

---

## 環境変数の設定

`.env.example` をコピーして `.env` を作成します。

```bash
cp .env.example .env
```

`.env` を開き、各変数を設定します。

```
TAILSCALE_IP=your_tailscale_ip_here
MC_MEMORY=2048M
MC_OPS=your_username_here
RCON_PASSWORD=your_rcon_password_here
PLAYIT_SECRET=your_secret_here
```

| 変数名 | 説明 |
|---|---|
| `TAILSCALE_IP` | Tailscale が割り当てた自分のマシンの IP アドレス。RCON や Netdata へのアクセス制限に使用する。 |
| `MC_MEMORY` | Minecraft サーバーに割り当てるメモリ量。例: `2048M`、`4G`。 |
| `MC_OPS` | サーバーのオペレーター（OP）として登録する Minecraft ユーザー名。カンマ区切りで複数指定できる。 |
| `RCON_PASSWORD` | RCON 接続に使用するパスワード。バックアップスクリプトからも参照される。 |
| `PLAYIT_SECRET` | playit.gg エージェントの認証に使用するシークレットキー。 |

---

## Tailscale 設定

Tailscale をインストール・起動した後、以下のコマンドで自分のマシンの IPv4 アドレスを確認します。

```bash
tailscale ip -4
```

出力された IP アドレスを `TAILSCALE_IP` に設定します。

---

## playit.gg シークレットキーの取得

1. [https://playit.gg](https://playit.gg) にログインします。
2. ダッシュボードの「Agents」セクションを開きます。
3. 「Add Agent」をクリックして新しいエージェントを作成します。
4. エージェント作成後に表示されるシークレットキー（Secret Key）をコピーします。
5. コピーしたキーを `.env` の `PLAYIT_SECRET` に設定します。

---

## 初回起動・動作確認

### コンテナを起動する

```bash
docker compose up -d
```

### ヘルスチェックを確認する

```bash
docker compose ps
```

すべてのコンテナの `STATUS` が `healthy` になっていることを確認します。`starting` の場合はしばらく待ってから再度実行してください。

### RCON で接続テストする

```bash
mcrcon -H 127.0.0.1 -P 25575 -p <RCON_PASSWORD>
```

接続後、以下のコマンドでサーバーの状態を確認できます。

```
list
```

---

## DNS 設定（Cloudflare）

Cloudflare の DNS 管理画面で以下のレコードを追加します。

| タイプ | 名前 | 値 | プロキシ |
|---|---|---|---|
| CNAME | mc | submit-governance.gl.joinmc.link | オフ（DNS のみ） |
| SRV | _minecraft._tcp.mc | 優先度: 1 / 重み: 1 / ポート: 22353 / ターゲット: submit-governance.gl.at.ply.gg | オフ（DNS のみ） |

プロキシはいずれも無効（DNS のみ）にしてください。Minecraft の通信は Cloudflare プロキシを経由できません。

設定後、`mc.umikurage.com` でサーバーへ接続できます。

---

## Bedrock（統合版）接続設定

Switch やコンソール（PS4/PS5、Xbox）から接続する場合は、統合版（Bedrock Edition）用の設定が必要です。

### サーバーアドレス

| 項目 | 値 |
|---|---|
| サーバーアドレス | mc.umikurage.com |
| ポート | 19132 |

### Switch・コンソールでの接続手順

Switch および PS4/PS5、Xbox は、デフォルトでは任意のサーバーへの直接接続をブロックしています。接続するには、以下のいずれかの方法を使用してください。

- **BedrockConnect などのサードパーティ DNS を利用する方法**: フレンドサーバー一覧に表示される公式サーバーの IP を差し替えて、任意のサーバーへ接続できるようにします。詳細は [BedrockConnect](https://github.com/Pugmatt/BedrockConnect) を参照してください。

### 注意点

- Java Edition（PC）と Bedrock Edition（Switch・コンソール）はクロスプレイが可能ですが、一部の機能やコマンドの挙動が異なる場合があります。
- Bedrock のポートは UDP の `19132` です。ファイアウォールで UDP が許可されていることを確認してください。

---

## 初回接続後の確認チェックリスト

- [ ] `docker compose ps` ですべてのコンテナが `healthy` 状態になっている
- [ ] `mcrcon` で RCON 接続ができる
- [ ] Java Edition から `mc.umikurage.com` でサーバーに接続できる
- [ ] Bedrock Edition（統合版）からサーバーに接続できる
- [ ] `.env` の `MC_OPS` に設定したユーザーが OP 権限を持っている（ゲーム内で `/op` コマンドで確認）
- [ ] Tailscale 経由で Netdata（`http://<TAILSCALE_IP>:19999`）にアクセスできる
- [ ] Tailscale 経由で RCON（ポート `25575`）に接続できる
- [ ] バックアップコンテナが正常に動作している（`docker compose logs backups` でエラーがないことを確認）
