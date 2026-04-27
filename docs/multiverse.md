# Multiverse セットアップ・操作手順

## 必要なプラグイン

以下を [Hangar](https://hangar.papermc.io) からダウンロードして `./data/plugins/` に配置します。

| プラグイン | 用途 |
|---|---|
| [Multiverse-Core](https://hangar.papermc.io/Multiverse/Multiverse-Core) | ワールド管理（必須） |
| [Multiverse-Inventories](https://hangar.papermc.io/Multiverse/Multiverse-Inventories) | インベントリ分離 |
| [LuckPerms](https://luckperms.net/download) | アクセス権限管理 |

```bash
# プラグイン配置後にサーバー再起動
docker compose restart mc
```

---

## 初期セットアップ

### 1. ワールド作成

ゲーム内またはRCONで実行します。

```
# ロビー
/mv create lobby NORMAL
/mv modify set gamemode ADVENTURE lobby
/mv modify set allowweather false lobby

# 建築（スーパーフラット・クリエイティブ）
/mv create build NORMAL -t FLAT
/mv modify set gamemode CREATIVE build

# 公開サバイバル
/mv create survival NORMAL
/mv modify set gamemode SURVIVAL survival

# プライベート（権限制限あり）
/mv create private NORMAL
/mv modify set gamemode SURVIVAL private
/mv modify set permission multiverse.access.private private
```

### 2. スポーンをロビーに設定

**ロビーワールドに移動してから**実行します。

```
/mv setspawn
/mv conf firstspawnworld lobby
/mv conf enforceaccess true
```

### 3. インベントリ分離（Multiverse-Inventories）

`./data/plugins/Multiverse-Inventories/config.yml` を編集：

```yaml
groups:
  - name: lobby
    worlds:
      - lobby
    shares:
      - all_inventory
  - name: build
    worlds:
      - build
    shares:
      - all_inventory
  - name: survival
    worlds:
      - survival
    shares:
      - all_inventory
  - name: private
    worlds:
      - private
    shares:
      - all_inventory
```

編集後にリロード：

```
/mvinv reload
```

### 4. プライベートワールドの権限設定（LuckPerms）

```
# 特定プレイヤーにプライベートワールドへのアクセスを付与
/lp user <プレイヤー名> permission set multiverse.access.private true

# 権限の確認
/lp user <プレイヤー名> permission info

# 権限の剥奪
/lp user <プレイヤー名> permission unset multiverse.access.private
```

---

## 日常操作

### ワールド移動

```
# 自分が移動
/mv tp <ワールド名>

# 他プレイヤーを移動
/mv tp <プレイヤー名> <ワールド名>
```

### ワールド一覧確認

```
/mv list
```

### ワールド情報確認

```
/mv info <ワールド名>
```

### ワールド設定変更

```
# ゲームモード変更
/mv modify set gamemode <SURVIVAL|CREATIVE|ADVENTURE|SPECTATOR> <ワールド名>

# PvP設定
/mv modify set pvp <true|false> <ワールド名>

# モンスターのスポーン
/mv modify set monsters <true|false> <ワールド名>

# 動物のスポーン
/mv modify set animals <true|false> <ワールド名>
```

### ワールドの読み込み・アンロード

```
# アンロード（メモリから解放）
/mv unload <ワールド名>

# 再読み込み
/mv load <ワールド名>
```

### ワールドの削除

```
# 削除（取り消し不可）
/mv delete <ワールド名>
```

---

## RCON経由での操作

Tailscale経由でRCONに接続して実行できます。

```bash
# 接続
mcrcon -H 100.95.202.53 -P 25575 -p 'パスワード'

# ワールド一覧
/mv list

# プレイヤーを移動
/mv tp <プレイヤー名> survival
```

---

## トラブルシューティング

### プレイヤーがワールドに入れない

```
# enforceaccessが有効か確認
/mv conf enforceaccess

# プレイヤーの権限確認（LuckPerms）
/lp user <プレイヤー名> permission info
```

### インベントリが共有されてしまう

Multiverse-Inventories の config.yml でワールドが別グループに分かれているか確認し、`/mvinv reload` を実行します。

### ワールドが起動時に読み込まれない

```
# 自動読み込みを有効化
/mv modify set autoload true <ワールド名>
```
