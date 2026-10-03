import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../models/worker_model.dart';
import '../providers/operation_logic.dart';
import 'todo_detail_tile.dart';

class PositionDetailCard extends StatelessWidget {
  final String storeId;
  final PositionGroup group;
  final Map<String, Worker> workerMap;
  final DateTime openDate;

  const PositionDetailCard({
    super.key,
    required this.storeId,
    required this.group,
    required this.workerMap,
    required this.openDate,
  });

  @override
  Widget build(BuildContext context) {
    // 色コードパース
    Color positionColor;
    try {
      final hexCode = group.info.colorHex.replaceAll('#', '');
      positionColor = Color(int.parse('FF$hexCode', radix: 16));
    } catch (_) {
      positionColor = Colors.grey;
    }

    // 達成率計算
    final int total = group.items.length;
    final int doneOrSkipped = group.items.where((i) => i.isDone).length;
    final double rate = total > 0 ? doneOrSkipped / total : 0.0;
    final String rateStr = (rate * 100).toStringAsFixed(1);

    // 完了時間の計算
    final DateTime? completedTime = group.completedAt;
    final String completedTimeStr = completedTime != null
        ? DateFormat('HH:mm').format(completedTime)
        : "未完了";

    // 貢献度計算 (誰がどれくらいやったか)
    final Map<String, int> workerCounts = {};
    for (var item in group.items) {
      if (item.isDone && item.execution != null) {
        final wid = item.execution!.workerId;
        if (wid == null) continue;
        workerCounts[wid] = (workerCounts[wid] ?? 0) + 1;
      }
    }
    // 貢献度上位を表示するためのリスト作成
    final sortedWorkers = workerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: positionColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.headerBlack.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ヘッダー ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      group.info.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: positionColor,
                      ),
                    ),
                    Text(
                      "$doneOrSkipped / $total",
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.subText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 達成率バー
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 8,
                    backgroundColor: AppColors.backgroundLight,
                    valueColor: AlwaysStoppedAnimation<Color>(positionColor),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "達成率 $rateStr%",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    Text(
                      "完了時刻: $completedTimeStr",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: completedTime != null
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),

                // 実施者の割合表示 (簡易版)
                if (sortedWorkers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: sortedWorkers.map((entry) {
                      final workerName =
                          workerMap[entry.key]?.familyName ?? "不明";
                      final workerRate = (entry.value / doneOrSkipped * 100)
                          .toStringAsFixed(0);
                      return Text(
                        "$workerName $workerRate%",
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.subText,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // --- Todoリスト ---
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return TodoDetailTile(
                storeId: storeId,
                item: group.items[index],
                positionTitle: group.info.title,
                positionColor: positionColor,
                todoIndex: index + 1,
                openDate: openDate,
              );
            },
          ),
        ],
      ),
    );
  }
}
