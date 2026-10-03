import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

import 'message_controller.dart';

// -----------------------------------------------------------------------------
// Message Creation Modal
// -----------------------------------------------------------------------------
class MessageCreationModal extends ConsumerStatefulWidget {
  const MessageCreationModal({super.key});

  @override
  ConsumerState<MessageCreationModal> createState() =>
      _MessageCreationModalState();
}

class _MessageCreationModalState extends ConsumerState<MessageCreationModal> {
  // 初期値設定
  final TextEditingController _contentController = TextEditingController();

  // スケジュール設定
  bool _isScheduled = false; // default false
  late DateTime _scheduleDate;

  // 宛先
  final Set<String> _selectedWorkerIds = {};

  // 形式設定 - チェック
  bool _isCheckRequired = false;
  late DateTime _checkDeadlineDate;
  bool _isCheckShared = false;
  bool _isImageRequiredWhileCheck = false;

  // 形式設定 - アナウンス
  bool _isOperationAnnouncementRequired = false;

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  // 現在の時間より先で、最初の15分刻みの時間を計算
  void _initializeDates() {
    final now = DateTime.now();
    // 15分刻みに切り上げ
    int minute = now.minute;
    int remainder = minute % 15;
    int addMinutes = 15 - remainder;
    final baseFuture = now.add(Duration(minutes: addMinutes));

    // 秒とミリ秒を0にする
    _scheduleDate = DateTime(
      baseFuture.year,
      baseFuture.month,
      baseFuture.day,
      baseFuture.hour,
      baseFuture.minute,
    );

    // チェック期限の初期値はスケジュールのさらに1時間後などに設定しておく
    _checkDeadlineDate = _scheduleDate.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation & Submit
  // ---------------------------------------------------------------------------
  Future<void> _submit() async {
    final now = DateTime.now();

    // Validate: Content is empty
    if (_contentController.text.trim().isEmpty) {
      _showErrorDialog('内容を入力してください。');
      return;
    }

    // Validate: Receiver is empty
    if (_selectedWorkerIds.isEmpty) {
      _showErrorDialog('送信相手を選択してください。');
      return;
    }

    // Validate: Scheduled date is in the past
    if (_isScheduled && _scheduleDate.isBefore(now)) {
      _showErrorDialog('スケジュール時間は現在より未来の日時を設定してください。');
      return;
    }

    // Validate: Check deadline is before schedule date
    final effectiveStartDate = _isScheduled ? _scheduleDate : now;
    if (_isCheckRequired) {
      // _enableCheckDeadlineの条件を削除
      if (_checkDeadlineDate.isBefore(effectiveStartDate)) {
        _showErrorDialog('チェック期限はスケジュール日時より後に設定してください。');
        return;
      }
    }

    // 送信処理
    try {
      await ref
          .read(messageControllerProvider.notifier)
          .sendMessage(
            receiverIds: _selectedWorkerIds.toList(),
            content: _contentController.text,
            isScheduled: _isScheduled,
            scheduleDate: _scheduleDate,
            isCheckRequired: _isCheckRequired,
            isCheckShared: _isCheckShared,
            checkDeadline: _isCheckRequired ? _checkDeadlineDate : null,
            isImageRequiredWhileCheck: _isImageRequiredWhileCheck,
            isOperationAnnouncementRequired: _isOperationAnnouncementRequired,
          );

      if (mounted) {
        Navigator.of(context).pop(); // 完了したら閉じる
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('メッセージを作成しました')));
      }
    } catch (e) {
      _showErrorDialog('送信に失敗しました: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '入力エラー',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: const TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(fontFamily: 'Inter', color: Color(0xFF0084FF)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Builders
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // 全画面モーダル風のデザイン
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // 少しグレーの背景にしてカードを目立たせる
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'メッセージを作成',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text(
              '送信',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF0084FF), // ブランドカラーの青
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE0E0E0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('送信設定'),
            const SizedBox(height: 8),
            _buildScheduleCard(),

            const SizedBox(height: 24),
            _buildSectionHeader('宛先'),
            const SizedBox(height: 8),
            _buildReceiverCard(),

            const SizedBox(height: 24),
            _buildSectionHeader('メッセージ内容'),
            const SizedBox(height: 8),
            _buildContentCard(),

            const SizedBox(height: 24),
            _buildSectionHeader('オプション'),
            const SizedBox(height: 8),
            _buildFormatCard(),

            // 下部の余白
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // セクションヘッダー
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF858585), // グレー
        fontFamily: 'Inter',
      ),
    );
  }

  // 共通カードデザイン
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: child,
    );
  }

  // 1. スケジュールカード
  Widget _buildScheduleCard() {
    return _buildCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 20,
                    color: Color(0xFF858585),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '予約送信',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _isScheduled,
                activeThumbColor: const Color(0xFF0084FF),
                onChanged: (val) {
                  setState(() {
                    _isScheduled = val;
                    if (_isScheduled) {
                      _initializeDates();
                    }
                  });
                },
              ),
            ],
          ),
          if (_isScheduled) ...[
            const Divider(height: 24, color: Color(0xFFEEEEEE)),
            InkWell(
              onTap: () => _pickDateTime(
                initialDate: _scheduleDate,
                onConfirm: (date) => setState(() => _scheduleDate = date),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('yyyy年MM月dd日 HH:mm').format(_scheduleDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF858585),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 2. 宛先カード
  Widget _buildReceiverCard() {
    final workersAsync = ref.watch(selectableStoreWorkersProvider);

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '送信するメンバーを選択',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              if (_selectedWorkerIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0084FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_selectedWorkerIds.length}名',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          workersAsync.when(
            data: (workers) => Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: workers.map((worker) {
                final isSelected = _selectedWorkerIds.contains(worker['id']);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedWorkerIds.remove(worker['id']!);
                      } else {
                        _selectedWorkerIds.add(worker['id']!);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0084FF)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0084FF)
                            : const Color(0xFFE0E0E0),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      worker['name'] ?? '',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF666666),
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, _) => const Text(
              '従業員の読み込みに失敗しました',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // 3. コンテンツカード
  Widget _buildContentCard() {
    return _buildCard(
      child: TextField(
        controller: _contentController,
        maxLines: 6,
        style: const TextStyle(fontSize: 15, fontFamily: 'Inter', height: 1.5),
        decoration: InputDecoration(
          hintText: 'メッセージを入力してください...',
          hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  // 4. オプション（形式）カード
  Widget _buildFormatCard() {
    return _buildCard(
      child: Column(
        children: [
          // チェック機能
          _buildSwitchRow(
            icon: Icons.check_circle_outline,
            title: 'チェックを求める',
            value: _isCheckRequired,
            onChanged: (val) => setState(() => _isCheckRequired = val),
            activeColor: const Color(0xFFFE8700), // オレンジ
          ),

          if (_isCheckRequired) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 0, bottom: 12),
              child: Column(
                children: [
                  const Divider(color: Color(0xFFF5F5F5)),

                  // 期限設定（トグルを廃止し、必須入力のUIに変更）
                  Row(
                    children: [
                      Container(
                        width: 2,
                        height: 16,
                        color: const Color(0xFFEEEEEE),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      const Expanded(
                        child: Text(
                          'チェック期限 (必須)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF444444),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _pickDateTime(
                          initialDate: _checkDeadlineDate,
                          onConfirm: (date) =>
                              setState(() => _checkDeadlineDate = date),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0E0), // 薄いオレンジ背景
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            DateFormat(
                              'MM/dd HH:mm',
                            ).format(_checkDeadlineDate),
                            style: const TextStyle(
                              color: Color(0xFFFE8700),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 共有設定
                  _buildSubOptionRow(
                    title: 'チェックを共有 (誰か1人でOK)',
                    value: _isCheckShared,
                    onChanged: (val) => setState(() => _isCheckShared = val),
                  ),
                  const SizedBox(height: 8),
                  // 画像必須設定
                  _buildSubOptionRow(
                    title: '画像の提出を必須にする',
                    value: _isImageRequiredWhileCheck,
                    onChanged: (val) =>
                        setState(() => _isImageRequiredWhileCheck = val),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 24, color: Color(0xFFEEEEEE)),

          // アナウンス機能
          _buildSwitchRow(
            icon: Icons.volume_up_outlined,
            title: '勤務中アナウンス',
            subtitle: '出勤中のメンバーに音声で通知します',
            value: _isOperationAnnouncementRequired,
            onChanged: (val) =>
                setState(() => _isOperationAnnouncementRequired = val),
            activeColor: const Color(0xFF8A6FE6), // 紫
          ),
        ],
      ),
    );
  }

  // スイッチ行のヘルパー
  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: value ? activeColor : const Color(0xFF858585),
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF858585),
                    fontFamily: 'Inter',
                  ),
                ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // サブオプション行のヘルパー
  Widget _buildSubOptionRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? trailing,
  }) {
    return Row(
      children: [
        // サブ階層の線
        Container(
          width: 2,
          height: 16,
          color: const Color(0xFFEEEEEE),
          margin: const EdgeInsets.only(right: 8),
        ),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF444444),
              fontFamily: 'Inter',
            ),
          ),
        ),
        if (trailing != null) ...[trailing, const SizedBox(width: 8)],
        SizedBox(
          height: 30,
          child: Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: value,
              activeThumbColor: const Color(0xFFFE8700),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // 汎用 DatePicker Helper (日付と時間をまとめて設定)
  Future<void> _pickDateTime({
    required DateTime initialDate,
    required Function(DateTime) onConfirm,
  }) async {
    // 15分刻みに合わせるための初期値調整
    final initialMinute = (initialDate.minute ~/ 15) * 15;
    final adjustedInitialDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
      initialDate.hour,
      initialMinute,
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        DateTime tempPickedDate = adjustedInitialDate;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ヘッダー (キャンセル / 完了)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'キャンセル',
                        style: TextStyle(
                          color: Color(0xFF858585),
                          fontSize: 15,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const Text(
                      '日時を選択',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onConfirm(tempPickedDate);
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '完了',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0084FF),
                          fontSize: 15,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // 統合型ピッカー (日付と時刻を同時に)
              SizedBox(
                height: 250, // 少し高さを確保
                child: CupertinoDatePicker(
                  // ★ここがポイント: 日付と時刻を同時に選ぶモード
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: adjustedInitialDate,
                  minuteInterval: 15, // 15分刻み
                  use24hFormat: true,
                  // 過去の日付を選べないように制限する場合
                  minimumDate: DateTime.now().subtract(
                    const Duration(minutes: 15),
                  ),
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
                  onDateTimeChanged: (DateTime newDate) {
                    tempPickedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
