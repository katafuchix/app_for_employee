import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tebanashi/features/operation/components/todo_detail_tile.dart';
import 'package:tebanashi/features/operation/models/meta_data_model.dart';
import 'package:tebanashi/features/operation/models/todo_execution_model.dart';
import 'package:tebanashi/features/operation/models/todo_mapping_model.dart';
import 'package:tebanashi/features/operation/models/todo_model.dart';
import 'package:tebanashi/features/operation/providers/operation_logic.dart';

void main() {
  testWidgets(
    'shows image button when submissionImageIds exists even if isImageSend is false',
    (tester) async {
      final baseDate = DateTime(2026, 4, 21, 9);
      final item = OperationTodoItem(
        mapping: TodoMapping(
          id: 'mapping_1',
          todoModeId: 'mode_1',
          positionId: 'position_1',
          timezoneId: 'timezone_1',
          todoId: 'todo_1',
          index: 1,
          metadata: Metadata.empty(),
        ),
        todoMaster: Todo(
          id: 'todo_1',
          title: '画像確認タスク',
          durationMinute: 10,
          difficulty: 1,
          isSkippable: true,
          metadata: Metadata.empty(),
          detail: '',
          useDetail: false,
          shortManual: '',
          useShortManual: false,
          durationType: TodoDurationType.fixed,
          countableTitle: '',
          countableDurationPerOne: 0,
          countableCountUnit: '',
          completionChecklist: const [],
          useCompletionChecklist: false,
          manualIds: const [],
          imageSubmissionInfos: const [
            ImageSubmissionInfo(
              id: 'quality_1',
              title: '品質',
              imageType: ImageSubmissionType.quality,
              isRequired: false,
            ),
          ],
        ),
        execution: TodoExecution(
          id: 'execution_1',
          mappingId: 'mapping_1',
          baseDate: baseDate,
          executionEndTime: baseDate.add(const Duration(minutes: 30)),
          executionMinute: 10,
          isImageSend: false,
          isSkipped: false,
          metadata: Metadata.empty(),
          todoId: 'todo_1',
          submissionImageIds: const ['quality_1'],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TodoDetailTile(
                storeId: 'store_1',
                positionTitle: 'Kitchen',
                positionColor: Colors.blue,
                todoIndex: 1,
                item: item,
                openDate: baseDate,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.image), findsOneWidget);
    },
  );
}
