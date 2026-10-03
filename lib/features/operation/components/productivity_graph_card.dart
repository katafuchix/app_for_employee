import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/operation_logic.dart';
import 'statistics_common_widgets.dart';

class ProductivityGraphCard extends StatelessWidget {
  final int currentProductionPoints;
  final int targetProductionPoints;
  final double achievementRate;
  final List<HourlyGraphData> hourlyGraphData;

  const ProductivityGraphCard({
    super.key,
    required this.currentProductionPoints,
    required this.targetProductionPoints,
    required this.hourlyGraphData,
    required this.achievementRate,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat("#,###");
    final totalAchievementRate = (achievementRate * 100).toStringAsFixed(1);

    int maxY = 1;
    for (var d in hourlyGraphData) {
      maxY = math.max(maxY, d.productionActual);
      maxY = math.max(maxY, d.productionTarget);
    }
    maxY = (maxY * 1.2).toInt();
    if (maxY == 0) maxY = 100;

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ValueColumn(
                label: "生産Pt",
                value: "${currencyFmt.format(currentProductionPoints)}pt",
                valueColor: AppColors.blue,
              ),
              const SizedBox(width: 16),
              ValueColumn(
                label: "目標Pt",
                value: "${currencyFmt.format(targetProductionPoints)}pt",
                valueColor: Colors.grey,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "全体達成率",
                    style: TextStyle(fontSize: 10, color: AppColors.subText),
                  ),
                  Text(
                    "$totalAchievementRate%",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: hourlyGraphData.map((data) {
                final targetRate = (data.productionTarget / maxY).clamp(
                  0.0,
                  1.0,
                );
                final actualRate = (data.productionActual / maxY).clamp(
                  0.0,
                  1.0,
                );
                final hourlyRate = data.productionTarget > 0
                    ? (data.productionActual / data.productionTarget * 100)
                          .toStringAsFixed(0)
                    : "-";
                final salesP = data.productionFromSales;
                final todoP = data.productionFromTodo;
                final taskP = data.productionFromTask;
                final totalP = salesP + todoP + taskP;

                const double barWidthActual = 16.0;
                const double barWidthTarget = 8.0;
                const double groupWidth = 80.0;

                return Container(
                  width: groupWidth,
                  height: 200,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 40,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              currencyFmt.format(data.productionActual),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blue,
                              ),
                            ),
                            Text(
                              "$hourlyRate%",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color:
                                    (data.productionActual >=
                                            data.productionTarget &&
                                        data.productionTarget > 0)
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FractionallySizedBox(
                              heightFactor: actualRate == 0 ? 0.01 : actualRate,
                              child: Container(
                                width: barWidthActual,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: totalP == 0
                                    ? Container(color: Colors.grey[200])
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (taskP > 0)
                                            Flexible(
                                              flex: taskP,
                                              child: Container(
                                                color: Colors.green,
                                              ),
                                            ),
                                          if (todoP > 0)
                                            Flexible(
                                              flex: todoP,
                                              child: Container(
                                                color: Colors.orange,
                                              ),
                                            ),
                                          if (salesP > 0)
                                            Flexible(
                                              flex: salesP,
                                              child: Container(
                                                color: AppColors.blue,
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            FractionallySizedBox(
                              heightFactor: targetRate == 0 ? 0.01 : targetRate,
                              child: Container(
                                width: barWidthTarget,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${data.hour}時",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LegendItem(color: AppColors.blue, label: "売上"),
              SizedBox(width: 12),
              LegendItem(color: Colors.orange, label: "Todo"),
              SizedBox(width: 12),
              LegendItem(color: Colors.green, label: "Task"),
              SizedBox(width: 12),
              LegendItem(color: Colors.grey, label: "目標"),
            ],
          ),
        ],
      ),
    );
  }
}
