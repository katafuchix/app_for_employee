import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class OperationTimeHeader extends StatelessWidget {
  final DateTime openTime;
  final DateTime closeTime;

  const OperationTimeHeader({
    super.key,
    required this.openTime,
    required this.closeTime,
  });

  @override
  Widget build(BuildContext context) {
    final startFormat = DateFormat('HH:mm').format(openTime);
    final endFormat = DateFormat('HH:mm').format(closeTime);

    final now = DateTime.now();
    final totalMinutes = closeTime.difference(openTime).inMinutes;
    final elapsedMinutes = now.difference(openTime).inMinutes;

    double progressValue = 0.0;
    String statusText = "";
    Color statusColor = AppColors.headerBlack;

    if (totalMinutes <= 0) {
      progressValue = 0.0;
      statusText = "--:--";
    } else if (now.isBefore(openTime)) {
      progressValue = 0.0;
      statusText = "開店前";
      statusColor = Colors.grey;
    } else if (now.isAfter(closeTime)) {
      progressValue = 1.0;
      statusText = "営業終了";
      statusColor = Colors.grey;
    } else {
      progressValue = (elapsedMinutes / totalMinutes).clamp(0.0, 1.0);
      final h = elapsedMinutes ~/ 60;
      final m = elapsedMinutes % 60;
      statusText = "現在 ${h}h ${m.toString().padLeft(2, '0')}m";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.headerBlack.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                startFormat,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  fontSize: 14,
                ),
              ),
              Text(
                endFormat,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: AppColors.backgroundLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                now.isAfter(closeTime) ? Colors.grey : AppColors.headerBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
