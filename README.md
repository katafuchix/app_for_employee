# tebanashi

店舗管理・勤怠管理用 Flutter アプリケーション。

## アーキテクチャ設計

本プロジェクトでは、スケーラビリティとメンテナンス性を高めるため、**機能別（Feature-first）アーキテクチャ**を採用しています。
画面（View）やロジック（Model/Repository）を技術的なレイヤーで分けるのではなく、「勤怠」「マニュアル」「Todo」といった**機能（Feature）単位**でディレクトリを分割します。

### ディレクトリ構成

`lib/` 配下は以下の構造を目指してリファクタリングを行います。

```text
lib/
├── main.dart                # エントリーポイント
├── firebase_options.dart    # Firebase設定（自動生成）
│
├── core/                    # アプリ全体で共有するリソース
│   ├── theme/               # 色（app_colors.dart）、テーマ設定
│   ├── utils/               # 日付フォーマット等のヘルパー関数
│   └── components/          # 複数の機能で共通利用するUI部品（ボタン、ダイアログ等）
│
└── features/                # 各機能ごとのモジュール
    ├── auth/                # 認証機能 (Login, AuthGate)
    │   ├── views/           # UI (login_page.dart 等)
    │   └── services/        # 認証ロジック
    │
    ├── home/                # ホーム画面
    │   └── views/           # (home_page.dart)
    │
    ├── attendance/          # 勤怠管理機能
    │   ├── models/          # データ型 (WorkerClock, DailyWorkerScore)
    │   ├── repositories/    # Firestore通信 (AttendanceRepository)
    │   └── views/           # 画面・Widget (attendance_screen.dart)
    │
    ├── manual/              # マニュアル機能
    │   ├── models/
    │   └── views/
    │
    ├── shift/               # シフト確認機能
    │   ├── models/
    │   └── views/
    │
    └── todo/                # Todo管理機能
        ├── models/
        └── views/

```

### 構成要素の役割

各 `features` フォルダ内は、原則として以下の3つに分離します。

1. **views/**
* 画面（Screen）やその機能固有のWidgetを配置します。
* ロジックは極力ここに書かず、RepositoryやModelを利用する形にします。


2. **models/**
* Firestoreのドキュメントやアプリ内で扱うデータの型定義（Class）を配置します。
* `fromDoc` などの変換ロジックもここに含めます。


3. **repositories/** (または services/)
* FirestoreやFirebase Storage、Authとの通信ロジックを配置します。
* UIコードから直接 `FirebaseFirestore.instance` を呼ばないようにします。



---

## 命名規則 (Naming Conventions)

ファイル名やクラス名の不統一を防ぐため、以下のルールを適用します。

* **ファイル名**: `snake_case` (スネークケース)
* OK: `attendance_screen.dart`, `login_page.dart`
* NG: `AttendanceScreen.dart`, `LoginPage.dart`


* **クラス名**: `PascalCase` (アッパーキャメルケース)
* 例: `class AttendanceScreen ...`


* **変数・定数**: `camelCase` (ローワーキャメルケース)
* 定数の場合、Flutter推奨の `kPrefix` (例: `kTeal`) も許容しますが、可能な限り `AppColors.teal` のようなクラス定数への移行を推奨します。



---

## リファクタリング手順

現状のコードベースから新アーキテクチャへ移行するためのステップです。

1. **ファイル名のリネーム**
* 既存の `PascalCase.dart` ファイルをすべて `snake_case.dart` に変更する。


2. **Core層の作成**
* `lib/core/theme/app_colors.dart` を作成し、各ファイルに散らばっている色定義を集約する。


3. **Featuresフォルダの作成と移動**
* 各ファイルを `lib/features/xxx/views/` へ移動する。


4. **Model/Repositoryの分離**
* 各画面ファイル内に記述されているクラス（`WorkerClock`など）や通信処理を切り出し、`models/` や `repositories/` に配置する。



---

## Lint Format
```bash
dart format --set-exit-if-changed .
flutter analyze .
```