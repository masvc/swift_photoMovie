# PhotoMovie App

## 概要

PhotoMovie は、iOS デバイスで写真を選択してスライドショー形式のムービーを作成できるシンプルなアプリケーションです。

## 主な機能

- 写真の複数選択（最大 10 枚）
- 選択した写真からムービーを自動生成（1 枚あたり 0.5 秒）
- 作成したムービーのプレビュー表示
- ムービーのカメラロールへの保存

## 技術スタック

- SwiftUI
- PhotosUI (写真選択)
- AVFoundation (ムービー作成)
- FileManager (ローカルストレージ管理)
- UserDefaults (メタデータ管理)

## プロジェクト構成
```
photoMovie/
├── photoMovie/
│ ├── Assets.xcassets/
│ │ ├── AccentColor.colorset/
│ │ ├── AppIcon.appiconset/
│ │ └── Contents.json
│ ├── ContentView.swift # メインビュー
│ ├── MovieMaker.swift # ムービー作成ロジック
│ ├── MoviePreviewView.swift # ムービープレビュー
│ ├── PhotoManager.swift # 写真管理
│ ├── Preview Content/
│ │ └── Preview Assets.xcassets/
│ └── photoMovieApp.swift # アプリケーションエントリーポイント
├── photoMovie.xcodeproj/
│ ├── project.pbxproj
│ ├── project.xcworkspace/
│ └── xcuserdata/
└── readme.md
```
## 必要な権限

- フォトライブラリへのアクセス権限（写真選択用）
- カメラロールへの保存権限（作成したムービーの保存用）

## 動作要件

- iOS 17.0 以上
- Xcode 15.0 以上

## 使用方法

1. アプリを起動
2. 「写真を選択」ボタンをタップ
3. 写真を選択（最大 10 枚）
4. 「ムービーを作成」ボタンをタップ
5. 作成されたムービーをプレビュー
6. プレビュー終了後、自動的にカメラロールに保存

## 開発メモ

- ムービー解像度: 1920x1080 (フル HD)
- フレームレート: 2fps（1 枚あたり 0.5 秒）
- 出力形式: MP4 (H.264)

## ライセンス

MIT License
