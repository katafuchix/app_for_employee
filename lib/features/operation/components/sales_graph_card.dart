import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/operation_logic.dart';
import 'statistics_common_widgets.dart';

class SalesGraphCard extends StatelessWidget {
  final int currentSales;
  final int salesForecast;
  final double achievementRate;
  final List<HourlyGraphData> hourlyGraphData;

  const SalesGraphCard({
    super.key,
    required this.currentSales,
    required this.salesForecast,
    required this.achievementRate,
    required this.hourlyGraphData,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat("#,###");
    final diff = currentSales - salesForecast;
    final diffStr = diff > 0
        ? "+${currencyFmt.format(diff)}"
        : currencyFmt.format(diff);
    final diffColor = diff >= 0 ? Colors.green : Colors.red;

    // グラフ最大値計算
    int maxY = 1;
    for (var d in hourlyGraphData) {
      maxY = math.max(maxY, d.salesActual);
      maxY = math.max(maxY, d.salesForecast);
    }
    maxY = (maxY * 1.2).toInt();
    if (maxY == 0) maxY = 10000;

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
          // 数値サマリー
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ValueColumn(
                label: "売上額",
                value: "${currencyFmt.format(currentSales)}円",
                valueColor: AppColors.blue,
              ),
              const SizedBox(width: 16),
              ValueColumn(
                label: "売上予測",
                value: "${currencyFmt.format(salesForecast)}円",
                valueColor: Colors.grey,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "差分",
                    style: TextStyle(fontSize: 10, color: AppColors.subText),
                  ),
                  Text(
                    diffStr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: diffColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 横スクロールグラフエリア
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: hourlyGraphData.map((data) {
                final forecastRate = (data.salesForecast / maxY).clamp(
                  0.0,
                  1.0,
                );
                final actualRate = (data.salesActual / maxY).clamp(0.0, 1.0);

                const double barWidthActual = 16.0;
                const double barWidthForecast = 8.0;
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
                              currencyFmt.format(data.salesActual),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blue,
                              ),
                            ),
                            Text(
                              "(${currencyFmt.format(data.salesForecast)})",
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
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
                                  color: AppColors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            FractionallySizedBox(
                              heightFactor: forecastRate == 0
                                  ? 0.01
                                  : forecastRate,
                              child: Container(
                                width: barWidthForecast,
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
        ],
      ),
    );
  }
}
