import 'dart:io'; // 追加: File型を使用するため
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart'; // 追加: image_picker
import 'package:intl/intl.dart';

import 'message_controller.dart';
import 'message_models.dart';

class MessageDetailModal extends ConsumerStatefulWidget {
  final String messageId;

  const MessageDetailModal({super.key, required this.messageId});

  @override
  ConsumerState<MessageDetailModal> createState() => _MessageDetailModalState();
}

class _MessageDetailModalState extends ConsumerState<MessageDetailModal> {
  // Action Form State
  final TextEditingController _replyController = TextEditingController();
  bool _isChecked = false;
  
  // 画像関連のState
  final ImagePicker _picker = ImagePicker(); // 追加
  String? _imagePath; 
  File? _imageFile; // 追加: プレビュー表示用

  @override
  void initState() {
    super.initState();
    // テキスト入力の変更を監視して、ボタンの活性状態を更新するために再描画する
    _replyController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  // --- 画像選択用メソッド (追加) ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // 容量節約のため圧縮（任意）
      );

      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像の取得に失敗しました')),
        );
      }
    }
  }

  // --- 画像ソース選択ダイアログ (追加) ---
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラで撮影'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('アルバムから選択'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _canSubmit(Message message) {
    // 0. スケジュール待機中の場合は押せない
    if (message.isScheduled && DateTime.now().isBefore(message.scheduleDate)) {
      return false;
    }

    // 1. チェックが必要なのにチェックされていなければ押せない
    if (message.isCheckRequired && !_isChecked) {
      return false;
    }

    // 2. チェック必須 かつ 画像必須 なのに画像が指定されていなければ押せない
    if (message.isCheckRequired && message.isImageRequiredWhileCheck && _imageFile == null) {
      return false;
    }

    // 3. すべてが空（テキストなし、チェックなし、画像なし）の場合は押せない
    final hasText = _replyController.text.trim().isNotEmpty;
    final hasImage = _imageFile != null;
    final hasCheck = _isChecked;

    if (!hasText && !hasImage && !hasCheck) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch Basic Data
    final myIdAsync = ref.watch(currentStoreWorkerIdProvider);
    final messageAsync = ref.watch(messageDetailFamilyProvider(widget.messageId));
    final actionsAsync = ref.watch(messageActionsFamilyProvider(widget.messageId));
    final workersAsync = ref.watch(storeWorkersProvider);

    return Container(
      // Full screen modal style
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        type: MaterialType.transparency,
        child: myIdAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (myId) {
            return messageAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (message) {
                if (message == null) return const Center(child: Text('メッセージが見つかりません'));

                return actionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => const SizedBox(),
                  data: (actions) {
                    return workersAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (workersList) {
                        final workerMap = {
                          for (var w in workersList) w['id']: w['name']
                        };

                        // isAlreadyDone判定（受信者の場合のみ）
                        final isReceiver = message.receiverIds.contains(myId);
                        final myAction = actions.where((a) => a.actorId == myId).firstOrNull;
                        final isAlreadyDone = isReceiver && myAction != null;

                        return Column(
                          children: [
                            // --- Grab Bar ---
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 12, bottom: 8),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // --- Header ---
                            _buildHeader(context, message, myId, workerMap),

                            // --- Scrollable Content ---
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Message Content Section
                                    _buildMessageContent(message, isAlreadyDone: isAlreadyDone),
                                    
                                    const SizedBox(height: 24),

                                    // Action Input Form (User's area)
                                    _buildActionFormCard(message, myId, actions),

                                    const SizedBox(height: 32),
                                    const Divider(),
                                    const SizedBox(height: 16),

                                    // Status List (Receivers status)
                                    _buildStatusList(message, actions, workerMap, myId),
                                    
                                    // 下部の余白確保
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Components
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, Message message, String myId, Map<String?, String?> workerMap) {
    // ... (変更なし) ...
    final isSender = message.senderId == myId;
    final senderName = workerMap[message.senderId] ?? '不明';
    final receiverCount = message.receiverIds.length;
    final firstReceiverName = message.receiverIds.isNotEmpty 
        ? (message.receiverIds.first == myId ? 'あなた' : workerMap[message.receiverIds.first]) 
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'メッセージの詳細',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (isSender)
                GestureDetector(
                  onTap: () => _confirmDelete(context, message),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF30909),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        const Text('削除', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('From:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.account_circle, size: 36),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            senderName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward,
                      size: 32,
                      color: Colors.black,
                      weight: 700,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('To:', style: TextStyle(fontSize: 10, color: Color(0xFF858585))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.account_circle, size: 36),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.3),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.black),
                                  children: [
                                    TextSpan(text: '$firstReceiverName ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    if (receiverCount > 1)
                                      TextSpan(text: '他', style: const TextStyle(fontSize: 12, color: Colors.black)),
                                    TextSpan(text: '${receiverCount - 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                                    const TextSpan(text: '人', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.black)),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '作成日: ',
                      style: TextStyle(color: Color(0xFF858585), fontSize: 11),
                    ),
                    TextSpan(
                      text: DateFormat('M月d日 HH:mm').format(message.metadata.firstInteractionTime!),
                      style: const TextStyle(color: Color(0xFF858585), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'スケジュール: ',
                      style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: message.isScheduled
                          ? DateFormat('M月d日 HH:mm').format(message.scheduleDate)
                          : 'なし',
                      style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Message message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('削除'),
        content: const Text('このメッセージを削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('削除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(messageControllerProvider.notifier).deleteMessage(message.id);
      Navigator.pop(context);
    }
  }

  // 経過時間をフォーマットするヘルパー
  String _formatOverdue(DateTime deadline) {
    final diff = DateTime.now().difference(deadline);
    if (diff.inDays > 0) return '${diff.inDays}日';
    if (diff.inHours > 0) return '${diff.inHours}時間';
    return '${diff.inMinutes}分';
  }

  Widget _buildMessageContent(Message message, {required bool isAlreadyDone}) {
    final isLate = message.checkDeadline != null && DateTime.now().isAfter(message.checkDeadline!);
    final deadlineDay = message.checkDeadline != null
        ? DateFormat('M/d').format(message.checkDeadline!)
        : '';
    final deadlineTime = message.checkDeadline != null
        ? DateFormat('HH:mm').format(message.checkDeadline!)
        : '';

    return Column(
      children: [
        Text(
          message.content,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (message.isCheckRequired) ...[
              Container(
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isAlreadyDone ? const Color(0xFF858585) : const Color(0xFFFE8700),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      message.isCheckShared ? 'チェック付き（共有）' : 'チェック付き',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (message.checkDeadline != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$deadlineDay ',
                              style: TextStyle(
                                color: isLate ? const Color(0xFFFF3232) : const Color(0xFFFE8700),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            TextSpan(
                              text: deadlineTime,
                              style: TextStyle(
                                color: isLate ? const Color(0xFFFF3232) : const Color(0xFFFE8700),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            TextSpan(
                              text: 'まで',
                              style: TextStyle(
                                color: isLate ? const Color(0xFFFF3232) : const Color(0xFFFE8700),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLate)
                        Text(
                          '${_formatOverdue(message.checkDeadline!)}遅れ',
                          style: const TextStyle(
                            color: Color(0xFFFF3232),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
            ],
            if (message.isOperationAnnouncementRequired) ...[
              const Spacer(),
              Container(
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isAlreadyDone ? const Color(0xFF858585) : const Color(0xFF8B20DC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volume_up, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    const Text(
                      'アナウンス',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionFormCard(Message message, String myId, List<MessageAction> actions) {
    if (!message.receiverIds.contains(myId)) {
      return const SizedBox.shrink();
    }

    final myAction = actions.where((a) => a.actorId == myId).firstOrNull;
    final isAlreadyDone = myAction != null;
    final isLate = message.checkDeadline != null && DateTime.now().isAfter(message.checkDeadline!);
    final isImageRequired = message.isImageRequiredWhileCheck;

    // ロック判定: スケジュールされていて、まだその日時になっていない場合
    final isLocked = message.isScheduled && DateTime.now().isBefore(message.scheduleDate);

    final isValid = _canSubmit(message);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply Input
          SizedBox(
            height: 27,
            child: TextField(
              controller: _replyController,
              enabled: !isAlreadyDone && !isLocked, // ロック時は無効
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: isAlreadyDone
                    ? (myAction.replyFromReceiver?.isNotEmpty == true ? myAction.replyFromReceiver : '返信なし')
                    : (isLocked ? '指定日時まで返信できません' : '返信を入力'),
                hintStyle: const TextStyle(
                  color: Color(0xFFB8B8B8),
                  fontSize: 9,
                  fontWeight: FontWeight.w300,
                ),
                filled: true,
                fillColor: (isAlreadyDone || isLocked) ? Colors.grey[100] : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image Picker Area
              GestureDetector(
                onTap: (isAlreadyDone || isLocked)
                    ? null
                    : () => _showImageSourceActionSheet(),
                child: Container(
                  width: 240,
                  height: 90,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    image: (_imageFile != null && !isAlreadyDone)
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                          child: isAlreadyDone && myAction.actionTypes.contains('image')
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check, color: Color(0xFF1AD84C)),
                                    SizedBox(height: 10),
                                    Text('画像提出済み', style: TextStyle(fontSize: 10))
                                  ]
                                )
                              : _imageFile != null
                                  ? const SizedBox.shrink()
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt, color: isLocked ? Colors.grey[300] : const Color(0xFF858585), size: 28),
                                        const SizedBox(height: 10),
                                        Text(
                                          isLocked
                                              ? '待機中'
                                              : (isImageRequired ? '画像の提出が求められています': '画像を添付 (任意)'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: isLocked ? Colors.grey[400] : const Color(0xFF858585),
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                        // 削除ボタン (未完了で画像選択済みの場合のみ)
                        if (_imageFile != null && !isAlreadyDone && !isLocked)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imageFile = null;
                                  _imagePath = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              if (message.isCheckRequired) ...[
                const SizedBox(width: 16),

                // Checkbox Area
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('チェックを付ける', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF858585))),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: (isAlreadyDone || isLocked) ? null : () => setState(() => _isChecked = !_isChecked),
                        child: Container(
                          width: 27,
                          height: 27,
                          decoration: BoxDecoration(
                            color: (isAlreadyDone ? myAction.actionTypes.contains('check') : _isChecked)
                                ? const Color(0xFFFE8700)
                                : const Color(0xFF858585),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (isLate && !isAlreadyDone) ...[
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning, size: 14, color: Color(0xFFFF3232)),
                            SizedBox(width: 2),
                            Text('期限超過', style: TextStyle(color: Color(0xFFFF3232), fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: 339,
            height: 21,
            child: ElevatedButton(
              onPressed: (isAlreadyDone || !isValid || isLocked) ? null : () => _submitAction(message),
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid && !isLocked ? const Color(0xFF0084FF) : Colors.grey[300],
                disabledBackgroundColor: const Color(0xFF858585),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
              child: Text(
                isAlreadyDone ? '完了済み' : (isLocked ? 'スケジュール待機中' : '完了'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAction(Message message) async {
    // Validation
    if (message.isScheduled && DateTime.now().isBefore(message.scheduleDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('指定日時になるまで送信できません')));
      return;
    }
    
    // チェック必須の確認
    if (message.isCheckRequired && !_isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('チェックが必要です')));
      return;
    }
    
    // 画像必須の確認
    if (message.isCheckRequired && message.isImageRequiredWhileCheck && _imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('画像の提出が必須です')));
      return;
    }

    // すべて空欄の確認（ボタンは非活性になりますが、念のためのガード）
    final hasText = _replyController.text.trim().isNotEmpty;
    final hasImage = _imagePath != null;
    final hasCheck = _isChecked;

    if (!hasText && !hasImage && !hasCheck) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('テキスト、チェック、または画像のいずれかを入力してください')));
      return;
    }

    try {
      await ref.read(messageControllerProvider.notifier).sendAction(
        message: message,
        replyContent: _replyController.text, // テキストが空欄の場合は空文字で送信されます
        imagePath: _imagePath,
        isCheckAction: _isChecked,
      );
      
      if (mounted) {
         // 送信成功時のフィードバックが必要であればここに記述
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }

  // ... (以下 _buildStatusList など変更なし) ...
  Widget _buildStatusList(Message message, List<MessageAction> actions, Map<String?, String?> workerMap, String myId) {
     // ... (元の実装のまま) ...
     final total = message.receiverIds.length;
    final readCount = message.receiverIds.where((id) => message.readTimeMap.containsKey(id)).length;
    final checkedUserIds = <String>{};
    for (var act in actions) {
      if (act.actionTypes.contains('check')) checkedUserIds.add(act.actorId);
    }
    final checkCount = checkedUserIds.length;
    final isLate = message.checkDeadline != null && DateTime.now().isAfter(message.checkDeadline!);

    Widget buildHeader() {
      return Row(
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '送信相手: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
                TextSpan(text: '$total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                const TextSpan(text: '人', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 16,
            color: Colors.grey[300],
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '既読:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF858585))),
                    TextSpan(text: '$readCount', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF858585))),
                    const TextSpan(text: '人', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF858585))),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 4),
              if (readCount == total)
                SvgPicture.asset('assets/images/Checkmark Circle.svg', width: 15, height: 15)
              else
                Icon(Icons.check_circle_outline, color: const Color(0xFF1AD84C), size: 16),
            ],
          ),
          const SizedBox(width: 16),
          if (message.isCheckRequired) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'チェック: ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF858585))),
                      TextSpan(text: '$checkCount', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFFF3232))),
                      const TextSpan(text: '人', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFFF3232))),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 4),
                // 完了時のみバッジ表示、遅延中も表示、期限前の未完了は非表示
                if (checkCount == total)
                  SvgPicture.asset('assets/images/Checkmark Circle.svg', width: 15, height: 15)
                else if (isLate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3232),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '遅延中',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                // 期限前の未完了は何も表示しない
              ],
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        buildHeader(),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: message.receiverIds.length,
          separatorBuilder: (_, __) => const Divider(height: 32),
          itemBuilder: (context, index) {
            final workerId = message.receiverIds[index];
            final name = workerMap[workerId] ?? 'Unknown';
            final action = actions.where((a) => a.actorId == workerId).firstOrNull;
            
            final readTime = message.readTimeMap[workerId];
            final announceTime = message.announcedTimeMap[workerId];
            
            final isLate = message.checkDeadline != null && 
                           (action == null || action.metadata.firstInteractionTime!.isAfter(message.checkDeadline!));
            final hasChecked = action?.actionTypes.contains('check') ?? false;
            final hasImage = action?.actionTypes.contains('image') ?? false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.account_circle, size: 32),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (readTime != null)
                                Text('既読: ${DateFormat('M/d HH:mm').format(readTime)}', style: const TextStyle(fontSize: 10, color: Color(0xFF858585))),
                              if (announceTime != null)
                                Text('アナウンス: ${DateFormat('M/d HH:mm').format(announceTime)}', style: const TextStyle(fontSize: 10, color: Color(0xFF858585))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (message.senderId == myId)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Color(0xFFFF3232), size: 18),
                        onPressed: () {
                          ref.read(messageControllerProvider.notifier).deleteUserFromReceiverList(message.id, workerId);
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                
                if (hasChecked || isLate)
                  Padding(
                    padding: const EdgeInsets.only(left: 0, top: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: hasChecked ? const Color(0xFFFE8700) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: hasChecked ? null : Border.all(color: const Color(0xFF858585)),
                          ),
                          child: Icon(Icons.check, size: 12, color: hasChecked ? Colors.white : const Color(0xFF858585)),
                        ),
                        const SizedBox(width: 8),

                        if (action != null)
                          Text(
                             DateFormat('M/d HH:mm').format(action.metadata.firstInteractionTime!),
                             style: TextStyle(
                               fontSize: (isLate && hasChecked) ? 9 : 13,
                               color: (isLate && hasChecked) ? const Color(0xFFFF3232) : (hasChecked ? const Color(0xFFFE8700) : Colors.black),
                               fontWeight: (isLate && hasChecked) ? FontWeight.w600 : FontWeight.bold,
                             )
                          ),
                        if (!hasChecked)
                          const Text('未チェック', style: TextStyle(color: Color(0xFFFF3232), fontSize: 12, fontWeight: FontWeight.bold)),
                        if (isLate && hasChecked)
                           const Text(' 遅れ', style: TextStyle(color: Color(0xFFFF3232), fontSize: 9, fontWeight: FontWeight.w600)),

                        const SizedBox(width: 8),

                        if (message.isCheckShared && hasChecked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFFE8700), borderRadius: BorderRadius.circular(10)),
                            child: const Text('共有', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),

                        const Spacer(),

                        if (hasImage) ...[
                          const Icon(Icons.camera_alt, color: Color(0xFFFE8700), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('M/d HH:mm').format(action!.metadata.firstInteractionTime!),
                            style: const TextStyle(color: Color(0xFFFE8700), fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),

                if (action?.replyFromReceiver != null && action!.replyFromReceiver!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            action.replyFromReceiver!,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}