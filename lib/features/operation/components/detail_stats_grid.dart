import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';

class DetailStatsGrid extends StatelessWidget {
  final int currentSales;
  final int salesForecast;
  final double achievementRate;
  final Duration elapsedTime;
  final Duration totalWorkDuration;
  final int totalTodoDurationMin;
  final int totalTaskDurationMin;
  final int currentProductionPoints;
  final int targetProductionPoints;

  const DetailStatsGrid({
    super.key,
    required this.currentSales,
    required this.salesForecast,
    required this.achievementRate,
    required this.elapsedTime,
    required this.totalWorkDuration,
    required this.totalTodoDurationMin,
    required this.totalTaskDurationMin,
    required this.currentProductionPoints,
    required this.targetProductionPoints,
  });

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return "${h}h ${m.toString().padLeft(2, '0')}m";
  }

  String _formatDurationObj(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return "${h}h ${m.toString().padLeft(2, '0')}m";
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat("#,###");
    final achievementRateStr = (achievementRate * 100).toStringAsFixed(1);

    final items = [
      _StatItemData(
        label: "経過時間",
        value: _formatDurationObj(elapsedTime),
        icon: Icons.timer,
        color: Colors.blueGrey,
      ),
      _StatItemData(
        label: "売上予測",
        value: "${currencyFmt.format(salesForecast)}円",
        icon: Icons.show_chart,
        color: Colors.grey,
      ),
      _StatItemData(
        label: "売上額",
        value: "${currencyFmt.format(currentSales)}円",
        icon: Icons.attach_money,
        color: Colors.blue,
      ),
      _StatItemData(
        label: "合計出勤時間",
        value: _formatDurationObj(totalWorkDuration),
        icon: Icons.group,
        color: Colors.blueGrey,
      ),
      _StatItemData(
        label: "Todo実施",
        value: _formatDuration(totalTodoDurationMin),
        icon: Icons.check_circle_outline,
        color: Colors.orange,
      ),
      _StatItemData(
        label: "Task実施",
        value: _formatDuration(totalTaskDurationMin),
        icon: Icons.task_alt,
        color: Colors.green,
      ),
      _StatItemData(
        label: "生産Pt",
        value: currencyFmt.format(currentProductionPoints),
        icon: Icons.auto_graph,
        color: AppColors.blue,
      ),
      _StatItemData(
        label: "目標Pt",
        value: currencyFmt.format(targetProductionPoints),
        icon: Icons.flag,
        color: Colors.grey,
      ),
      _StatItemData(
        label: "達成率",
        value: "$achievementRateStr%",
        icon: Icons.pie_chart,
        color: Colors.redAccent,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "詳細データ",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(height: 12),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.9,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subText,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatItemData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatItemData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
