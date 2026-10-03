import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tebanashi/features/operation/models/todo_execution_model.dart';
import 'package:tebanashi/features/operation/models/todo_model.dart';

void main() {
  group('Todo.fromMap', () {
    test(
      'parses imageSubmissionInfos and ignores legacy is_image_required',
      () {
        final todo = Todo.fromMap({
          'title': 'Close kitchen',
          'duration_minute': 15,
          'difficulty': 2,
          'is_skippable': true,
          'detail': 'detail',
          'use_detail': true,
          'short_manual': '',
          'use_short_manual': false,
          'duration_type': 'fixed',
          'countable_title': '',
          'countable_duration_per_one': 0,
          'countable_count_unit': '',
          'completion_checklist': const [],
          'use_completion_checklist': false,
          'manual_ids': const [],
          'is_image_required': true,
          'image_submission_infos': [
            {
              'id': 'quality_1',
              'title': 'ポットを止めているところの写真',
              'image_type': 'quality',
              'is_required': true,
            },
            {
              'id': 'mystery',
              'title': '不明タイプ',
              'image_type': 'unknown_value',
              'is_required': false,
            },
          ],
        }, 'todo_1')!;

        expect(todo.imageSubmissionInfos, hasLength(2));
        expect(
          todo.imageSubmissionInfos.first.imageType,
          ImageSubmissionType.quality,
        );
        expect(todo.imageSubmissionInfos.first.isRequired, isTrue);
        expect(
          todo.imageSubmissionInfos.last.imageType,
          ImageSubmissionType.other,
        );
        expect(todo.toMap(), isNot(contains('is_image_required')));
      },
    );
  });

  group('TodoExecution serialization', () {
    test('reads and writes submission_image_ids', () {
      final now = DateTime(2026, 4, 18, 10, 0);
      final execution = TodoExecution.fromMap({
        'mapping_id': 'mapping_1',
        'base_date': {'date': Timestamp.fromDate(now)},
        'execution_end_time': {'date': Timestamp.fromDate(now)},
        'execution_minute': 12,
        'is_image_send': true,
        'is_skipped': false,
        'worker_ids': 'worker_1',
        'todo_id': 'todo_1',
        'countable_count': 3,
        'submission_image_ids': ['quality_1', 'service_1'],
      }, 'execution_1')!;

      expect(execution.submissionImageIds, ['quality_1', 'service_1']);
      expect(execution.toMap()['submission_image_ids'], [
        'quality_1',
        'service_1',
      ]);
      expect(execution.toMap(), isNot(contains('submissionImageIds')));
    });

    test('reads legacy submissionImageIds', () {
      final now = DateTime(2026, 4, 18, 10, 0);
      final execution = TodoExecution.fromMap({
        'mapping_id': 'mapping_1',
        'todo_id': 'todo_1',
        'base_date': {'date': Timestamp.fromDate(now)},
        'execution_end_time': {'date': Timestamp.fromDate(now)},
        'submissionImageIds': ['quality_1', 'service_1'],
      }, 'execution_1')!;

      expect(execution.submissionImageIds, ['quality_1', 'service_1']);
    });
  });
}
