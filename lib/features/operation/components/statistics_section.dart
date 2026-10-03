import 'package:flutter/material.dart';

import '../providers/operation_logic.dart';
import 'sales_graph_card.dart';
import 'productivity_graph_card.dart';
import 'detail_stats_grid.dart';
import 'statistics_common_widgets.dart';

class StatisticsSection extends StatefulWidget {
  final int currentSales;
  final int salesForecast;
  final double achievementRate;
  final List<HourlyGraphData> hourlyGraphData;
  final int currentProductionPoints;
  final int targetProductionPoints;
  final int individualCapacity;
  final Duration elapsedTime;
  final Duration totalWorkDuration;
  final int totalTodoDurationMin;
  final int totalTaskDurationMin;

  const StatisticsSection({
    super.key,
    required this.currentSales,
    required this.salesForecast,
    required this.achievementRate,
    required this.hourlyGraphData,
    required this.currentProductionPoints,
    required this.targetProductionPoints,
    required this.individualCapacity,
    required this.elapsedTime,
    required this.totalWorkDuration,
    required this.totalTodoDurationMin,
    required this.totalTaskDurationMin,
  });

  @override
  State<StatisticsSection> createState() => _StatisticsSectionState();
}

class _StatisticsSectionState extends State<StatisticsSection> {
  int _selectedIndex = 0; // 0: 売上, 1: 生産性

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. タブ切り替えボタン
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: StatisticsTabButton(
                  label: "売上状況",
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
              ),
              Expanded(
                child: StatisticsTabButton(
                  label: "生産性状況",
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. グラフカード
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedIndex == 0
              ? SalesGraphCard(
                  currentSales: widget.currentSales,
                  salesForecast: widget.salesForecast,
                  achievementRate: widget.achievementRate,
                  hourlyGraphData: widget.hourlyGraphData,
                )
              : ProductivityGraphCard(
                  currentProductionPoints: widget.currentProductionPoints,
                  targetProductionPoints: widget.targetProductionPoints,
                  hourlyGraphData: widget.hourlyGraphData,
                  achievementRate: widget.achievementRate,
                ),
        ),

        const SizedBox(height: 24),

        // 3. 詳細統計グリッド
        DetailStatsGrid(
          currentSales: widget.currentSales,
          salesForecast: widget.salesForecast,
          achievementRate: widget.achievementRate,
          elapsedTime: widget.elapsedTime,
          totalWorkDuration: widget.totalWorkDuration,
          totalTodoDurationMin: widget.totalTodoDurationMin,
          totalTaskDurationMin: widget.totalTaskDurationMin,
          currentProductionPoints: widget.currentProductionPoints,
          targetProductionPoints: widget.targetProductionPoints,
        ),
      ],
    );
  }
}
