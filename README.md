# Minecraft Server

PaperMC (Java Edition) を Docker Compose で運用するサーバー構成です。

## 構成

```
┌─────────────────────────────────────────────────┐
│  外部プレイヤー                                    │
│  mc.umikurage.com → playit.gg トンネル            │
└───────────────────────┬─────────────────────────┘
                        │ TCP (SRV: port 22353)
┌───────────────────────▼─────────────────────────┐
│  Docker ホスト                                    │
│                                                   │
│  ┌──────────┐   RCON    ┌──────────────────────┐ │
│  │  mc      │◄──────────│  mc_backup           │ │
│  │ PaperMC  │           │  itzg/mc-backup      │ │
│  │ 1.21.11  │           │  12時間ごとバックアップ  │ │
│  └──────────┘           └──────────────────────┘ │
│  127.0.0.1:25565                                  │
│  100.95.202.53:25575 (RCON via Tailscale)         │
│                                                   │
│  ┌──────────────────────────────────────────────┐ │
│  │  playit (network_mode: host)                 │ │
│  │  playit.gg エージェント                        │ │
│  │  → 127.0.0.1:25565 に転送                    │ │
│  └──────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## サービス一覧

| サービス | イメージ | 役割 |
|---|---|---|
| `mc` | `itzg/minecraft-server` | PaperMC 1.21.11 |
| `mc_backup` | `itzg/mc-backup` | 自動バックアップ（12時間ごと） |
| `playit` | `ghcr.io/playit-cloud/playit-agent` | 外部公開トンネル |

## セットアップ

### 1. 必要なもの

- Docker / Docker Compose
- playit.gg アカウント（[https://playit.gg](https://playit.gg)）

### 2. 環境変数の設定

```bash
cp .env.example .env
```

`.env` を編集して値を入力：

```env
# Minecraft オペレーター（カンマ区切りで複数指定可）
MC_OPS=your_username

# Minecraft RCON パスワード
RCON_PASSWORD=your_rcon_password

# playit.gg シークレットキー
PLAYIT_SECRET=your_secret_key
```

### 3. 起動

```bash
docker compose up -d
```

### 4. 停止

```bash
docker compose down
```

## DNS 設定（Cloudflare）

`mc.umikurage.com` でのアクセスには以下のDNSレコードが必要です。

| タイプ | 名前 | 値 | プロキシ |
|---|---|---|---|
| CNAME | `mc` | `submit-governance.gl.joinmc.link` | オフ |
| SRV | `_minecraft._tcp.mc` | `1 1 22353 submit-governance.gl.at.ply.gg` | オフ |

## RCON 接続（管理用）

Tailscale 経由でのみアクセス可能です（ポート 25575）。

```bash
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' -w 5
```

## バックアップ

- **間隔**: 12時間ごと
- **保存先**: `./backups/`
- **保持期間**: 14日間
- **形式**: tar.gz

バックアップは RCON 経由でサーバーにセーブを指示してから取得されます。

## プラグイン

プラグインは `./data/plugins/` に JAR ファイルを配置して再起動で導入できます。

### 予定プラグイン構成

| プラグイン | 用途 |
|---|---|
| Multiverse-Core | 複数ワールド管理 |
| Multiverse-Inventories | ワールドごとのインベントリ分離 |
| LuckPerms | 権限管理（プライベートワールドのアクセス制限） |

### ワールド構成（予定）

| ワールド | モード | 説明 |
|---|---|---|
| `lobby` | アドベンチャー | スポーン地点 |
| `build` | クリエイティブ / スーパーフラット | 建築ワールド |
| `survival` | サバイバル | 公開サバイバル |
| `private` | サバイバル | 権限制限あり |

## イメージバージョン管理

全イメージは SHA256 ダイジェストで固定されています。更新する場合：

```bash
# 新しいイメージを取得
docker compose pull

# 新しいダイジェストを確認
docker inspect <image> --format '{{index .RepoDigests 0}}'

# docker-compose.yml のダイジェストを更新して再起動
docker compose up -d
```

## ドキュメント

- [Multiverse セットアップ・操作手順](docs/multiverse.md)

## gitignore について

以下はバージョン管理対象外です：

- `.env`（認証情報）
- `./data/`（サーバーデータ）
- `./backups/`（バックアップファイル）
- `.omc/`（AI ツール内部状態）
