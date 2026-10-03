import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/operation_logic.dart';
import '../operation_timezone_detail_screen.dart'; // 画面遷移先

class TimezoneSummaryCard extends StatelessWidget {
  final TimezoneSummary summary;
  final String storeId;
  final TimezoneGroup groupData;
  final DateTime openDate;

  const TimezoneSummaryCard({
    super.key,
    required this.summary,
    required this.storeId,
    required this.groupData,
    required this.openDate,
  });

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('HH:mm').format(summary.startTime);
    final endStr = DateFormat('HH:mm').format(summary.endTime);

    // 分母の安全なキャスト
    final int totalCount = summary.totalItemCount;
    final double totalDouble = totalCount > 0 ? totalCount.toDouble() : 1.0;

    // 1. 進捗率（達成度）: 純粋な完了率を表示（オーナー版の基準に準拠）
    final double doneRatePercent = (summary.doneCount / totalDouble) * 100;

    // 2. スキップ率
    final double skippedRatePercent = (summary.skippedCount / totalDouble) * 100;

    // 全てのタスクが消化（完了 or スキップ）されたか
    final bool isAllCompleted = totalCount > 0 && 
        (summary.doneCount + summary.skippedCount == totalCount);

    // タイムゾーンの状態定義
    final bool isDuringNow = !summary.isEnded; // 現在進行中か
    final bool isElapsed = summary.isEnded;       // タイムゾーンが終了しているか

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // 実施中なら青枠線、そうでないならシャドウ（オーナー版のZStack風デザインを反映）
        border: isDuringNow 
            ? Border.all(color: AppColors.blue, width: 1.5) 
            : null,
        boxShadow: isDuringNow 
            ? null 
            : [
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
          // HEADER_VIEW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    summary.info.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  if (isDuringNow) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "実施中",
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OperationTimezoneDetailScreen(
                        storeId: storeId,
                        timezoneId: groupData.info.id,
                        openDate: openDate,
                      ),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      "詳細を確認",
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.blue),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // MIDDLE_VIEW (時間 & カウント)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$startStr - $endStr",
                style: const TextStyle(color: AppColors.subText, fontSize: 12),
              ),
              Row(
                children: [
                  if (isAllCompleted)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.check_circle, size: 14, color: Colors.green),
                    ),
                  Text(
                    "${summary.doneCount + summary.skippedCount} 項目 / $totalCount 項目",
                    style: TextStyle(
                      color: isAllCompleted ? Colors.green : AppColors.subText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // GAUGE_VIEW (安全な三層プログレスバー)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (summary.doneCount > 0)
                    Expanded(
                      flex: summary.doneCount,
                      child: Container(color: Colors.green),
                    ),
                  if (summary.skippedCount > 0)
                    Expanded(
                      flex: summary.skippedCount,
                      child: Container(color: Colors.orange), // 従業員版のカラーを維持
                    ),
                  if (totalCount - summary.doneCount - summary.skippedCount > 0)
                    Expanded(
                      flex: totalCount - summary.doneCount - summary.skippedCount,
                      child: Container(color: AppColors.backgroundLight),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // BOTTOM_VIEW (ステータス表示の出し分け & 右側に進捗率)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // 左側コンポーネントの出し分け
              if (isAllCompleted)
                // 1. すべてのタスクが消化済みの場合はスキップ率を表示
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text("スキップ率:", style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 3),
                    Text(
                      "${skippedRatePercent.toStringAsFixed(1)}%",
                      style: const TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              else if (isDuringNow)
                // 2. 現在進行中の場合はタイムゾーン終了までの時間を表示
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text("タイムゾーン終了まで", style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 3),
                    Text(
                      "${summary.remainingDuration.inMinutes}分",
                      style: TextStyle(fontSize: 18, color: isElapsed ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              else
                // 3. 終了しているが未完了のタスクが残っている場合
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text("未完了", style: TextStyle(fontSize: 12, color: isElapsed ? Colors.red : Colors.black, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 3),
                    Text(
                      "${summary.remainingDuration.inMinutes}分",
                      style: TextStyle(fontSize: 18, color: isElapsed ? Colors.red : Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

              // 右側：常に現在の純粋な進捗率(達成度)を表示
              Text(
                "${doneRatePercent.toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}