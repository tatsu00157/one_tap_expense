# プロジェクト概要: 1タップ支出管理アプリ (one_tap_expense)

## ⚠️ 重要：現在の開発スコープ（これ以外は絶対に作らないこと）
現在は【Phase 1：最初のリリース（無料版の基本UIとローカル保存）】のみに集中します。
Phase 2以降の機能（カテゴリーの追加・編集機能、CSV書き出し、固定費自動入力など）のコードは、現時点では一切記述しないでください。

---

## 開発ロードマップ

### 🎯 【現在進行中】Phase 1: 初回リリース仕様
まずはこの機能だけでアプリを完成させ、ストアに公開します。

1. **メイン入力画面（1画面目）**
   - 上部：今月の総支出額を表示（まずは数字のみ、後から `fl_chart` で円グラフ化）。
   - 中央：金額を入力するカスタムテンキー（0〜9、C、00など）。
   - 下部：固定のカテゴリーボタン4つ（「食費」「日用品」「交際費」「その他」）。
   - 操作：金額を入れてカテゴリーを1タップしたら、即座にローカルDB（`isar` または `hive`）に保存され、入力欄がリセットされる。
2. **履歴タイムライン画面（2画面目）**
   - 「日付・カテゴリー・金額」がシンプルに縦に並ぶ一覧画面。
3. **設定・課金画面（3画面目）**
   - 広告を消すための「Pro版（買い切り）」の購入ボタン（RevenueCat）。
   - **重要：** 画面内に「今後、カテゴリー編集機能や固定費自動入力などを追加予定。機能追加ごとに値上げしますが、今買った方は追加料金なしで使えます」というロードマップ（匂わせ）をテキストで明記する。
4. **広告の実装**
   - 無料版の履歴画面の下部に常時バナー広告を表示。

---

## 🚫 【バックログ】後から追加する機能（今は実装禁止）
以下の機能は、Phase 1がストアに公開された後に実装します。現在はコードを1行も書かないでください。

- **Phase 2（次の一手）：** カテゴリーのカスタマイズ機能（ユーザーが自由に名前や色を変更・追加・削除できるCRUD機能）
- **Phase 3（利便性向上）：** 固定費の自動入力（リピート機能）、入力忘れ防止のローカル通知
- **Phase 4（外部連携）：** CSV / Excelエクスポート機能

---

## 技術スタック（Phase 1用）
- データベース: `hive` / `hive_flutter`（採用済み）
- 課金管理: `purchases_flutter` (RevenueCat)
- 広告: `google_mobile_ads`

## 開発者特性＆ルール
- React Native (TypeScript) の経験あり。Flutter/Dartは初学者。
- 状態管理は、まずは最もシンプルな `setState` のみで画面ごとに完結させること（最初から複雑なアーキテクチャを持ち込まない）。
- コードを生成・修正する際は、必ず上記の「現在の開発スコープ」を守ること。

---

## 📍 現在の進捗状況（2026-05-19時点）

### ✅ Phase 1 コーディング完了
以下のファイルをすべて実装済み：

- `lib/main.dart` — Hive・AdMob・RevenueCat初期化、BottomNavigationBar（3タブ）、isPro状態管理
- `lib/screens/input_screen.dart` — カスタムテンキー、4カテゴリーボタン、Hive保存、月次合計表示
- `lib/screens/history_screen.dart` — 履歴一覧（新しい順）、バナー広告（無料ユーザーのみ）
- `lib/screens/settings_screen.dart` — Pro版購入ボタン・復元ボタン（RevenueCat）
- `android/app/src/main/AndroidManifest.xml` — AdMob App ID設定済み（テスト用ID）
- `ios/Runner/Info.plist` — GADApplicationIdentifier設定済み（テスト用ID）

### ✅ iOS・Android 実機テスト完了・追加機能実装済み
- iPhoneおよびAndroid端末で動作確認済み
- 以下の追加機能を実装・確認済み：
  - **履歴画面**：月ごとの表示切り替え（`<` `年月` `>`ナビゲーション）
  - **履歴画面**：左スワイプで削除ボタン表示 → タップで削除（誤操作防止）
  - **履歴画面**：メモがある場合は日付の下に表示
  - **入力画面**：日付選択（カレンダー、デフォルト今日の日付を表示）
  - **入力画面**：メモ欄（任意項目）
  - **日本語ロケール対応**：カレンダーが日本語表示

### ✅ 広告設定完了
- **AdMob App ID（Android）**：`android/app/src/main/AndroidManifest.xml` に設定済み
- **AdMob App ID（iOS）**：`ios/Runner/Info.plist` に設定済み
- **バナー広告ユニットID（Android・iOS）**：`lib/screens/history_screen.dart` に設定済み

### 🔜 次にやること：RevenueCat設定

**手順：**
1. App Store Connect / Google Play Console でアプリ・商品登録（ストア側設定）
2. RevenueCatダッシュボードでストアと連携
3. Entitlementを `pro` で作成、Productを作成（価格設定）
4. RevenueCat APIキー（iOS・Android各1つ）を取得
5. `lib/main.dart` の `_rcAndroidKey` / `_rcIosKey` を差し替え

**リリース前に対応するコード修正：**
- `google_mobile_ads` を `^5.0.0` → `^8.0.0` に更新（現在5.3.1で非推奨API警告が出ているため）
- `pubspec.yaml` のバージョンを変更後、`flutter pub upgrade` → `pod install --repo-update` を実行

### ⏳ 未実装（Phase 1仕様より）
- 設定画面内の「匂わせ」テキスト（表示場所・デザインは未定のため保留中）
