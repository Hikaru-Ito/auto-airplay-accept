# AirPlay Auto Accept

> Macで AirPlay 受信ダイアログの「受け入れる」を自動でクリックする、小さなバックグラウンドアプリ。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-11%2B-black.svg)](https://www.apple.com/macos/)
[![Made with AppleScript](https://img.shields.io/badge/Made_with-AppleScript-lightgrey.svg)]()

iPhone や iPad から Mac に AirPlay するとき、毎回出てくる「受け入れる / 辞退」のダイアログ。何度も同じデバイスから繋いでいるのに、毎回クリックを求められる。

このアプリを起動しておくだけで、そのクリックを自動でやってくれます。

## ✨ 特徴

- **ゼロ・インタラクション** — AirPlayダイアログが出た瞬間に自動で「受け入れる」をクリック
- **日本語・英語対応** — 「受け入れる」「Accept」「許可」「Allow」のいずれにも対応
- **完全バックグラウンド** — Dock にもメニューバーにも表示されない
- **軽量** — AppleScriptベース。CPU/メモリ消費はごくわずか
- **オープンソース** — 中身は数十行。コードを読んでから使える

## 📦 インストール

### バイナリで使う場合

1. [Releases ページ](https://github.com/Hikaru-Ito/auto-airplay-accept/releases/latest) から最新の `AirPlayAutoAccept-x.y.z.dmg` をダウンロード
2. DMGを開いて、`AirPlay Auto Accept.app` を `Applications` にドラッグ
3. 初回起動時、**右クリック → 開く** で起動（未署名アプリのため、ダブルクリックではGatekeeperに弾かれます）
4. アクセシビリティ権限を求められるので許可
   - システム設定 → プライバシーとセキュリティ → アクセシビリティ で `AirPlay Auto Accept` を ON
5. （任意）システム設定 → 一般 → ログイン項目 に追加して、Mac起動時に自動で常駐させる

### ソースからビルドする場合

```bash
git clone https://github.com/Hikaru-Ito/auto-airplay-accept.git
cd auto-airplay-accept
./scripts/build.sh
open "dist/AirPlay Auto Accept.app"
```

ビルドには macOS 標準の `osacompile` と `PlistBuddy` だけを使います。追加の依存はありません。

## 🛠 仕組み

1. `osacompile -s` で AppleScript を **stay-open アプレット** としてコンパイル
2. アプレットは `on idle` ハンドラで1秒おきにシステム上のプロセスを巡回
3. `ControlCenter` などのプロセスにダイアログがあるか確認し、見つけたら `click button "受け入れる"` を実行
4. `LSUIElement = true` を Info.plist に追加することで、Dock/メニューバー非表示で常駐

実装の本体は [`src/main.applescript`](src/main.applescript) にあり、わずか40行ほどです。

## ⚙️ 設定

ポーリング間隔を変更したい場合は、`src/main.applescript` の `pollInterval` プロパティを編集してビルドしてください（デフォルトは1秒）。

検出するボタンのラベルや、巡回するプロセス名も同ファイルの上部で定義されているので、自分の環境に合わせて追加できます。

## 🐛 トラブルシューティング

### 自動クリックされない

1. **アクセシビリティ権限が許可されているか確認**
   システム設定 → プライバシーとセキュリティ → アクセシビリティ で `AirPlay Auto Accept` がリストに入っていて、トグルが ON か確認してください。
2. **アプリが起動しているか確認**
   ```bash
   pgrep -f "AirPlay Auto Accept"
   ```
   何も返らない場合、アプリは終了しています。
3. **ダイアログを出しているプロセス名を確認**
   ダイアログが表示されている状態で、以下を実行：
   ```bash
   osascript -e 'tell application "System Events" to get name of every process whose visible is true'
   ```
   出力されたプロセス名を `src/main.applescript` の `candidateProcesses` に追加し、再ビルドしてください。

### 「開発元が確認できません」というエラーが出る

ad-hoc 署名のみで Apple Developer 署名はしていないため、Gatekeeper が警告を出します。

- 初回起動時のみ、**右クリック → 開く** で起動してください
- それでも開かない場合：
  ```bash
  xattr -d com.apple.quarantine "/Applications/AirPlay Auto Accept.app"
  ```

### アンインストール

1. `/Applications/AirPlay Auto Accept.app` を削除
2. システム設定 → 一般 → ログイン項目 から削除（追加していた場合）
3. システム設定 → プライバシーとセキュリティ → アクセシビリティ からエントリを削除

## 🧪 開発

### ビルド

```bash
./scripts/build.sh
```

出力: `dist/AirPlay Auto Accept.app`

### DMGパッケージ作成

```bash
./scripts/package-dmg.sh
```

出力: `dist/AirPlayAutoAccept-x.y.z.dmg`

### バージョン指定

```bash
VERSION=1.1.0 ./scripts/build.sh
VERSION=1.1.0 ./scripts/package-dmg.sh
```

## 📁 プロジェクト構成

```
.
├── src/
│   └── main.applescript        # アプリ本体（AppleScript）
├── scripts/
│   ├── build.sh                # .app のビルド
│   └── package-dmg.sh          # 配布用DMG作成
├── website/
│   └── index.html              # 配布用ランディングページ
├── dist/                       # ビルド成果物（gitignore）
├── LICENSE
└── README.md
```

## 🤝 Contributing

バグ報告や Pull Request は歓迎です。

- 新しい言語のボタンラベルを追加したい
- 別のAirPlay系ダイアログにも対応させたい
- アイコンをデザインしたい

そんな貢献を待っています。

## 📄 License

[MIT License](LICENSE) © 2026 Hikaru Ito

## 🙏 こんな人に届け

- 会議のたびにAirPlayでスクリーン共有している人
- 自宅のApple TVがわりにMacで動画を流している人
- 「あの小さなクリックも積もれば...」と思ってしまうエンジニア
