# 設定リファレンス

## 環境変数（.env）

`.env` ファイルはリポジトリルートに配置し、docker-compose.yml から参照されます。

| 変数名 | デフォルト値 | 説明 |
|---|---|---|
| `TAILSCALE_IP` | （空） | Tailscale のIPアドレス。RCON（25575）のバインド先として使用する。管理者のみアクセス可能にするために Tailscale IP を指定する。 |
| `MC_MEMORY` | `2048M` | Minecraft サーバーに割り当てるヒープメモリ。`512M` `1024M` `2048M` `4096M` などの形式で指定する。 |
| `MC_OPS` | （空） | オペレーター権限を付与するプレイヤー名。複数指定する場合はカンマ区切り（例: `Alice,Bob`）。 |
| `RCON_PASSWORD` | （空） | RCON の認証パスワード。mc サービスと backups サービスで共有する。推測されにくい文字列を設定すること。 |
| `PLAYIT_SECRET` | （空） | playit.gg のシークレットキー。playit サービスが外部からのトンネルを確立するために使用する。 |

---

## docker-compose.yml サービス設定リファレンス

### mc（Minecraftサーバー）

| 設定項目 | 値 | 説明 |
|---|---|---|
| `EULA` | `TRUE` | Minecraft EULA への同意。起動に必須。 |
| `TYPE` | `PAPER` | サーバー種別。PaperMC を使用する。 |
| `VERSION` | `1.21.11` | Minecraft のバージョン。 |
| `LEVEL` | `world` | 初期ワールド（デフォルトワールド）のフォルダ名。 |
| `MEMORY` | `${MC_MEMORY}` | JVM ヒープメモリ。.env の `MC_MEMORY` を参照する。 |
| `MAX_PLAYERS` | `30` | 同時接続可能な最大プレイヤー数。 |
| `USE_AIKAR_FLAGS` | `true` | Aikar's GC フラグを有効化する。G1GC チューニングによりパフォーマンスが向上する。 |
| `USE_MEOWICE_FLAGS` | `true` | MeowIce の追加 JVM フラグを有効化する。 |
| `ENABLE_COMMAND_BLOCK` | `true` | コマンドブロックを有効化する。 |
| `TZ` | `Asia/Tokyo` | サーバーのタイムゾーン。ログのタイムスタンプに影響する。 |
| `OPS` | `${MC_OPS}` | オペレーター設定。.env の `MC_OPS` を参照する。 |
| `PLAYER_IDLE_TIMEOUT` | `300` | アイドル状態のプレイヤーを切断するまでの時間（分）。 |
| `MANAGEMENT_SERVER_ENABLED` | `false` | itzg/minecraft-server の管理用 HTTP サーバーを無効化する。 |
| `RCON_PASSWORD` | `${RCON_PASSWORD}` | RCON パスワード。.env の `RCON_PASSWORD` を参照する。 |

ボリューム: `./data:/data`（サーバーデータ全体をマウント）

### backups（自動バックアップ）

[itzg/mc-backup](https://github.com/itzg/mc-backup) イメージを使用した自動バックアップサービスです。

| 設定項目 | 値 | 説明 |
|---|---|---|
| `RCON_HOST` | `mc` | バックアップ前後に save-all / save-off を送る対象サービス名。 |
| `RCON_PASSWORD` | `${RCON_PASSWORD}` | RCON 認証パスワード。mc サービスと共通。 |
| `BACKUP_INTERVAL` | `12h` | バックアップの実行間隔。`h`（時間）`m`（分）で指定する。 |
| `INITIAL_DELAY` | `2m` | コンテナ起動後、最初のバックアップを実行するまでの待機時間。mc サービスの起動完了を待つために設定する。 |
| `DEST_DIR` | `/backups` | バックアップの保存先ディレクトリ（コンテナ内パス）。 |
| `SRC_DIR` | `/data` | バックアップ対象のディレクトリ（コンテナ内パス）。 |
| `BACKUP_METHOD` | `tar` | バックアップ形式。`tar` は圧縮アーカイブを生成する。 |
| `PRUNE_BACKUPS_DAYS` | `14` | 保持するバックアップの日数。この日数を超えた古いバックアップは自動削除される。 |

ボリューム:
- `./data:/data:ro`（読み取り専用でサーバーデータをマウント）
- `./backups:/backups`（バックアップ保存先）

### playit（外部公開トンネル）

[playit.gg](https://playit.gg) を利用した外部公開用トンネルサービスです。

- `PLAYIT_SECRET` に playit.gg で発行したシークレットキーを設定することで動作します。
- Java 版（25565）を外部プレイヤーへ公開する場合に使用します。

---

## ポート一覧

| ポート | プロトコル | バインド | 用途 |
|---|---|---|---|
| 25565 | TCP | 127.0.0.1 | Minecraft Java Edition（localhost のみ。外部公開は playit.gg 経由） |
| 25575 | TCP | TAILSCALE_IP | RCON（管理コマンド送信用。Tailscale 経由のみ） |
| 19132 | UDP | 0.0.0.0 | Minecraft Bedrock / 統合版（Switch・コンソール対応） |

---

## PaperMC 設定ファイル

設定ファイルはすべて `./data/` 以下に生成されます。

### bukkit.yml

| パラメーター | 設定値 | 説明 |
|---|---|---|
| `spawn-limits.monsters` | `70` | ワールド全体で同時スポーンできるモンスターの上限数。 |
| `spawn-limits.animals` | `10` | 通常の動物の上限数。 |
| `spawn-limits.water-animals` | `5` | 水中動物（イカなど）の上限数。 |
| `ticks-per.autosave` | `6000` | ワールドの自動保存間隔（tick）。6000 tick = 5 分。 |

### spigot.yml

| パラメーター | 設定値 | 説明 |
|---|---|---|
| `world-settings.default.view-distance` | `default` | クライアントへ送信するチャンクの描画距離。`default` は server.properties の値に従う。 |
| `settings.restart-on-crash` | `true` | サーバーがクラッシュした場合に自動再起動する。 |
| `settings.netty-threads` | `4` | ネットワーク処理に使用するスレッド数。コア数に応じて調整する。 |

### paper-global.yml

| パラメーター | 設定値 | 説明 |
|---|---|---|
| `misc.max-joins-per-tick` | `5` | 1 tick あたりに処理する接続要求の最大数。同時接続スパイクによる負荷を抑制する。 |
| `packet-limiter.max-packet-rate` | `500.0` | プレイヤーごとの最大パケットレート（パケット/秒）。 |
| `packet-limiter.max-packet-rate-check-interval` | `7`（秒） | パケットレートのチェック間隔。 |
| `spark.enabled` | `true` | パフォーマンスプロファイラー Spark を有効化する。`/spark` コマンドで使用可能。 |
| `update-checker.enabled` | `true` | PaperMC のアップデート確認を有効化する。 |

### paper-world-defaults.yml

| パラメーター | 設定値 | 説明 |
|---|---|---|
| `anticheat.anti-xray.enabled` | `false` | Anti-Xray を無効化。有効にするとサーバー負荷が上がるため、必要な場合のみ有効化する。 |
| `anticheat.anti-xray.engine-mode` | `1` | engine-mode 1 は露出している鉱石ブロックを偽装する軽量モード。 |
| `entities.spawning.per-player-mob-spawns` | `true` | モブのスポーンをプレイヤーごとに個別計算する。人数が増えてもモブ数が過剰になりにくくなる。 |
| `chunks.delay-chunk-unloads-by` | `10s` | チャンクのアンロードを遅延させる時間。頻繁な読み書きを減らし I/O 負荷を軽減する。 |

---

## 設定変更の反映方法

### 再起動が必要な設定

以下の設定はファイルを変更した後、コンテナの再起動が必要です。

```bash
docker compose restart mc
```

| 対象 | 理由 |
|---|---|
| `.env` の変更 | docker-compose が起動時に読み込むため。 |
| `docker-compose.yml` の変更 | `docker compose up -d` で再作成が必要。 |
| `server.properties` | 起動時にのみ読み込まれる。 |
| `spigot.yml` | 起動時にのみ読み込まれる。 |
| `paper-global.yml` | 起動時にのみ読み込まれる。 |
| `bukkit.yml`（spawn-limits 以外） | 起動時にのみ読み込まれる。 |
| JVM フラグ（`USE_AIKAR_FLAGS` など） | JVM 起動時にのみ適用される。 |

`docker-compose.yml` 自体を変更した場合は `restart` ではなく `up -d` で再作成します。

```bash
docker compose up -d mc
```

### /reload で反映できる設定

以下はゲーム内または RCON から `/reload confirm` を実行することで反映できます。ただし `/reload` はプラグインとの相性問題が発生することがあるため、再起動が可能な場合は再起動を優先することを推奨します。

| 対象 | コマンド |
|---|---|
| `bukkit.yml`（spawn-limits） | `/reload confirm` |
| `paper-world-defaults.yml` の一部 | `/reload confirm` |
| プラグインの設定ファイル | 各プラグインの reload コマンド（例: `/lp reload`、`/mvinv reload`） |

RCON 経由での `/reload` 実行例:

```bash
mcrcon -H <TAILSCALE_IP> -P 25575 -p '<RCON_PASSWORD>' 'reload confirm'
```

---

## メモリ設定の目安（MC_MEMORY）

`MC_MEMORY` に設定する値の目安です。プラグイン数やワールドサイズによっても変動します。

| 同時接続プレイヤー数 | 推奨メモリ | 備考 |
|---|---|---|
| 1〜5 人 | `1024M` | 軽量プラグイン構成の場合。 |
| 6〜15 人 | `2048M` | 現在のデフォルト設定。標準的な構成に適する。 |
| 16〜25 人 | `3072M` | 複数ワールド・多数プラグイン使用時。 |
| 26〜30 人（上限） | `4096M` | 高負荷構成やモッズ追加時に推奨。 |

Aikar's GC フラグ（`USE_AIKAR_FLAGS=true`）を使用しているため、割り当てたメモリのほぼ全量を JVM ヒープとして有効活用できます。ホストマシンの物理メモリの 70〜80% 以内に収めるようにしてください。

設定変更後は再起動が必要です。

```bash
# .env の MC_MEMORY を変更してから実行
docker compose up -d mc
```
