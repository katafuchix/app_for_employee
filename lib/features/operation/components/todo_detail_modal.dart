import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tebanashi/features/manual/manual_page.dart';

import '../../manual/manual_controller.dart';
import '../controllers/todo_action_controller.dart';
import '../models/todo_model.dart';
import '../providers/operation_attendance_provider.dart';
import '../providers/operation_logic.dart';
import '../providers/operation_todo_provider.dart';

class TodoDetailModal extends ConsumerStatefulWidget {
  final OperationTodoItem item;
  final String storeId;
  final String positionTitle;
  final Color positionColor;
  final int todoIndex;
  final DateTime openDate;

  const TodoDetailModal({
    super.key,
    required this.item,
    required this.storeId,
    required this.positionTitle,
    required this.positionColor,
    required this.todoIndex,
    required this.openDate,
  });

  @override
  ConsumerState<TodoDetailModal> createState() => _TodoDetailModalState();
}

class _TodoDetailModalState extends ConsumerState<TodoDetailModal> {
  late int _inputCount;
  final Set<String> _checkedItemIds = {};
  final _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.execution?.countableCount != null) {
      _inputCount = widget.item.execution!.countableCount!;
    } else {
      _inputCount = widget.item.mapping.countableDefault ?? 0;
    }

    if (widget.item.isDone) {
      final checklist = widget.item.todoMaster?.completionChecklist ?? [];
      _checkedItemIds.addAll(checklist.map((e) => e.id));
    }
  }

  Future<void> _onCompletePressed(Map<String, File> currentDrafts) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(todoActionControllerProvider)
          .completeTodo(
            storeId: widget.storeId,
            item: widget.item,
            baseDate: widget.openDate,
            inputCount: _inputCount,
            imageFiles: currentDrafts,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${widget.item.todoMaster?.title}」を完了しました'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage(String submissionId) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (pickedFile == null) return;
    if (!mounted) return;

    ref
        .read(todoImageDraftProvider.notifier)
        .saveDraft(
          scope: _draftScope,
          submissionId: submissionId,
          file: File(pickedFile.path),
        );
  }

  void _removeImage(String submissionId) {
    ref
        .read(todoImageDraftProvider.notifier)
        .removeDraft(scope: _draftScope, submissionId: submissionId);
  }

  TodoImageDraftScope get _draftScope {
    return TodoImageDraftScope(
      storeId: widget.storeId,
      baseDate: widget.openDate,
      mappingId: widget.item.mapping.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.item.todoMaster;
    if (todo == null) return const Center(child: Text('データエラー'));

    final allDrafts = ref.watch(todoImageDraftProvider);
    final currentDrafts = allDrafts[_draftScope.key] ?? const <String, File>{};
    final isCountable = todo.durationType == TodoDurationType.countable;
    final requiredInfos = todo.imageSubmissionInfos
        .where((info) => info.isRequired)
        .toList();
    final missingRequiredInfos = requiredInfos
        .where((info) => !currentDrafts.containsKey(info.id))
        .toList();

    final isChecklistComplete =
        !todo.useCompletionChecklist ||
        (_checkedItemIds.length == todo.completionChecklist.length);
    final canComplete = isChecklistComplete && missingRequiredInfos.isEmpty;

    final isWorkingAsync = ref.watch(
      isCurrentUserWorkingProvider(
        storeId: widget.storeId,
        date: widget.openDate,
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: isWorkingAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => SizedBox(
            height: 200,
            child: Center(child: Text('エラーが発生しました: $err')),
          ),
          data: (isWorking) {
            final isEditable = isWorking && !widget.item.isDone;
            return Column(
              children: [
                _buildHeader(context, todo),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleSection(todo),
                        const SizedBox(height: 24),
                        _buildManualSection(todo),
                        if (!widget.item.isDone || widget.item.isSkipped)
                          _buildPreviousExecutionPlaceholder(),
                        if (isCountable) ...[
                          const SizedBox(height: 24),
                          _buildCountInputSection(todo, isEditable),
                        ],
                        if (todo.useCompletionChecklist) ...[
                          const SizedBox(height: 24),
                          _buildChecklistSection(todo, isEditable),
                        ],
                        if (todo.imageSubmissionInfos.isNotEmpty ||
                            _hasOtherSubmittedImages(todo)) ...[
                          const SizedBox(height: 24),
                          _buildImageSection(
                            todo: todo,
                            currentDrafts: currentDrafts,
                            isEditable: isEditable,
                          ),
                        ],
                        if (isEditable && missingRequiredInfos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            '必須画像が不足しています: ${missingRequiredInfos.map((e) => e.title).join('、')}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildActionArea(
                  todo: todo,
                  currentDrafts: currentDrafts,
                  isWorking: isWorking,
                  canComplete: canComplete,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _hasOtherSubmittedImages(Todo todo) {
    final submittedIds =
        widget.item.execution?.submissionImageIds ?? const <String>[];
    final knownIds = todo.imageSubmissionInfos.map((info) => info.id).toSet();
    return submittedIds.any((id) => !knownIds.contains(id));
  }

  Widget _buildHeader(BuildContext context, Todo todo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.positionColor),
                ),
                child: Text(
                  widget.positionTitle,
                  style: TextStyle(
                    color: widget.positionColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lv.${todo.difficulty}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.purpleAccent,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(Todo todo) {
    final isDone = widget.item.isDone;
    final isSkipped = widget.item.isSkipped;
    final durationText = todo.durationType == TodoDurationType.fixed
        ? '${todo.durationMinute}分'
        : '× ${todo.countableDurationPerOne}分';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isDone
                ? (isSkipped ? Colors.orange : Colors.green)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDone
                    ? (isSkipped ? Icons.skip_next : Icons.check)
                    : Icons.circle,
                size: 12,
                color: isDone ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                isDone ? (isSkipped ? 'スキップ済み' : '完了済み') : '未完了',
                style: TextStyle(
                  color: isDone ? Colors.white : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.todoIndex}. ${todo.title}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (todo.useDetail && todo.detail.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(todo.detail, style: const TextStyle(color: Colors.black87)),
        ],
        const SizedBox(height: 8),
        Text(
          durationText,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildManualSection(Todo todo) {
    if (todo.shortManual.isEmpty && todo.manualIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todo.useShortManual && todo.shortManual.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  '小マニュアル',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  todo.shortManual,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        if (todo.manualIds.isNotEmpty) ...[
          const Text(
            'マニュアル',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF4081),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'タップして確認してください',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...todo.manualIds.map((id) {
            return _ManualButton(storeId: widget.storeId, manualId: id);
          }),
        ],
      ],
    );
  }

  Widget _buildPreviousExecutionPlaceholder() {
    final todoId = widget.item.todoMaster?.id ?? '';
    final asyncValue = ref.watch(
      latestTodoExecutionProvider(storeId: widget.storeId, todoId: todoId),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '前回の実施',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          asyncValue.when(
            loading: () => const Text(
              '読み込み中...',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            error: (err, stack) => const Text(
              '履歴の取得に失敗しました',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            data: (data) {
              final exec = data.execution;
              if (exec == null) {
                return const Text(
                  '前回の実施記録はありません',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                );
              }

              final difference = DateTime.now().difference(
                exec.executionEndTime,
              );
              final relativeDate = difference.inDays >= 1
                  ? '${difference.inDays}日前'
                  : difference.inHours >= 1
                  ? '${difference.inHours}時間前'
                  : '数分前';
              final timeStr = DateFormat('HH:mm').format(exec.executionEndTime);
              final photoUrl = data.workerPhotoUrl;
              final displayName = data.workerName ?? '担当者不明';
              final countText = exec.countableCount != null
                  ? '${exec.countableCount}個'
                  : '';

              return Row(
                children: [
                  Text(
                    relativeDate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: photoUrl != null
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (countText.isNotEmpty)
                    Text(
                      countText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCountInputSection(Todo todo, bool isEditable) {
    final estimatedTime = todo.countableDurationPerOne * _inputCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'カウントの値入力',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  const TextSpan(text: '記録される実施時間: '),
                  TextSpan(
                    text: '$estimatedTime',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const TextSpan(text: ' 分'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'カウントのタイトル',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.play_arrow, size: 14, color: Colors.black),
                    Text(
                      todo.countableTitle.isNotEmpty
                          ? todo.countableTitle
                          : '仕込んだ数',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '$_inputCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    todo.countableCountUnit,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildCountButton(
              icon: Icons.remove,
              onPressed: isEditable
                  ? () {
                      if (_inputCount > 0) {
                        setState(() => _inputCount--);
                      }
                    }
                  : null,
            ),
            const SizedBox(width: 8),
            _buildCountButton(
              icon: Icons.add,
              onPressed: isEditable
                  ? () => setState(() => _inputCount++)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountButton({required IconData icon, VoidCallback? onPressed}) {
    return SizedBox(
      width: 24,
      height: 24,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildChecklistSection(Todo todo, bool isEditable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'チェックリスト',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${_checkedItemIds.length}/${todo.completionChecklist.length}',
              style: TextStyle(
                color: _checkedItemIds.length == todo.completionChecklist.length
                    ? Colors.green
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...todo.completionChecklist.map((item) {
          final isChecked = _checkedItemIds.contains(item.id);
          return CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(item.content),
            value: isChecked,
            onChanged: isEditable
                ? (value) {
                    setState(() {
                      if (value == true) {
                        _checkedItemIds.add(item.id);
                      } else {
                        _checkedItemIds.remove(item.id);
                      }
                    });
                  }
                : null,
          );
        }),
      ],
    );
  }

  Widget _buildImageSection({
    required Todo todo,
    required Map<String, File> currentDrafts,
    required bool isEditable,
  }) {
    final submittedIds =
        widget.item.execution?.submissionImageIds ?? const <String>[];
    final knownIds = todo.imageSubmissionInfos.map((info) => info.id).toSet();
    final otherIds = submittedIds
        .where((id) => !knownIds.contains(id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('画像を提出', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...todo.imageSubmissionInfos.map((info) {
          final hasServerImage = submittedIds.contains(info.id);
          final localDraft = currentDrafts[info.id];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ImageSubmissionCard(
              storeId: widget.storeId,
              executionId: widget.item.execution?.id,
              info: info,
              localDraft: localDraft,
              hasServerImage: hasServerImage,
              isEditable: isEditable,
              onPickImage: isEditable ? () => _pickImage(info.id) : null,
              onRemoveImage: isEditable && localDraft != null
                  ? () => _removeImage(info.id)
                  : null,
            ),
          );
        }),
        ...otherIds.map((submissionId) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _OtherImageCard(
              storeId: widget.storeId,
              executionId: widget.item.execution?.id,
              submissionId: submissionId,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionArea({
    required Todo todo,
    required Map<String, File> currentDrafts,
    required bool isWorking,
    required bool canComplete,
  }) {
    if (!isWorking) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: Colors.grey[100],
        child: Column(
          children: [
            const Icon(Icons.work_off, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              '勤務時間外のため操作できません',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '完了・スキップ・削除を行うには出勤打刻をしてください',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return _buildActionButtons(todo, currentDrafts, canComplete);
  }

  Widget _buildActionButtons(
    Todo todo,
    Map<String, File> currentDrafts,
    bool canComplete,
  ) {
    if (widget.item.isDone) {
      final isSkipped = widget.item.isSkipped;
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: isSkipped
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSkipped ? Icons.skip_next : Icons.check_circle,
                    color: isSkipped ? Colors.orange : Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isSkipped ? 'スキップ済み' : '完了済み',
                    style: TextStyle(
                      color: isSkipped ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('確認'),
                      content: const Text('実施記録を削除しますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('削除'),
                        ),
                      ],
                    ),
                  );

                  if (result != true) return;

                  setState(() => _isLoading = true);
                  try {
                    await ref
                        .read(todoActionControllerProvider)
                        .deleteExecution(
                          storeId: widget.storeId,
                          executionId: widget.item.execution!.id,
                        );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('実施記録を削除しました'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  '実施記録を削除',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.red.withValues(alpha: 0.05),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (todo.isSkippable)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            await ref
                                .read(todoActionControllerProvider)
                                .skipTodo(
                                  storeId: widget.storeId,
                                  item: widget.item,
                                  baseDate: widget.openDate,
                                );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '「${widget.item.todoMaster?.title}」をスキップしました',
                                ),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text(
                    'スキップ',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (canComplete && !_isLoading)
                  ? () => _onCompletePressed(currentDrafts)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey[300],
                elevation: canComplete ? 2 : 0,
              ),
              child: const Text(
                '完了',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSubmissionCard extends ConsumerWidget {
  final String storeId;
  final String? executionId;
  final ImageSubmissionInfo info;
  final File? localDraft;
  final bool hasServerImage;
  final bool isEditable;
  final VoidCallback? onPickImage;
  final VoidCallback? onRemoveImage;

  const _ImageSubmissionCard({
    required this.storeId,
    required this.executionId,
    required this.info,
    required this.localDraft,
    required this.hasServerImage,
    required this.isEditable,
    this.onPickImage,
    this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagColor = info.isRequired
        ? const Color(0xFFFFD54F)
        : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                info.isRequired ? '必須' : '任意',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${info.imageType.title} / ${info.imageType.englishTitle}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          info.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _ImagePreviewBox(
          storeId: storeId,
          executionId: executionId,
          submissionId: info.id,
          localDraft: localDraft,
          hasServerImage: hasServerImage,
          emptyLabel: isEditable ? 'タップして撮影' : '未提出',
          onTap: isEditable ? onPickImage : null,
          onRemove: onRemoveImage,
        ),
      ],
    );
  }
}

class _OtherImageCard extends StatelessWidget {
  final String storeId;
  final String? executionId;
  final String submissionId;

  const _OtherImageCard({
    required this.storeId,
    required this.executionId,
    required this.submissionId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'その他',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Other / その他',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '未登録の提出枠: $submissionId',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _ImagePreviewBox(
          storeId: storeId,
          executionId: executionId,
          submissionId: submissionId,
          localDraft: null,
          hasServerImage: true,
          emptyLabel: '未提出',
        ),
      ],
    );
  }
}

class _ImagePreviewBox extends ConsumerWidget {
  final String storeId;
  final String? executionId;
  final String submissionId;
  final File? localDraft;
  final bool hasServerImage;
  final String emptyLabel;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _ImagePreviewBox({
    required this.storeId,
    required this.executionId,
    required this.submissionId,
    required this.localDraft,
    required this.hasServerImage,
    required this.emptyLabel,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLocalImage = localDraft != null;

    if (!hasLocalImage && !hasServerImage) {
      return InkWell(
        onTap: onTap,
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
              Text(emptyLabel, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
            image: hasLocalImage
                ? DecorationImage(
                    image: FileImage(localDraft!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: !hasLocalImage && hasServerImage && executionId != null
              ? _ServerImagePreview(
                  storeId: storeId,
                  executionId: executionId!,
                  submissionId: submissionId,
                )
              : null,
        ),
        if (onRemove != null)
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onRemove,
              ),
            ),
          ),
      ],
    );
  }
}

class _ServerImagePreview extends ConsumerWidget {
  final String storeId;
  final String executionId;
  final String submissionId;

  const _ServerImagePreview({
    required this.storeId,
    required this.executionId,
    required this.submissionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrlAsync = ref.watch(
      todoExecutionImageUrlProvider(
        storeId: storeId,
        executionId: executionId,
        submissionImageId: submissionId,
      ),
    );

    return imageUrlAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, stack) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            Text('取得失敗', style: TextStyle(fontSize: 10, color: Colors.red)),
          ],
        ),
      ),
      data: (url) {
        if (url == null || url.isEmpty) {
          return const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 40,
              color: Colors.grey,
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
          ),
        );
      },
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
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ManualDetailPage(storeId: storeId, manual: manual),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF4081).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      manual.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFFF4081)),
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
      width: double.infinity,
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
