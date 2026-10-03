// manual_models.dart
class Manual {
  final String manualId;
  final String title;
  final int index;
  final int viewCount;
  final String createdDate;
  final String updatedDate;
  final bool isAuto;
  final List<StepItem> steps;

  // カテゴリー・フォルダ紐付け用
  final String categoryId;
  final String folderId;

  const Manual({
    required this.manualId,
    required this.title,
    required this.index,
    required this.viewCount,
    required this.createdDate,
    required this.updatedDate,
    required this.isAuto,
    required this.steps,
    required this.categoryId,
    required this.folderId,
  });

  int get stepCount => steps.length;
  int get imageTotal =>
      steps.fold(0, (sum, step) => sum + step.imageIds.length);
  int get manualNo => index + 1;
}

class StepItem {
  final int stepNo;
  final bool useTitle;
  final String title;
  final String content;
  final bool useUrl;
  final String url;
  final List<String> imageIds;

  const StepItem({
    required this.stepNo,
    required this.useTitle,
    required this.title,
    required this.content,
    required this.useUrl,
    required this.url,
    required this.imageIds,
  });
}

// カテゴリーモデル
class ManualCategory {
  final String id;
  final String title;
  final String color; // 色コード文字列など
  final List<ManualFolder> folders;
  final DateTime? firstInteractionTime; // ソート用

  const ManualCategory({
    required this.id,
    required this.title,
    required this.color,
    required this.folders,
    this.firstInteractionTime,
  });
}

// フォルダモデル
class ManualFolder {
  final String id;
  final String title;
  final DateTime? firstInteractionTime; // ソート用

  const ManualFolder({
    required this.id,
    required this.title,
    this.firstInteractionTime,
  });
}

// UI表示用に階層化されたデータ構造
class CategoryWithContent {
  final ManualCategory category;
  final List<FolderWithContent> folders;
  // フォルダに属さないマニュアルがある場合用（今回はPDF仕様に従いフォルダ分け前提で実装しますが、念のため）
  final List<Manual> uncategorizedManuals;

  const CategoryWithContent({
    required this.category,
    required this.folders,
    required this.uncategorizedManuals,
  });
}

class FolderWithContent {
  final ManualFolder folder;
  final List<Manual> manuals;

  const FolderWithContent({required this.folder, required this.manuals});
}
