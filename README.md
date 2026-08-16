# 推しとStudy — Flutter iOS版

HTML POCをもとにしたiOS向けFlutterアプリです。

## 技術スタック

- **Flutter / Dart** — アプリ本体とUIの実装（Material・Cupertinoウィジェット）
- **iOS / Swift** — iOSネイティブ側のアプリ設定・起動処理
- **shared_preferences** — 学習セッション、教科、設定などの端末内保存
- **image_picker** — 写真ライブラリからの画像選択
- **path_provider** — 選択した画像のアプリ内ストレージへの保存
- **flutter_test** — ウィジェットテスト
- **flutter_lints** — Dartコードの静的解析・Lint

## Bundle ID

`com.ryushin.studycollection`

## 広告・プレミアムのリリース設定

開発ビルドではGoogle公式のテスト広告を使用します。本番リリース前に次を設定してください。

1. AdMobでiOSアプリとバナー広告ユニットを作成する
2. `ios/Runner/Info.plist`の`GADApplicationIdentifier`を本番App IDへ変更する
3. Releaseビルドでは本番広告ユニットID、DebugビルドではGoogle公式テストIDが自動で使われる
4. App Store Connectで非消耗型商品`com.ryushin.studycollection.remove_ads`を作成する
5. App Privacyの回答を広告SDKのデータ利用に合わせて更新する

本番広告ユニットIDが未指定の場合、リリースビルドでは広告枠を表示しません。

## 起動

```bash
flutter pub get
open -a Simulator
flutter run
```

## 現在実装済み

- 3画面の初回設定
- 10秒で完成するデバッグ用手帳
- 4種類の手帳柄と完成時間
- 写真ライブラリからの推し画像設定
- 編集可能な手帳タイトル
- ストップウォッチ（初期選択）
- 任意時間のカウントダウンタイマー
- アプリ復帰時にも経過時間を再計算する計測方式
- 白いヴェールが薄くなる現像進捗
- 教科の選択・追加・削除
- 学習セッションの端末内保存
- 今日・今週・合計・教科別統計
- 完成した手帳だけを保存するコレクション
- 未完成時の共有ロック
- 計測の一時停止・再開・記録せず取り消し
- 現在の手帳削除と全データ初期化

## 次の実装候補

- 写真上のデコ配置・移動・削除
- 完成フォトの画像生成とiOS共有シート
- 意見箱
- 教科名のインライン編集
- コレクションからの手帳再編集
- バックグラウンド計測に関する実機テスト
- アプリアイコン、スプラッシュ、正式名称
- App Store向け署名・プライバシー表示
