// features/operation/operation_timezone_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../../core/theme/app_colors.dart';

// Controllerの代わりに新しいProviderをインポート
import 'providers/operation_master_provider.dart';
import 'providers/operation_todo_provider.dart';

// コンポーネントのインポート
import 'components/position_detail_card.dart';

class OperationTimezoneDetailScreen extends ConsumerWidget {
  final String storeId;
  final String timezoneId;
  final DateTime openDate;

  const OperationTimezoneDetailScreen({
    super.key,
    required this.storeId,
    required this.timezoneId,
    required this.openDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // operationControllerProvider ではなく operationTodoListProvider を使用
    final groupAsync = ref.watch(
      operationTodoListProvider(storeId: storeId, date: openDate).select(
        (value) => value.whenData(
          // TodoListState 内の timezoneGroups から検索
          (state) => state.timezoneGroups.firstWhereOrNull(
            (g) => g.info.id == timezoneId,
          ),
        ),
      ),
    );

    final masterAsync = ref.watch(
      operationMasterDataProvider(storeId: storeId, date: openDate),
    );
    final workerMap = masterAsync.value?.workerMap ?? {};

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          groupAsync.value?.info.title ?? "",
          style: const TextStyle(
            color: AppColors.darkGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkGrey),
        centerTitle: true,
      ),
      body: groupAsync.when(
        data: (groupData) {
          if (groupData == null) {
            return const Center(child: Text("タイムゾーンが見つかりません"));
          }

          final startStr = DateFormat('HH:mm').format(groupData.startTime);
          final endStr = DateFormat('HH:mm').format(groupData.endTime);
          final timeRange = "$startStr - $endStr";

          // 表示するポジションをフィルタリング
          final visiblePositionGroups = groupData.positionGroups.where((
            posGroup,
          ) {
            return posGroup.items.isNotEmpty;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 時間表示
                Center(
                  child: Text(
                    timeRange,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.subText,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ポジションごとのリスト
                if (visiblePositionGroups.isEmpty)
                  const Center(child: Text("表示するポジションがありません"))
                else
                  ...visiblePositionGroups.map((posGroup) {
                    return PositionDetailCard(
                      storeId: storeId,
                      group: posGroup,
                      workerMap: workerMap,
                      openDate: openDate,
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("エラーが発生しました: $err")),
      ),
    );
  }
}
