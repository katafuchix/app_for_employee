import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart'; // テーマカラーを使用
import '../providers/operation_logic.dart';

class MyStatusCard extends StatelessWidget {
  final String storeWorkerId;
  final List<WorkerAttendance> attendances;

  const MyStatusCard({
    super.key,
    required this.storeWorkerId,
    required this.attendances,
  });

  @override
  Widget build(BuildContext context) {
    final myData = attendances
        .where((a) => a.worker.id == storeWorkerId)
        .firstOrNull;

    if (myData == null) {
      return const SizedBox.shrink(); // データがない場合は非表示
    }

    final isWorking = myData.isWorking;
    final hours = myData.totalWorkDuration.inHours;
    final minutes = myData.totalWorkDuration.inMinutes.remainder(60);
    final durationStr = "${hours}h ${minutes}m";

    // デザイン定義
    final statusColor = isWorking ? AppColors.headerBlack : Colors.grey;
    final statusText = isWorking ? "勤務中" : "退勤 / 休憩";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Owner側と共通のシャドウ設定
        boxShadow: [
          BoxShadow(
            color: AppColors.headerBlack.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        // 勤務中は左端にアクセントカラーをつける
        border: isWorking
            ? const Border(left: BorderSide(color: AppColors.blue, width: 4))
            : null,
      ),
      child: Row(
        children: [
          // アイコン
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.backgroundLight,
                child: const Icon(Icons.person, color: Colors.grey, size: 32),
              ),
              if (isWorking)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // 名前と役職
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "My Status",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
                Text(
                  myData.worker.givenName,
                  style: const TextStyle(
                    color: AppColors.darkGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    myData.positionTitle,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ステータスと時間
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                durationStr,
                style: const TextStyle(
                  color: AppColors.darkGrey,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
