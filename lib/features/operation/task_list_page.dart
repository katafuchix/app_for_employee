import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用
import 'components/task_detail_modal.dart';
import 'models/task_models.dart';
import 'providers/operation_task_provider.dart';
import '../../core/theme/app_colors.dart'; // 既存のカラー定義を使用と仮定

class TaskListPage extends ConsumerStatefulWidget {
  final String storeId;
  final DateTime operationDate;

  const TaskListPage({
    super.key,
    required this.storeId,
    required this.operationDate,
  });

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'タスク一覧',
          style: TextStyle(
            color: AppColors.darkGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkGrey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.blue,
          tabs: const [
            Tab(text: '月次タスク'),
            Tab(text: '定期タスク'),
          ],
        ),
      ),
      backgroundColor: AppColors.backgroundLight,
      body: TabBarView(
        controller: _tabController,
        children: [
          // 引数はそのまま渡す
          _MonthlyTaskList(
            storeId: widget.storeId,
            operationDate: widget.operationDate,
          ),
          _RegularTaskList(
            storeId: widget.storeId,
            operationDate: widget.operationDate,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 月次タスクリスト (Monthly / Temporary)
// AutomaticKeepAliveClientMixin で状態を保持
// ---------------------------------------------------------
class _MonthlyTaskList extends ConsumerStatefulWidget {
  final String storeId;
  final DateTime operationDate;

  const _MonthlyTaskList({required this.storeId, required this.operationDate});

  @override
  ConsumerState<_MonthlyTaskList> createState() => _MonthlyTaskListState();
}

class _MonthlyTaskListState extends ConsumerState<_MonthlyTaskList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // タブ切り替え時に破棄されないようにする

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必ず呼ぶ

    final tasksAsync = ref.watch(
      operationMonthlyTasksProvider(
        storeId: widget.storeId,
        date: widget.operationDate,
      ),
    );

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (tasks) {
        if (tasks.isEmpty) return const Center(child: Text('タスクはありません'));

        // 日付ごとにグルーピング
        final grouped = <DateTime, List<TaskTemporary>>{};
        for (var task in tasks) {
          final dateKey = DateTime(
            task.baseDate.year,
            task.baseDate.month,
            task.baseDate.day,
          );
          if (grouped[dateKey] == null) grouped[dateKey] = [];
          grouped[dateKey]!.add(task);
        }

        final sortedDates = grouped.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dailyTasks = grouped[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateHeader(date: date, operationDate: widget.operationDate),
                ...dailyTasks.map(
                  (task) => _MonthlyTaskCard(
                    task: task,
                    storeId: widget.storeId,
                    operationDate: widget.operationDate,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------
// 定期タスクリスト (Regular / Schedule)
// AutomaticKeepAliveClientMixin で状態を保持
// ---------------------------------------------------------
class _RegularTaskList extends ConsumerStatefulWidget {
  final String storeId;
  final DateTime operationDate;

  const _RegularTaskList({required this.storeId, required this.operationDate});

  @override
  ConsumerState<_RegularTaskList> createState() => _RegularTaskListState();
}

class _RegularTaskListState extends ConsumerState<_RegularTaskList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // タブ切り替え時に破棄されないようにする

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必ず呼ぶ

    final nodesAsync = ref.watch(
      operationRegularTasksProvider(
        storeId: widget.storeId,
        date: widget.operationDate,
      ),
    );

    return nodesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (nodes) {
        if (nodes.isEmpty) return const Center(child: Text('タスクはありません'));

        final grouped = <DateTime, List<RegularTaskNode>>{};
        for (var node in nodes) {
          final dateKey = DateTime(
            node.schedule.baseDate.year,
            node.schedule.baseDate.month,
            node.schedule.baseDate.day,
          );
          if (grouped[dateKey] == null) grouped[dateKey] = [];
          grouped[dateKey]!.add(node);
        }

        final sortedDates = grouped.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dailyNodes = grouped[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateHeader(date: date, operationDate: widget.operationDate),
                ...dailyNodes.map(
                  (node) => _RegularTaskCard(
                    storeId: widget.storeId,
                    operationDate: widget.operationDate,
                    node: node,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------
// 共通UIコンポーネント (変更なし)
// ---------------------------------------------------------

/// 日付ヘッダー
class _DateHeader extends StatelessWidget {
  final DateTime date;
  final DateTime operationDate;

  const _DateHeader({required this.date, required this.operationDate});

  @override
  Widget build(BuildContext context) {
    final isDelayed = date.isBefore(
      DateTime(operationDate.year, operationDate.month, operationDate.day),
    );
    final isToday =
        date.year == operationDate.year &&
        date.month == operationDate.month &&
        date.day == operationDate.day;

    final dateStr = isToday ? "今日" : DateFormat('M/d').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        dateStr,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDelayed ? Colors.red : Colors.black,
        ),
      ),
    );
  }
}

/// Helper: Hex String to Color
Color _hexToColor(String? hexString) {
  if (hexString == null) return Colors.grey;
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// 月次タスクカード
class _MonthlyTaskCard extends StatelessWidget {
  final TaskTemporary task;
  final String storeId;
  final DateTime operationDate;

  const _MonthlyTaskCard({
    required this.task,
    required this.storeId,
    required this.operationDate,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = _hexToColor(task.category?.colorHex);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => TaskDetailModal(
            storeId: storeId,
            temporaryTask: task,
            operationDate: operationDate,
          ),
        );
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: catColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: catColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.category?.title ?? 'No Category',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.menu_book,
                      size: 18,
                      color: task.manualIds.isNotEmpty
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: task.isImageRequired ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '${task.durationMinute}分',
                    style: TextStyle(
                      color: catColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (task.useAim && task.aim.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    task.aim,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                )
              else if (task.useDetail && task.detail.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    task.detail,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 定期タスクカード
class _RegularTaskCard extends StatelessWidget {
  final String storeId;
  final RegularTaskNode node;
  final DateTime operationDate;

  const _RegularTaskCard({
    required this.storeId,
    required this.node,
    required this.operationDate,
  });

  @override
  Widget build(BuildContext context) {
    final isStep = node.schedule.isStepTask;
    final catColor = _hexToColor(node.category?.colorHex);

    final title = isStep
        ? node.stepInfo?.title ?? ''
        : node.taskInfo?.title ?? '';
    final duration = isStep
        ? node.stepInfo?.stepInfos.fold(
                0,
                (sum, item) => sum + item.durationMinute,
              ) ??
              0
        : node.taskInfo?.durationMinute ?? 0;

    final hasManual = isStep
        ? (node.stepInfo?.manualIds.isNotEmpty ?? false)
        : (node.taskInfo?.manualIds.isNotEmpty ?? false);

    String? detailText;
    if (!isStep && (node.taskInfo?.useDetail ?? false)) {
      detailText = node.taskInfo?.detail;
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => TaskDetailModal(
            storeId: storeId,
            regularTaskNode: node,
            operationDate: operationDate,
          ),
        );
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: catColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: catColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      node.category?.title ?? 'No Category',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.menu_book,
                      size: 18,
                      color: hasManual ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isStep)
                    Text(
                      '${node.stepInfo?.stepInfos.length ?? 0}ステップ',
                      style: TextStyle(
                        color: catColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    Text(
                      '$duration分',
                      style: TextStyle(
                        color: catColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              if (isStep && node.stepInfo != null) ...[
                const SizedBox(height: 8),
                _StepProgressBar(
                  stepInfos: node.stepInfo!.stepInfos,
                  executedStepIds: node.schedule.executedStepIds,
                  color: catColor,
                ),
              ] else if (detailText != null && detailText.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    detailText,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ステップタスク用の進捗バー
class _StepProgressBar extends StatelessWidget {
  final List<StepInfo> stepInfos;
  final List<String> executedStepIds;
  final Color color;

  const _StepProgressBar({
    required this.stepInfos,
    required this.executedStepIds,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final executedCount = executedStepIds.length;
    final totalDuration = stepInfos.fold(0, (sum, s) => sum + s.durationMinute);

    int currentDuration = 0;
    for (int i = 0; i < executedCount && i < stepInfos.length; i++) {
      currentDuration += stepInfos[i].durationMinute;
    }

    final progress = totalDuration == 0 ? 0.0 : currentDuration / totalDuration;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$currentDuration/$totalDuration分',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
