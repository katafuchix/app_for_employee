import 'meta_data_model.dart';

enum TodoDurationType { fixed, countable }

class ChecklistItem {
  final String id;
  final String content;

  ChecklistItem({required this.id, required this.content});

  factory ChecklistItem.fromMap(Map<String, dynamic> data) {
    return ChecklistItem(id: data['id'] ?? '', content: data['content'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'content': content};
  }
}

enum ImageSubmissionType {
  quality,
  service,
  cleanliness,
  tidiness,
  conservation,
  supply,
  other;

  factory ImageSubmissionType.fromValue(String value) {
    return ImageSubmissionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ImageSubmissionType.other,
    );
  }

  String get englishTitle {
    switch (this) {
      case ImageSubmissionType.quality:
        return 'Quality';
      case ImageSubmissionType.service:
        return 'Service';
      case ImageSubmissionType.cleanliness:
        return 'Cleanliness';
      case ImageSubmissionType.tidiness:
        return 'Tidiness';
      case ImageSubmissionType.conservation:
        return 'Conservation';
      case ImageSubmissionType.supply:
        return 'Supply';
      case ImageSubmissionType.other:
        return 'Other';
    }
  }

  String get title {
    switch (this) {
      case ImageSubmissionType.quality:
        return '品質';
      case ImageSubmissionType.service:
        return 'サービス';
      case ImageSubmissionType.cleanliness:
        return '清潔';
      case ImageSubmissionType.tidiness:
        return '整理整頓';
      case ImageSubmissionType.conservation:
        return '省エネ';
      case ImageSubmissionType.supply:
        return '供給';
      case ImageSubmissionType.other:
        return 'その他';
    }
  }
}

class ImageSubmissionInfo {
  final String id;
  final String title;
  final ImageSubmissionType imageType;
  final bool isRequired;

  const ImageSubmissionInfo({
    required this.id,
    required this.title,
    required this.imageType,
    required this.isRequired,
  });

  factory ImageSubmissionInfo.fromMap(Map<String, dynamic> data, int index) {
    final id = (data['id'] as String?)?.trim();
    return ImageSubmissionInfo(
      id: (id != null && id.isNotEmpty)
          ? id
          : 'fallback_image_submission_$index',
      title: data['title'] ?? '',
      imageType: ImageSubmissionType.fromValue(
        data['image_type'] as String? ?? '',
      ),
      isRequired: data['is_required'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image_type': imageType.name,
      'is_required': isRequired,
    };
  }
}

class Todo {
  final String id;
  final String title;
  final int durationMinute;
  final int difficulty;
  final bool isSkippable;
  final Metadata metadata;

  final String detail;
  final bool useDetail;
  final String shortManual;
  final bool useShortManual;

  final TodoDurationType durationType;
  final String countableTitle;
  final int countableDurationPerOne;
  final String countableCountUnit;

  final List<ChecklistItem> completionChecklist;
  final bool useCompletionChecklist;
  final List<String> manualIds;
  final List<ImageSubmissionInfo> imageSubmissionInfos;

  Todo({
    required this.id,
    required this.title,
    required this.durationMinute,
    required this.difficulty,
    required this.isSkippable,
    required this.metadata,
    required this.detail,
    required this.useDetail,
    required this.shortManual,
    required this.useShortManual,
    required this.durationType,
    required this.countableTitle,
    required this.countableDurationPerOne,
    required this.countableCountUnit,
    required this.completionChecklist,
    required this.useCompletionChecklist,
    required this.manualIds,
    required this.imageSubmissionInfos,
  });

  static Todo? fromMap(Map<String, dynamic> data, String docId) {
    try {
      if (docId.isEmpty) {
        return null;
      }
      final typeStr = data['duration_type'] as String? ?? 'fixed';
      final durationType = typeStr == 'countable'
          ? TodoDurationType.countable
          : TodoDurationType.fixed;

      final checklistRawList =
          data['completion_checklist'] as List<dynamic>? ?? [];
      final checklist = checklistRawList.asMap().entries.map((entry) {
        final index = entry.key;
        final itemData = entry.value as Map<String, dynamic>? ?? {};
        var id = itemData['id'] as String? ?? '';
        if (id.isEmpty) {
          id = 'fallback_index_$index';
        }
        return ChecklistItem.fromMap({...itemData, 'id': id});
      }).toList();

      final rawImageInfos =
          data['image_submission_infos'] as List<dynamic>? ?? [];
      final imageSubmissionInfos = rawImageInfos.asMap().entries.map((entry) {
        final item = entry.value as Map<String, dynamic>? ?? {};
        return ImageSubmissionInfo.fromMap(item, entry.key);
      }).toList();

      return Todo(
        id: docId,
        title: data['title'] ?? '',
        durationMinute: (data['duration_minute'] as num?)?.toInt() ?? 0,
        difficulty: (data['difficulty'] as num?)?.toInt() ?? 0,
        isSkippable: data['is_skippable'] ?? false,
        metadata: data['metadata'] != null
            ? Metadata.fromMap(data['metadata'] as Map<String, dynamic>)
            : Metadata.empty(),
        detail: data['detail'] ?? '',
        useDetail: data['use_detail'] ?? false,
        shortManual: data['short_manual'] ?? '',
        useShortManual: data['use_short_manual'] ?? false,
        durationType: durationType,
        countableTitle: data['countable_title'] ?? '',
        countableDurationPerOne:
            (data['countable_duration_per_one'] as num?)?.toInt() ?? 0,
        countableCountUnit: data['countable_count_unit'] ?? '',
        completionChecklist: checklist,
        useCompletionChecklist: data['use_completion_checklist'] ?? false,
        manualIds: List<String>.from(data['manual_ids'] ?? []),
        imageSubmissionInfos: imageSubmissionInfos,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    final durationTypeStr = durationType == TodoDurationType.countable
        ? 'countable'
        : 'fixed';

    return {
      'title': title,
      'duration_minute': durationMinute,
      'difficulty': difficulty,
      'is_skippable': isSkippable,
      'metadata': metadata.toMap(),
      'detail': detail,
      'use_detail': useDetail,
      'short_manual': shortManual,
      'use_short_manual': useShortManual,
      'duration_type': durationTypeStr,
      'countable_title': countableTitle,
      'countable_duration_per_one': countableDurationPerOne,
      'countable_count_unit': countableCountUnit,
      'completion_checklist': completionChecklist
          .map((e) => e.toMap())
          .toList(),
      'use_completion_checklist': useCompletionChecklist,
      'manual_ids': manualIds,
      'image_submission_infos': imageSubmissionInfos
          .map((e) => e.toMap())
          .toList(),
    };
  }
}
