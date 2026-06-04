# RiskAndRune (ドット絵版)

本作は、テキストベースのローグライクRPGゲーム『markdown_rogue』のゲームシステムをベースに、キャラクターやエフェクトをドット絵（スプライトグラフィック）に差し替えることを目的としたプロジェクトです。

---

## 🎮 ゲーム概要
借金を抱えた主人公（`@`）が、ダンジョンで敵を倒して稼いだコインでギャンブルに挑み、さらに資金を増やして各ステージの「回収人（Lender）」に借金を完済していくアクションローグライクゲームです。完済するとボスが出現し、撃破することで強力な固有武器を獲得できます。

---

## 🛠️ コアシステムと機能一覧

### 1. 全8ステージ構成とポータル移動
- **FIELD** (草原): スロット & ブラックジャック
- **CAVE** (洞窟): ポーカー (ショップ/鍛冶屋)
- **HEAVEN** (天界): エンゼルレース (ショップ)
- **HELL** (地獄): デビルダイス (ショップ)
- **FOREST** (森林): フォーレストホイール (ショップ/鍛冶屋)
- **DESERT** (砂漠): デザートハイ＆ロー (ショップ/鍛冶屋)
- **OCEAN** (海洋): パールオイスター (ショップ)
- **SPACE** (宇宙): コズミッククラッシュ (ショップ)

### 2. 回復手段
- **ショップでの回復購入**: すべてのステージのショップで `HEAL (FULL HP)` を **8G** で購入して体力を全回復できます（すでに満タンの場合は購入不可）。
- **ボス撃破時の全回復**: 各ステージのボスを撃破すると、次の通常ウェーブが始まる前に自動的にHPが最大（5 HP）まで回復します。

### 3. ボス戦 & ボス武器報酬
回収人にステージごとの借金を返済（リペー）すると、その回収人がボスへと変貌します。ボスを倒すと返済額の2倍のコインをドロップし、以下の固有武器が解放されます：
- **SCYTHE** (FIELD): プレイヤーの周りを回転する鎌（` ) `）
- **DRILL** (CAVE): 前方に高速で放たれる貫通ドリル（` >>> `）
- **VINE WHIP** (FOREST): 左右の横方向に薙ぎ払う鞭（` \/ `）
- **SANDSTORM** (DESERT): プレイヤーの周囲に展開する継続砂嵐（` . `）
- **LIGHTNING** (HEAVEN): 最寄りの敵を自動追尾して天から降り注ぐ落雷（` V `）
- **TRIDENT** (OCEAN): 前方に扇状に放たれる3本の貫通三叉槍（` Ψ ` / ` ψ `）
- **DOOMSDAY** (HELL): 画面全体の敵に継続ダメージを与える炎（` f `）
- **BLACKHOLE** (SPACE): 敵を引き寄せつつ継続ダメージを与える重力場（` @ `）

### 4. 武器強化（鍛冶屋）
- **CAVE**, **FOREST**, **DESERT** に配置された `⚒️ FORGE` で、所持武器を **最大 Lv. 5** まで強化できます。

---

## 🎨 ドット絵化ロードマップ (ToDo)

テキストベース表示（Labelノードによる文字描画）からドット絵表示（Sprite2D / AnimatedSprite2D）への変換は以下の流れで実装していきます。

### 1. アセットの準備
- `assets/` フォルダを作成し、プレイヤー、敵、弾、ボス、回復薬などのドット絵スプライト画像（.png）を配置します。

### 2. キャラクター表示の変更
- `player.gd` および `main.gd` で、`Label` ノードを生成している箇所を `Sprite2D` ノードに差し替え、テクスチャを割り当てます。
- `enemy.gd` の `setup(type)` に合わせ、敵のタイプ（A〜J）やボスタイプに対応するドット絵テクスチャ（スプライトフレーム）に切り替える処理を記述します。

### 3. エフェクト・弾表示の変更
- プレイヤーの弾や敵の弾、ボスの攻撃ガイド線やビームエフェクトをスプライトアニメーションに変更します。


---

## 🌌 ポータルグラフィックのアセットについて

現在ゲーム内で使用されている各ステージ移行用のポータル画像には、**AI画像生成アセット**と**プログラム生成アセット**が混在しています。AIの生成制限（API枠制限）を回避するため、一部アセットは一時的に既存画像を元にプログラムで自動加工して「生成」したものです。**後日、制限解除後に個別のオリジナルアセットに差し替える予定**です。

### 1. 各アセットの元画像と加工分類
* **AI生成のオリジナルアセット (3種)**:
  * `sprite_portal_field.png` (草原用のツタが絡まる石の門)
  * `sprite_portal_cave.png` (洞窟用の暗い岩肌の穴)
  * `sprite_portal_heaven.png` (天界用の黄金の雲の門)
* **Pillow（Python）で加工生成したアセット (5種 - 将来差し替え予定)**:
  * `sprite_portal_hell.png` (`cave`ベース: 溶岩の赤・オレンジへ明度マッピング)
  * `sprite_portal_forest.png` (`field`ベース: 深い森のコケ緑や暗い樹木色へ色相シフト)
  * `sprite_portal_desert.png` (`cave`ベース: 砂岩の温かい砂漠色や金色へ明度マッピング)
  * `sprite_portal_ocean.png` (`heaven`ベース: 深海のブルーや水色へ色相シフト)
  * `sprite_portal_space.png` (`heaven`ベース: 宇宙の怪しい紫やネオンマゼンタへ色相シフト)

### 2. 画像アセットの仕様
* **解像度/サイズ**: 各画像は `1024x1024` ピクセルで保存されており、ゲーム実行時に `120x120` ピクセルに縮小描画されます。
* **背景色**: 完全に透過させるため、背景は純粋な白色（RGBがすべて235以上、つまり `r, g, b > 0.92`）で作成されています。
* **透過の仕組み（クロマキー）**:
  ゲーム実行時に [main.gd](file:///Users/IceTea/RiskAndRune/scripts/main.gd) の `_make_background_transparent()` 関数がピクセルごとにスキャンし、白色に近い領域を透明（`Color(0, 0, 0, 0)`）へ置換する処理を動的に行っています。新規にアセットを自作・再生成する際は、**背景をRGB(255, 255, 255)の純白色にして書き出す**必要があります。

### 3. AI画像生成用プロンプト (再生成用)
後日、制限がない環境で画像を個別に再生成する際は、以下のプロンプトを使用するとテイストを統一したまま背景を純白色に固定して生成できます。

* **FIELDポータル (`sprite_portal_field.png`)**
  > `Flat 16-bit RPG pixel art sprite of a green vine-covered stone archway, game portal entrance, isolated white background`
* **CAVEポータル (`sprite_portal_cave.png`)**
  > `Flat 16-bit RPG pixel art sprite of a dark stone cave entrance, game portal hole, isolated white background`
* **HEAVENポータル (`sprite_portal_heaven.png`)**
  > `Flat 16-bit RPG pixel art sprite of a glowing golden gate with soft clouds, holy game portal, isolated white background`
* **HELLポータル (`sprite_portal_hell.png`)**
  > `Flat 16-bit RPG pixel art sprite of a demonic dark stone gate with red lava, hell game portal, isolated white background`
* **FORESTポータル (`sprite_portal_forest.png`)**
  > `Flat 16-bit RPG pixel art sprite of a rustic leafy wooden archway, forest game portal, isolated white background`
* **DESERTポータル (`sprite_portal_desert.png`)**
  > `Flat 16-bit RPG pixel art sprite of a sandstone dune gate, desert game portal, isolated white background`
* **OCEANポータル (`sprite_portal_ocean.png`)**
  > `Flat 16-bit RPG pixel art sprite of a blue water whirlpool vortex, ocean game portal, isolated white background`
* **SPACEポータル (`sprite_portal_space.png`)**
  > `Flat 16-bit RPG pixel art sprite of a purple cosmic black hole vortex, space game portal, isolated white background`


---

## 🎵 効果音（SFX）生成用プロンプト

ギャンブルルームのスロットやブラックジャックで自動ロードされる各種 `.wav` 効果音ファイルを生成する際の推奨AIプロンプト（ElevenLabs Sound EffectsやSuno等のAI音響生成サービスに対応）です。

### 🎰 スロットマシン効果音
* **レバー操作音 (`sfx_lever.wav`)**
  > `Heavy mechanical lever pull, retro casino slot machine crank sound, arcade game button click, solid clunk, short, clean audio`
* **リール停止音 (`sfx_stop.wav`)**
  > `Sharp retro arcade game beep, clean mechanical snap, synthesizer woodblock strike, short, punchy, high-volume action response`
* **勝利音 (`sfx_win.wav`)**
  > `Retro arcade game win jingle, happy synthesizer chimes, pixel art coin pickup, celebratory retro melody, positive chime, clean loop`
* **敗北音 (`sfx_lose.wav`)**
  > `8-bit game over downer chime, classic retro game lose melody, descending synthesizer sad notes, flat fail sound, short, clean`

### 🃏 ブラックジャック効果音
* **カード配布音 (`sfx_deal.wav`)**
  > `Foley of a single playing card sliding quickly across a casino felt table, smooth paper friction, soft swoosh, dealer dealing cards`
* **カード追加（ヒット）音 (`sfx_hit.wav`)**
  > `Crisp playing card flip, drawing a card from deck, sharp paper snap on wooden table, dealer flicking a card, clean close-up audio`
* **引き分け（プッシュ）音 (`sfx_push.wav`)**
  > `Short neutral game jingle, 8-bit synthesizer chord, tie game sound, friendly coin return chime, neither win nor lose, clean, subtle`

---

## 🚀 実行方法

1. **Godot Engine 4.x** を起動します。
2. プロジェクトマネージャーで **「インポート (Import)」** を選択します。
3. このフォルダの **`project.godot`** を読み込み、エディタで開きます。
