# Multiverse セットアップ・操作手順

## 必要なプラグイン

以下を [Hangar](https://hangar.papermc.io) からダウンロードして `./data/plugins/` に配置します。

| プラグイン | 用途 |
|---|---|
| [Multiverse-Core](https://hangar.papermc.io/Multiverse/Multiverse-Core) | ワールド管理（必須） |
| [Multiverse-Inventories](https://hangar.papermc.io/Multiverse/Multiverse-Inventories) | インベントリ分離 |
| [LuckPerms](https://luckperms.net/download) | アクセス権限管理 |
| [WorldGuard](https://dev.bukkit.org/projects/worldguard) | ロビーのアクション制限 |
| [WorldEdit](https://dev.bukkit.org/projects/worldedit) | WorldGuardの依存プラグイン |

```bash
# プラグイン配置後にサーバー再起動
docker compose restart mc
```

---

## 初期セットアップ

### 1. スポーン・リスポーンの仕様

| タイミング | 場所 |
|---|---|
| 初回接続（新規プレイヤー） | lobby |
| デス後のリスポーン | **現在いるワールド**（lobbyには戻らない） |
| ベッドがある場合 | ベッドのスポーン地点 |

`firstspawnworld lobby` は新規プレイヤーの初回スポーンのみに適用されます。リスポーンは各ワールド内で行われるのがMultiverseのデフォルト動作です。

---

### 2. ワールド作成

ゲーム内またはRCONで実行します。

```
# ロビー
/mv create lobby NORMAL
/mv modify lobby set gamemode ADVENTURE

# 建築（スーパーフラット・クリエイティブ）
/mv create build NORMAL -t FLAT
/mv modify build set gamemode CREATIVE

# 公開サバイバル
/mv create survival NORMAL
/mv modify survival set gamemode SURVIVAL

```

### 3. スポーンをロビーに設定

**ロビーワールドに移動してから**実行します。

```
/mv setspawn
/mv config firstspawnworld lobby
/mv config enforceaccess true
```

### 4. インベントリ分離（Multiverse-Inventories）

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

```

編集後にリロード：

```
/mvinv reload
```

### 5. ロビーの行動制限（WorldGuard）

移動とポータル利用のみ許可し、それ以外のアクションをすべて禁止します。

**lobbyワールドに移動してから**以下を実行します。

`__global__` はWorldGuardが各ワールドに自動で作成するグローバルリージョンです。WorldEdit選択不要で実行できます。

```
# ブロック破壊・設置を禁止
/rg flag __global__ block-break deny
/rg flag __global__ block-place deny

# アイテム使用・ブロック操作を禁止
/rg flag __global__ use deny
/rg flag __global__ interact deny

# PvP・ダメージを禁止
/rg flag __global__ pvp deny
/rg flag __global__ mob-damage deny

# ドロップ・拾いを禁止
/rg flag __global__ item-drop deny
/rg flag __global__ item-pickup deny

# ポータル（ネザー・エンド）の利用を許可
/rg flag __global__ use-portal allow
```

> **注意**: OP権限を持つプレイヤーはWorldGuardの制限をデフォルトでバイパスします。一般プレイヤーのみ制限が適用されます。

#### WorldGuard設定のコンフィグ化（自動化）

上記コマンドを実行すると、設定は以下のファイルに保存されます。

```
./data/plugins/WorldGuard/worlds/lobby/regions.yml
```

このファイルを事前に作成しておくことで、コマンド実行なしに設定を自動適用できます。

```yaml
# ./data/plugins/WorldGuard/worlds/lobby/regions.yml
regions:
  __global__:
    type: global
    priority: -1
    flags:
      block-break: deny
      block-place: deny
      use: deny
      interact: deny
      pvp: deny
      mob-damage: deny
      item-drop: deny
      item-pickup: deny
      use-portal: allow
    members:
      players: []
      groups: []
    owners:
      players: []
      groups: []
```

手順：
1. `./data/plugins/WorldGuard/worlds/lobby/` ディレクトリを作成
2. 上記内容で `regions.yml` を配置
3. サーバー起動後にWorldGuardがこのファイルを読み込みます

ゲームルールでモブスポーンや天候も無効化します（lobbyワールドで実行）：

```
/gamerule doMobSpawning false
/gamerule doFireTick false
/gamerule keepInventory true
/gamerule doWeatherCycle false
/weather clear
/gamerule doDaylightCycle false
/time set 6000
```

> **注意**: Multiverse-Core 4.x では `/mv modify` による `allowweather` 設定はサポートされていません。天候の固定は上記のゲームルールで行ってください。

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
/mv modify <ワールド名> set gamemode <SURVIVAL|CREATIVE|ADVENTURE|SPECTATOR>

# PvP設定
/mv modify <ワールド名> set pvp <true|false>

# モンスターのスポーン
/mv modify <ワールド名> set monsters <true|false>

# 動物のスポーン
/mv modify <ワールド名> set animals <true|false>
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
/mv config enforceaccess

# プレイヤーの権限確認（LuckPerms）
/lp user <プレイヤー名> permission info
```

### インベントリが共有されてしまう

Multiverse-Inventories の config.yml でワールドが別グループに分かれているか確認し、`/mvinv reload` を実行します。

### ワールドが起動時に読み込まれない

```
# 自動読み込みを有効化
/mv modify <ワールド名> set autoload true
```
