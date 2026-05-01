# 運用マニュアル

## サービス構成

| サービス名 | イメージ | 用途 |
|---|---|---|
| `mc` | PaperMC 1.21.11 | Minecraftサーバー本体 |
| `backups` | itzg/mc-backup | 自動バックアップ（12時間ごと） |
| `playit` | playit.gg agent | 外部公開トンネル |

---

## 1. サーバー起動・停止・再起動

```bash
# 全サービス起動
docker compose up -d

# 全サービス停止
docker compose down

# 全サービス再起動
docker compose restart

# 特定サービスのみ再起動
docker compose restart mc
docker compose restart backups
docker compose restart playit
```

---

## 2. コンテナ状態確認

```bash
# 全コンテナの状態確認
docker compose ps

# 詳細な状態（ヘルスチェック含む）
docker compose ps -a
```

出力例：

```
NAME         IMAGE                        STATUS
mc           itzg/minecraft-server        Up (healthy)
mc_backup    itzg/mc-backup               Up
playit       ghcr.io/playit-cloud/...     Up
```

---

## 3. ログ確認

```bash
# 全コンテナのログを追尾
docker compose logs -f

# 特定コンテナのログ
docker compose logs -f mc
docker compose logs -f backups
docker compose logs -f playit

# 直近100行のみ表示
docker compose logs --tail=100 mc

# タイムスタンプ付きで表示
docker compose logs -f --timestamps mc

# キーワードでフィルタリング
docker compose logs mc | grep "ERROR"
docker compose logs mc | grep "WARN"
docker compose logs mc | grep "joined the game"
docker compose logs mc | grep "left the game"

# バックアップ関連のログ確認
docker compose logs backups | grep -E "backup|error|warn"
```

---

## 4. RCON接続・ゲーム内コマンド実行

### 接続方法

RCON への接続には `mcrcon` を使用します。接続には Tailscale ネットワーク上にいる必要があります。

```bash
# 対話モードで接続
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード'

# コマンドを直接実行して終了
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'コマンド'

# 複数コマンドを一度に実行（-w は応答待機秒数）
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' -w 5 'say Hello'
```

### よく使うコマンド

```bash
# OP権限の付与
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'op <プレイヤー名>'

# OP権限の剥奪
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'deop <プレイヤー名>'

# プレイヤーをキック
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'kick <プレイヤー名> <理由>'

# プレイヤーをBAN
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'ban <プレイヤー名> <理由>'

# IPでBAN
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'ban-ip <プレイヤー名>'

# BANの解除
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'pardon <プレイヤー名>'

# ホワイトリストに追加
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'whitelist add <プレイヤー名>'

# ホワイトリストから削除
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'whitelist remove <プレイヤー名>'

# ホワイトリスト一覧
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'whitelist list'

# ワールドデータを手動保存
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'save-all'

# 全プレイヤーへのメッセージ送信
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'say <メッセージ>'

# 接続中のプレイヤー一覧
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'list'

# サーバー停止（Docker が restart: unless-stopped のため自動再起動されない）
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'stop'
```

---

## 5. バックアップ確認・手動バックアップ・リストア

### バックアップの確認

```bash
# バックアップファイル一覧
ls -lh ./backups/

# 最新のバックアップを確認
ls -lt ./backups/ | head -10

# バックアップの内容を確認（展開せずに）
tar -tzf ./backups/<ファイル名>.tar.gz | head -20
```

### 手動バックアップ

自動バックアップは 12 時間ごとに実行されますが、任意のタイミングで手動実行も可能です。

```bash
# バックアップコンテナを手動で実行
docker compose exec backups backup now
```

または、`save-all` してからデータディレクトリを直接アーカイブする方法：

```bash
# ゲームデータを保存
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'save-all'

# 手動でアーカイブ（ファイル名に日時を付ける）
tar -czf ./backups/manual_$(date +%Y%m%d_%H%M%S).tar.gz ./data/
```

### リストア手順

リストアはサーバーを停止してから実行します。

```bash
# 1. サーバーを停止
docker compose down

# 2. 現在のデータをバックアップ（念のため）
tar -czf ./backups/before_restore_$(date +%Y%m%d_%H%M%S).tar.gz ./data/

# 3. データディレクトリを削除または退避
mv ./data ./data_old

# 4. バックアップからリストア
mkdir ./data
tar -xzf ./backups/<リストアするファイル名>.tar.gz -C ./

# 5. サーバーを起動
docker compose up -d

# 6. 正常に起動したら退避したデータを削除
rm -rf ./data_old
```

---

## 6. リソース監視

```bash
docker stats mc
```

---

## 7. プラグイン追加・削除手順

### 追加

```bash
# 1. プラグインの JAR ファイルを配置
cp <プラグイン名>.jar ./data/plugins/

# 2. サーバーを再起動して読み込む
docker compose restart mc

# 3. 読み込みを確認
docker compose logs -f mc | grep -i "loading plugin\|enabling"
```

PaperMC はホットリロード非対応のプラグインが多いため、原則として再起動で読み込みます。

### 削除

```bash
# 1. JAR ファイルを削除（または plugins/disabled/ に移動）
rm ./data/plugins/<プラグイン名>.jar

# 不完全に無効化したい場合は disabled フォルダへ移動
mkdir -p ./data/plugins/disabled
mv ./data/plugins/<プラグイン名>.jar ./data/plugins/disabled/

# 2. サーバーを再起動
docker compose restart mc
```

プラグインのデータ（設定ファイル・DBなど）は `./data/plugins/<プラグイン名>/` に残ります。不要であれば手動で削除してください。

---

## 8. イメージ更新手順

### 最新イメージの取得と確認

```bash
# 1. 最新イメージを pull
docker compose pull

# 2. 取得したイメージのダイジェストを確認
docker inspect itzg/minecraft-server:latest --format '{{index .RepoDigests 0}}'
docker inspect itzg/mc-backup:latest --format '{{index .RepoDigests 0}}'
docker inspect ghcr.io/playit-cloud/playit-agent:latest --format '{{index .RepoDigests 0}}'
```

### docker-compose.yml のダイジェストを更新

`docker-compose.yml` 内の `image:` 行にある `@sha256:...` の部分を、上記で確認した新しいダイジェストに書き換えます。

例：

```yaml
image: itzg/minecraft-server@sha256:<新しいダイジェスト>
```

### 再起動して適用

```bash
# コンテナを再作成して起動
docker compose up -d --force-recreate

# 起動ログを確認
docker compose logs -f mc
```

### 古いイメージの削除

```bash
docker image prune -f
```

---

## 9. Bedrock（統合版）接続について

### 対応クライアント

- Nintendo Switch
- PlayStation 4 / PlayStation 5
- Xbox
- iOS / Android（Minecraft: Bedrock Edition）
- Windows 10/11（Minecraft for Windows）

### 接続情報

| 項目 | 値 |
|---|---|
| ホスト | playit.gg が発行するアドレス（または直接 IP） |
| ポート | 19132（UDP） |

`19132/UDP` はすべてのインターフェース（`0.0.0.0`）でリッスンしています。Java 版と同一のワールドに接続できます（Geyser / Floodgate プラグインが有効な場合）。

### Switch・コンソールからの接続手順

Switch など公式のサーバーリストに非公式サーバーを追加できない端末は、DNS 書き換えや dedicated server 経由での接続が必要な場合があります。playit.gg のトンネルを経由している場合は、playit のダッシュボードで発行されたアドレスとポートを使用してください。

### 注意事項

- Java 版と統合版でプレイヤー UUID が異なります。OP 付与や whitelist 追加は Bedrock 側のプレイヤー名（`floodgate:` プレフィックスが付く場合あり）で行います。
- Floodgate を使用している場合、統合版プレイヤーのデータは Java 版とは分離されます。

---

## 10. トラブルシューティング

### サーバーが起動しない

```bash
# ヘルスチェックの状態確認
docker compose ps

# 起動ログを確認
docker compose logs mc | tail -50
```

よくある原因：

- `EULA: "TRUE"` が未設定 → `docker-compose.yml` を確認
- ポート競合 → `ss -lntp | grep 25565` でポートの使用状況を確認
- メモリ不足 → `.env` の `MC_MEMORY` を減らす

### プレイヤーが接続できない

```bash
# コンテナが起動しているか確認
docker compose ps

# サーバーログで接続エラーを確認
docker compose logs mc | grep -E "ERROR|failed|refused"

# ポートのリッスン確認（Java版）
ss -lntp | grep 25565

# ポートのリッスン確認（Bedrock版）
ss -lnup | grep 19132
```

ホワイトリストが有効な場合は接続しようとしているプレイヤーが追加されているか確認してください。

```bash
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード' 'whitelist list'
```

### バックアップが実行されない

```bash
# バックアップコンテナの状態確認
docker compose ps backups

# バックアップのログ確認
docker compose logs backups | tail -30

# mc コンテナが healthy 状態か確認（backups は mc の healthcheck に依存）
docker inspect mc --format '{{.State.Health.Status}}'
```

### RCON に接続できない

```bash
# RCON ポートのリッスン確認
ss -lntp | grep 25575

# Tailscale の接続状態確認
tailscale status

# mc コンテナ内の RCON 設定確認
docker compose exec mc cat /data/server.properties | grep rcon
```

### ディスク容量不足

```bash
# ディスク使用量の確認
df -h

# データディレクトリの使用量
du -sh ./data/
du -sh ./backups/

# 古いバックアップを手動削除（14日より古いファイル）
find ./backups/ -name "*.tar.gz" -mtime +14 -delete
```

### コンテナが繰り返し再起動する（restart loop）

```bash
# 直近のログを確認
docker compose logs --tail=50 mc

# 再起動回数を確認
docker inspect mc --format '{{.RestartCount}}'

# 一時的に自動再起動を無効化して調査
docker compose stop mc
docker compose run --rm mc
```

### メモリ使用量が高い

`.env` の `MC_MEMORY` を調整します。

```bash
# 現在のメモリ設定確認
grep MC_MEMORY .env

# メモリ使用量のリアルタイム確認
docker stats mc
```
