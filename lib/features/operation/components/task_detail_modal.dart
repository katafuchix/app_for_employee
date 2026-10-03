import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../manual/manual_controller.dart';
import '../../manual/manual_page.dart';
import '../models/task_models.dart';
import '../controllers/task_action_controller.dart';
import '../providers/operation_task_provider.dart';

class TaskDetailModal extends ConsumerWidget {
  final String storeId;
  final DateTime operationDate;
  final TaskTemporary? temporaryTask;
  final RegularTaskNode? regularTaskNode;

  const TaskDetailModal({
    super.key,
    required this.storeId,
    required this.operationDate,
    this.temporaryTask,
    this.regularTaskNode,
  }) : assert(temporaryTask != null || regularTaskNode != null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 画像の状態を監視 (ボタンの有効/無効判定用)
    final imageFile = ref.watch(taskImageStateProvider);

    // データの正規化
    final isTemporary = temporaryTask != null;
    final category = isTemporary
        ? temporaryTask!.category
        : regularTaskNode!.category;

    // タイトルなどの基本情報
    final String title;
    final int duration;
    final DateTime baseDate;
    final String? detail;
    final String? aim;
    final bool useAim;
    final bool useDetail;
    final List<String> manualIds;
    final bool isImageRequired;

    if (isTemporary) {
      final t = temporaryTask!;
      title = t.title;
      duration = t.durationMinute;
      baseDate = t.baseDate;
      detail = t.detail;
      aim = t.aim;
      useAim = t.useAim;
      useDetail = t.useDetail;
      manualIds = t.manualIds;
      isImageRequired = t.isImageRequired;
    } else {
      final node = regularTaskNode!;
      final isStep = node.schedule.isStepTask;
      baseDate = node.schedule.baseDate;
      isImageRequired = false;

      if (isStep) {
        title = node.stepInfo?.title ?? '';
        duration = 0;
        detail = null;
        aim = null;
        useAim = false;
        useDetail = false;
        manualIds = node.stepInfo?.manualIds ?? [];
      } else {
        title = node.taskInfo?.title ?? '';
        duration = node.taskInfo?.durationMinute ?? 0;
        detail = node.taskInfo?.detail;
        aim = null;
        useAim = false;
        useDetail = node.taskInfo?.useDetail ?? false;
        manualIds = node.taskInfo?.manualIds ?? [];
      }
    }

    final catColor = _hexToColor(category?.colorHex);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // 1. Header (Category & Time)
              _buildHeader(
                context,
                category,
                catColor,
                isTemporary,
                regularTaskNode,
                duration,
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // 2. Deadline
                      _DeadlineSection(baseDate: baseDate),
                      const SizedBox(height: 16),

                      // 3. Title
                      Center(
                        child: Column(
                          children: [
                            if (isTemporary)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.blue,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  "タスク内容",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 4. Detail / Aim
                      if (useAim && (aim?.isNotEmpty ?? false))
                        _DetailBox(
                          title: '意義',
                          content: aim!,
                          color: Colors.blue[50]!,
                          titleColor: Colors.blue,
                        ),
                      if (useDetail && (detail?.isNotEmpty ?? false))
                        _DetailBox(
                          title: '詳細',
                          content: detail!,
                          color: Colors.grey[100]!,
                          titleColor: Colors.grey,
                        ),

                      const SizedBox(height: 16),

                      // 5. Manual
                      if (manualIds.isNotEmpty) ...[
                        Text(
                          'マニュアル',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'タップして確認してください',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ...manualIds.map(
                          (id) => _ManualButton(storeId: storeId, manualId: id),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 6. Main Content (Image or Steps)
                      if (isTemporary) ...[
                        if (isImageRequired) const _ImagePickerSection(),
                        const SizedBox(height: 24),
                      ] else if (regularTaskNode!.schedule.isStepTask) ...[
                        _StepListSection(
                          storeId: storeId, 
                          node: regularTaskNode!, 
                          operationDate: operationDate,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 7. Execute Button Area (Footer)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: isTemporary
                    ? _ExecuteButton(
                        label: '完了',
                        // 画像が必須かつ未添付の場合はnullを渡してボタンを無効化
                        onPressed: (isImageRequired && imageFile == null)
                            ? null
                            : () => _handleTemporaryExecution(
                                context,
                                ref,
                                operationDate,
                                temporaryTask!,
                              ),
                      )
                    : regularTaskNode!.schedule.isStepTask
                    ? const SizedBox.shrink()
                    : _ExecuteButton(
                        label: '完了',
                        onPressed: () => _handleRegularExecution(
                          context,
                          ref,
                          operationDate,
                          regularTaskNode!,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header Helper
  Widget _buildHeader(
    BuildContext context,
    TaskCategory? category,
    Color catColor,
    bool isTemporary,
    RegularTaskNode? regularTaskNode,
    int duration,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "カテゴリー: ",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Flexible(
                    child: Text(
                      category?.title ?? '',
                      style: TextStyle(
                        color: catColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (category?.detail != null && category!.detail!.isNotEmpty)
                Text(
                  category.detail!,
                  style: TextStyle(color: catColor, fontSize: 10),
                ),
            ],
          ),
        ),
        Row(
          children: [
            if (!isTemporary && (regularTaskNode?.schedule.isStepTask ?? false))
              const SizedBox.shrink()
            else
              Text(
                '実施時間: $duration分',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  // Temporaryの実行処理
  Future<void> _handleTemporaryExecution(
    BuildContext context,
    WidgetRef ref,
    DateTime operationDate,
    TaskTemporary task,
  ) async {
    final controller = ref.read(taskActionControllerProvider);
    try {
      final bool? confirm = await _showConfirmDialog(context);
      if (confirm != true) return;

      await controller.executeTemporaryTask(
        storeId: storeId,
        operationDate: operationDate,
        task: task,
      );

      if (context.mounted) {
        // 完了通知を表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${task.title}」を完了しました'),
            backgroundColor: AppColors.blue, // または任意のカラー
            behavior: SnackBarBehavior.floating, // 浮いたスタイル（トーストに近い見た目）
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  // Regularの実行処理
  Future<void> _handleRegularExecution(
    BuildContext context,
    WidgetRef ref,
    DateTime operationDate,
    RegularTaskNode node,
  ) async {
    final controller = ref.read(taskActionControllerProvider);
    try {
      final bool? confirm = await _showConfirmDialog(context);
      if (confirm != true) return;

      await controller.executeRegularTask(
        storeId: storeId,
        operationDate: operationDate,
        node: node,
      );

      if (context.mounted) {
        final title = node.schedule.isStepTask
            ? node.stepInfo?.title
            : node.taskInfo?.title;
        // 完了通知を表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「$title」を完了しました'),
            backgroundColor: AppColors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認'),
        content: const Text('タスクを完了しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('実行'),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

// === Sub Components ===

// _ExecuteButton: onPressedをnullableに変更
class _ExecuteButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed; // Nullableに変更
  const _ExecuteButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // ボタンが無効な場合の色調整
    final bool isEnabled = onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          disabledBackgroundColor: Colors.grey[300], // 無効時の背景色
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isEnabled ? Colors.white : Colors.grey[600], // 無効時のテキスト色
          ),
        ),
      ),
    );
  }
}

class _ManualButton extends ConsumerWidget {
  final String storeId;
  final String manualId;

  const _ManualButton({required this.storeId, required this.manualId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manualListAsync = ref.watch(manualListProvider(storeId));

    return manualListAsync.when(
      loading: () => _buildPlaceholder(),
      error: (_, __) => const SizedBox.shrink(),
      data: (manuals) {
        final manual = manuals.where((m) => m.manualId == manualId).firstOrNull;

        if (manual == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ManualDetailPage(storeId: storeId, manual: manual),
                ),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4081),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4081).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      manual.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 40,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _DeadlineSection extends StatelessWidget {
  final DateTime baseDate;
  const _DeadlineSection({required this.baseDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(baseDate.year, baseDate.month, baseDate.day);
    final diff = target.difference(today).inDays;

    final bool isDelayed = diff < 0;
    final String diffText = diff == 0
        ? "今日"
        : "${diff.abs()}日${isDelayed ? '前' : '後'}";

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "期限:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.check_circle, color: Colors.grey, size: 20),
        const SizedBox(width: 4),
        Text(
          DateFormat('M月d日').format(baseDate),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDelayed ? Colors.red[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            diffText,
            style: TextStyle(
              color: isDelayed ? Colors.red : Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailBox extends StatelessWidget {
  final String title;
  final String content;
  final Color color;
  final Color titleColor;

  const _DetailBox({
    required this.title,
    required this.content,
    required this.color,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: titleColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(color: Colors.grey[800], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerSection extends ConsumerWidget {
  const _ImagePickerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageFile = ref.watch(taskImageStateProvider);
    final picker = ImagePicker();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageFile == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: const Center(
              child: Text("画像を提出してください", style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              imageFile,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final xFile = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (xFile != null) {
                  ref
                      .read(taskImageStateProvider.notifier)
                      .setImage(File(xFile.path));
                }
              },
              icon: const Icon(Icons.photo_library),
              label: const Text("アルバム"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final xFile = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (xFile != null) {
                  ref
                      .read(taskImageStateProvider.notifier)
                      .setImage(File(xFile.path));
                }
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text("カメラ"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepListSection extends ConsumerWidget {
  final String storeId;
  final RegularTaskNode node;
  final DateTime operationDate; // ★追記

  const _StepListSection({
    required this.storeId, 
    required this.node, 
    required this.operationDate, // ★追記
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ポイント1: StreamProviderをwatchして、Firestoreの更新をリアルタイムに検知する
    final nodesAsync = ref.watch(operationRegularTasksProvider(storeId: storeId, date: operationDate));

    return nodesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (latestNodes) {
        // 最新のリストから、今開いているタスクと同じドキュメントを特定する
        // 全ステップ完了してリストから消えた瞬間のために、見つからない場合は初期のnodeをフォールバックにする
        final latestNode = latestNodes.where((n) => n.schedule.id == node.schedule.id).firstOrNull ?? node;

        final stepInfos = latestNode.stepInfo!.stepInfos;
        final executedIds = latestNode.schedule.executedStepIds;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stepInfos.length,
          itemBuilder: (context, index) {
            final step = stepInfos[index];
            final isExecuted = executedIds.contains(step.id);
            
            bool showExecuteButton = false;
            if (!isExecuted) {
              if (index == 0) {
                showExecuteButton = true;
              } else {
                final prevStepId = stepInfos[index - 1].id;
                if (executedIds.contains(prevStepId)) {
                  showExecuteButton = true;
                }
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: isExecuted ? Colors.grey[50] : Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("ステップ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(width: 8),
                      Text("${step.durationMinute}分", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const Spacer(),
                      if (isExecuted) const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(step.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (step.useDetail && step.detail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(step.detail, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                  
                  if (showExecuteButton) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // ★ポイント2: 実行メソッドの戻り値（全完了したか）を受け取る
                            final isAllCompleted = await ref.read(taskActionControllerProvider).executeStepTask(
                              storeId: storeId,
                              node: latestNode, 
                              stepToExecute: step
                            );

                            if (!context.mounted) return;

                            if (isAllCompleted) {
                              // ① すべてのステップが完了したときの心地よいUX
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🎉 「${latestNode.stepInfo?.title}」のすべてのステップを完了しました！お疲れ様でした！'),
                                  backgroundColor: AppColors.blue,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              // モーダルを自動で閉じる
                              Navigator.pop(context);
                            } else {
                              // ② 途中のステップを完了したときのUX
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('「${step.title}」を完了しました。'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              // 画面は閉じず、watchの力で自動的に次のステップのボタンが出現します
                            }
                          } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text("実施", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Color _hexToColor(String? hexString) {
  if (hexString == null) return Colors.grey;
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
