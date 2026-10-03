## Todo画像提出機能の修正・実装タスク一覧

### 1. データ構造の変更対応
`todo_mapping`から取得するTodoのデータ形式の変更に対応する [cite: 3, 5]。
新しく追加された `image_submission_infos` 配列を取得する [cite: 17, 43]。
従来の `is_image_required` は判定に使用せず、取得もしないように変更する [cite: 44]。

### 2. UI表示の改修（提出画面）
画像の提出枠を単一から複数枚対応に変更する [cite: 44, 46]。
`image_submission_infos` の各要素の `title` を、撮影指示のテキストとして表示する（例：「ポットを止めているところの写真」） [cite: 47, 48, 62]。
要素の `image_type`（String型、"quality" や "conservation" など7種類）に応じて条件分岐を作成し、対応する英語タイトルと日本語タイトルを表示する（Dartのenum等を活用する） [cite: 63, 64]。
要素の `is_required` に応じてUIを出し分ける。必須の場合は「黄色」で、任意の場合は「灰色」でラベル等を表示する [cite: 65, 74]。

### 3. 画像の撮影・選択とデータ紐付け
要素（提出枠）ごとにカメラ等で画像を登録できるようにする [cite: 75]。
（提出前表示において）登録した画像を削除できるバツボタンなどを配置する [cite: 103]。
提出時に利用するため、登録した画像データに対して `image_submission_infos` の各要素の `id` を紐付けて保持する [cite: 75]。

### 4. 完了（提出）処理の実装
提出ボタン押下時などに、`is_required` が true になっている要素の画像が全て登録されているかバリデーションチェックを行う [cite: 74, 77]。
必須画像が不足している場合は、ボタンを非活性にするか警告を出すなどして、提出できないよう制御する [cite: 77]。
Firebase Storageへの画像アップロードパスを以下のように変更する [cite: 81, 82, 83]。
    **変更前:** `store_data/{store_id}/todo_execution/{todo_execution_info_id}` [cite: 78, 79]
    **変更後:** `store_data/{store_id}/todo_execution/{todo_execution_info_id}/{image_submission_info_id}` [cite: 82, 84]
`todo_execution_info` 送信時に以下の値を設定する [cite: 85]。
    `submission_image_ids`: 提出した画像に紐づく `image_submission_infos` の `id` のリストを含める [cite: 85, 96]。
    `is_image_send`: 画像が1枚でも提出されている場合は `true` に設定する [cite: 86, 95]。

### 5. 実施済みTodoの表示処理
`todo_execution_infos` の取得時に、必ず `submission_image_ids` も取得する [cite: 102]。
取得した `submission_image_ids` を用いて、Firebase Storageから各画像をロードして表示する [cite: 102]。
画像のIDと `image_submission_infos` の要素を照合し、それぞれの要素（タイトル等）と画像を紐付けて画面に表示する [cite: 104]。
IDが一致する `image_submission_infos` の要素が見つからない画像データが存在した場合は、「その他」の枠として表示する [cite: 104]。