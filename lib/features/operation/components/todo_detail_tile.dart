import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tebanashi/features/operation/components/todo_detail_modal.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/operation_logic.dart';
import 'todo_image_button.dart';

class TodoDetailTile extends StatelessWidget {
  final String storeId;
  final String positionTitle;
  final Color positionColor;
  final int todoIndex;
  final OperationTodoItem item;
  final DateTime openDate;

  const TodoDetailTile({
    super.key,
    required this.storeId,
    required this.positionTitle,
    required this.positionColor,
    required this.todoIndex,
    required this.item,
    required this.openDate,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.todoMaster?.title ?? '不明なタスク';
    final duration = item.todoMaster?.durationMinute ?? 0;
    final todo = item.todoMaster;

    final isDone = item.isDone;
    final isSkipped = item.isSkipped;
    final hasImage = item.execution?.submissionImageIds.isNotEmpty ?? false;

    final completionTime =
        item.execution?.executionEndTime ?? item.execution?.baseDate;
    final completionTimeStr = completionTime != null
        ? DateFormat('HH:mm').format(completionTime)
        : null;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => TodoDetailModal(
            item: item,
            storeId: storeId,
            positionTitle: positionTitle,
            positionColor: positionColor,
            todoIndex: todoIndex,
            openDate: openDate,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ステータスアイコン
            Icon(
              isDone
                  ? (isSkipped ? Icons.skip_next : Icons.check_circle)
                  : Icons.radio_button_unchecked,
              color: isDone
                  ? (isSkipped ? Colors.orange : Colors.green)
                  : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),

            // タイトル & 時間
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDone ? Colors.grey : AppColors.darkGrey,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$duration分',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (completionTimeStr != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '完了: $completionTimeStr',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSkipped ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 画像ボタン
            if (hasImage && item.execution != null && todo != null)
              TodoImageButton(
                storeId: storeId,
                executionId: item.execution!.id,
                submissionImageIds: item.execution!.submissionImageIds,
                imageSubmissionInfos: todo.imageSubmissionInfos,
              ),
          ],
        ),
      ),
    );
  }
}
