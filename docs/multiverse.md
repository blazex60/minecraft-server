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

`first-spawn-location lobby` は新規プレイヤーの初回スポーンのみに適用されます。リスポーンは各ワールド内で行われるのがMultiverseのデフォルト動作です。

---

### 2. ワールド作成

ゲーム内またはRCONで実行します。

```
# ロビー
/mv create lobby NORMAL
/mv modify lobby set gamemode ADVENTURE

# 建築（スーパーフラット・クリエイティブ）
/mv create build NORMAL --world-type FLAT
/mv modify build set gamemode CREATIVE

# 公開サバイバル
/mv create survival NORMAL
/mv modify survival set gamemode SURVIVAL

```

### 3. スポーンをロビーに設定

**ロビーワールドに移動してから**実行します。

```
/mv setspawn
/mv config first-spawn-override true
/mv config first-spawn-location lobby
/mv config enforce-access false
```

### 4. インベントリ分離（Multiverse-Inventories）

`./data/plugins/Multiverse-Inventories/groups.yml` を編集：

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

移動以外のアクションをすべて禁止します。ポータルはエンティティの移動イベントで処理されるため、`use`/`interact` の制限を受けません。

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
/gamerule spawn_mobs false
/gamerule fire_spread_radius_around_player 0
/gamerule keep_inventory true
/gamerule advance_weather false
/weather clear
/gamerule advance_time false
/time set 6000
```

> **注意**: Multiverse-Core では `/mv modify` による天候固定設定はサポートされていません。天候の固定は上記のゲームルールで行ってください。

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
/mv entity-spawn-config modify <ワールド名> monster set spawn <true|false>

# 動物のスポーン
/mv entity-spawn-config modify <ワールド名> animal set spawn <true|false>
```

### ワールドの読み込み・アンロード

```
# アンロード（Multiverse管理から除外。フォルダは残る）
/mv unload <ワールド名>

# 再読み込み（5.x では import を使用）
/mv import <ワールド名> NORMAL
```

### ワールドの削除

```
# 削除（取り消し不可。確認コマンドが必要）
/mv delete <ワールド名>
/mv confirm
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
# enforce-accessが有効か確認
/mv config enforce-access

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
