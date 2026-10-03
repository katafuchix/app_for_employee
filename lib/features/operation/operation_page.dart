// features/operation/operation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

// Providers
import 'providers/operation_streams.dart';
import 'providers/operation_master_provider.dart';
import 'providers/operation_attendance_provider.dart';
import 'providers/operation_todo_provider.dart';
import 'providers/operation_statistics_provider.dart';

// Components
import 'components/my_status_card.dart';
import 'components/operation_time_header.dart';
import 'components/attendance_widgets.dart';
import 'components/timezone_summary_card.dart';
import 'components/statistics_section.dart';
import 'task_list_page.dart';

class OperationPage extends ConsumerWidget {
  final String dailySetupId;
  final String storeId;
  final String storeWorkerId;
  final DateTime operationDate;

  const OperationPage({
    super.key,
    required this.dailySetupId,
    required this.storeId,
    required this.storeWorkerId,
    required this.operationDate,
  });

  // 強制終了の処理を関数として定義
  void _handleForceClose(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('営業が終了したため、ホーム画面に戻ります。'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 営業終了監視 (ref.listen は build 内で記述可能)
    ref.listen(
      operationStatusStreamProvider(
        storeId: storeId,
        dailySetupId: dailySetupId,
      ),
      (previous, next) {
        final shouldClose =
            next.value == null || (next.value?.isOperating != true);
        if (shouldClose) {
          _handleForceClose(context);
        }
      },
    );

    // 2. マスタデータのロード
    final masterAsync = ref.watch(
      operationMasterDataProvider(storeId: storeId, date: operationDate),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          '業務モード',
          style: TextStyle(
            color: AppColors.darkGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.darkGrey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: masterAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
        error: (err, stack) {
          debugPrint('OperationPage master data fetch failed: $err');
          debugPrintStack(stackTrace: stack);
          return _ErrorView(
            onRetry: () => ref.invalidate(operationMasterDataProvider),
          );
        },
        data: (master) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AttendanceSection(
                  storeId: storeId,
                  storeWorkerId: storeWorkerId,
                  date: operationDate,
                  openTime: master.openTime,
                  closeTime: master.closeTime,
                ),
                const SizedBox(height: 24),
                _TodoSection(storeId: storeId, date: operationDate),
                const SizedBox(height: 24),
                _StatisticsSection(storeId: storeId, date: operationDate),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// エラー表示部分は可読性のために切り出すとスッキリします
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text('データの取得に失敗しました'),
          ElevatedButton(onPressed: onRetry, child: const Text('再読み込み')),
        ],
      ),
    );
  }
}

/// 勤怠セクション
class _AttendanceSection extends ConsumerWidget {
  final String storeId;
  final String storeWorkerId;
  final DateTime date;
  final DateTime openTime;
  final DateTime closeTime;

  const _AttendanceSection({
    required this.storeId,
    required this.storeWorkerId,
    required this.date,
    required this.openTime,
    required this.closeTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(
      operationAttendanceProvider(storeId: storeId, date: date),
    );

    // 時間経過の表示のためにStatisticsProviderのelapsedTimeを使うか、
    // あるいは単純にHeader部分だけ別Providerを見る設計にする。
    // ここでは便宜上StatisticsProviderからelapsedTimeを取得してHeaderに渡す。
    // ※ Headerの更新で勤怠リストまでリビルドされるのを防ぐならさらに分割すべきですが、
    //   ここではHeaderとListを同じセクションとして扱います。

    final statsAsync = ref.watch(
      operationStatisticsProvider(storeId: storeId, date: date),
    );

    return attendanceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) {
        debugPrint('OperationPage attendance fetch failed: $e');
        debugPrintStack(stackTrace: s);
        return Text('勤怠データエラー: $e');
      },
      data: (attendance) {
        return Column(
          children: [
            MyStatusCard(
              storeWorkerId: storeWorkerId,
              attendances: attendance.workerAttendances,
            ),
            const SizedBox(height: 24),

            // ヘッダーには経過時間が必要
            statsAsync.when(
              data: (stats) => OperationTimeHeader(
                // 既存コンポーネントがOperationStateを要求する場合、必要な引数のみ渡す形にリファクタリング推奨。
                // ここでは仮に引数を展開して渡すイメージで記述します。
                openTime: openTime,
                closeTime: closeTime,
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, s) {
                debugPrint(
                  'OperationPage statistics fetch failed in attendance section: $e',
                );
                debugPrintStack(stackTrace: s);
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),

            AttendanceSectionHeader(
              count: attendance.totalWorkerCount,
              duration: attendance.totalWorkDuration,
            ),
            const SizedBox(height: 12),
            AttendanceHorizontalList(attendances: attendance.workerAttendances),
          ],
        );
      },
    );
  }
}

/// Todoセクション
class _TodoSection extends ConsumerWidget {
  final String storeId;
  final DateTime date;

  const _TodoSection({required this.storeId, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoAsync = ref.watch(
      operationTodoListProvider(storeId: storeId, date: date),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Todo 状況',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(height: 12),
        todoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) {
            debugPrint('OperationPage todo fetch failed: $e');
            debugPrintStack(stackTrace: s);
            return Text('Todoデータエラー: $e');
          },
          data: (state) {
            if (state.timezoneSummaries.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "Todo設定がありません",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            // Workerリストがまだロード中でもTodoは表示したいので、空リストフォールバック
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.timezoneSummaries.length,
              itemBuilder: (context, index) {
                final summary = state.timezoneSummaries[index];
                final groupData = state.timezoneGroups[index];

                return TimezoneSummaryCard(
                  summary: summary,
                  storeId: storeId,
                  groupData: groupData,
                  openDate: date,
                );
              },
            );
          },
        ),

        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue, // テーマカラーに合わせて調整
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.list_alt, color: Colors.white),
            label: const Text(
              'タスク一覧を確認する',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      TaskListPage(storeId: storeId, operationDate: date),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

/// 統計セクション
class _StatisticsSection extends ConsumerWidget {
  final String storeId;
  final DateTime date;

  const _StatisticsSection({required this.storeId, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(
      operationStatisticsProvider(storeId: storeId, date: date),
    );

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) {
        debugPrint('OperationPage statistics fetch failed: $e');
        debugPrintStack(stackTrace: s);
        return Text('統計データエラー: $e');
      },
      data: (state) {
        return StatisticsSection(
          currentSales: state.currentSales,
          salesForecast: state.salesForecast,
          achievementRate: state.achievementRate,
          currentProductionPoints: state.currentProductionPoints,
          targetProductionPoints: state.targetProductionPoints,
          hourlyGraphData: state.hourlyGraphData,
          individualCapacity: state.individualCapacity,
          elapsedTime: state.elapsedTime,
          totalWorkDuration: state.totalWorkDuration,
          totalTodoDurationMin: state.totalTodoDurationMin,
          totalTaskDurationMin: state.totalTaskDurationMin,
        );
      },
    );
  }
}
