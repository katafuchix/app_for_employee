import 'dart:io'; // 追加: File型を使用するため
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                            
                            const Divider(height: 1),

                            // --- Scrollable Content ---
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Message Content Section
                                    _buildMessageContent(message),
                                    
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
                ElevatedButton.icon(
                  onPressed: () => _confirmDelete(context, message),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('削除', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                    const Text('From:', style: TextStyle(fontSize: 10, color: Color(0xFF858585))),
                    const SizedBox(height: 4),
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
              const Expanded(
                flex: 1,
                child: Center(
                  child: Icon(Icons.arrow_forward, size: 20, color: Color(0xFF858585)),
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To:', style: TextStyle(fontSize: 10, color: Color(0xFF858585))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.account_circle, size: 36),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black),
                              children: [
                                TextSpan(text: '$firstReceiverName ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                if (receiverCount > 1)
                                  TextSpan(text: '他${receiverCount - 1}人', style: const TextStyle(fontSize: 11, color: Color(0xFF858585))),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
              Text(
                '作成日: ${DateFormat('M月d日 HH:mm').format(message.metadata.firstInteractionTime!)}',
                style: const TextStyle(color: Color(0xFF858585), fontSize: 11),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'スケジュール: ',
                      style: TextStyle(color: Color(0xFF858585), fontSize: 11),
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

  // 経過時間をフォーマットするヘルパーメソッド
  String _formatOverdue(DateTime deadline) {
    final diff = DateTime.now().difference(deadline);
    if (diff.inDays > 0) return '${diff.inDays}日遅れ';
    if (diff.inHours > 0) return '${diff.inHours}時間遅れ';
    return '${diff.inMinutes}分遅れ';
  }

  Widget _buildMessageContent(Message message) {
    final isLate = message.checkDeadline != null && DateTime.now().isAfter(message.checkDeadline!);
    final deadlineText = message.checkDeadline != null
        ? '${DateFormat('M/d HH:mm').format(message.checkDeadline!)}まで'
        : '';

    return Column(
      children: [
        Text(
          message.content,
          style: const TextStyle(fontSize: 16, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (message.isCheckRequired) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFE8700),
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
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deadlineText,
                        style: TextStyle(
                          color: isLate ? const Color(0xFFFF3232) : const Color(0xFFFE8700),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (isLate && message.checkDeadline != null)
                        Text(
                          _formatOverdue(message.checkDeadline!),
                          style: const TextStyle(
                            color: Color(0xFFFE8700),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
            if (message.isOperationAnnouncementRequired) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF858585),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volume_up, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
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
          TextField(
            controller: _replyController,
            enabled: !isAlreadyDone && !isLocked, // ロック時は無効
            decoration: InputDecoration(
              hintText: isAlreadyDone 
                  ? (myAction.replyFromReceiver?.isNotEmpty == true ? myAction.replyFromReceiver : '返信なし')
                  : (isLocked ? '指定日時まで返信できません' : '返信を入力'),
              filled: true,
              fillColor: (isAlreadyDone || isLocked) ? Colors.grey[100] : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Area
              Expanded(
                flex: message.isCheckRequired ? 3 : 1,
                child: GestureDetector(
                  onTap: (isAlreadyDone || isLocked)
                      ? null
                      : () => _showImageSourceActionSheet(),
                  child: Container(
                    height: 90,
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
                                    Text('画像提出済み', style: TextStyle(fontSize: 10))
                                  ]
                                )
                              : _imageFile != null
                                  ? const SizedBox.shrink()
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt, color: isLocked ? Colors.grey[300] : Colors.grey, size: 28),
                                        const SizedBox(height: 4),
                                        Text(
                                          isLocked
                                              ? '待機中'
                                              : (isImageRequired ? '画像の提出が\n求められています': '画像を添付 (任意)'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 10, color: isLocked ? Colors.grey[400] : Colors.grey[600]),
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
              ),

              // Checkbox Area
              if (message.isCheckRequired) ...[
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text('チェックを付ける', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isLocked ? Colors.grey : const Color(0xFFFE8700))),
                      const SizedBox(height: 4),
                      Transform.scale(
                        scale: 1.5,
                        child: Checkbox(
                          value: isAlreadyDone ? myAction.actionTypes.contains('check') : _isChecked,
                          onChanged: (isAlreadyDone || isLocked) ? null : (v) => setState(() => _isChecked = v ?? false),
                          activeColor: const Color(0xFFFE8700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      if (isLate && !isAlreadyDone)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning, size: 14, color: Color(0xFFFF3232)),
                            SizedBox(width: 2),
                            Text('期限超過', style: TextStyle(color: Color(0xFFFF3232), fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: (isAlreadyDone || !isValid || isLocked) ? null : () => _submitAction(message),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAlreadyDone
                    ? const Color(0xFF858585)
                    : (isValid && !isLocked ? const Color(0xFF0084FF) : Colors.grey[300]),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                isAlreadyDone ? '完了済み' : (isLocked ? 'スケジュール待機中' : '完了'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
          Text('送信相手: $total人', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          Row(
            children: [
              Text('既読: $readCount人', style: const TextStyle(fontSize: 12, color: Color(0xFF858585))),
              const SizedBox(width: 4),
              Icon(readCount == total ? Icons.check_circle : Icons.check_circle_outline, color: const Color(0xFF1AD84C), size: 16),
            ],
          ),
          const SizedBox(width: 12),
          if (message.isCheckRequired) ...[
            Text('チェック: $checkCount人', style: const TextStyle(fontSize: 12, color: Color(0xFF858585))),
            const SizedBox(width: 4),
            // 完了時は緑バッジ、遅延中は赤バッジ、期限前は表示なし
            if (checkCount == total)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1AD84C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '完了',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            else if (isLate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3232),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '遅延中',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            // 期限前で未完了の場合はバッジを表示しない
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
                             style: TextStyle(fontSize: 12, color: hasChecked ? const Color(0xFFFE8700) : Colors.black, fontWeight: FontWeight.bold)
                          ),
                        if (!hasChecked)
                          const Text('未チェック', style: TextStyle(color: Color(0xFFFF3232), fontSize: 12, fontWeight: FontWeight.bold)),
                        if (isLate && hasChecked)
                           const Text(' 遅れ', style: TextStyle(color: Color(0xFFFF3232), fontSize: 12, fontWeight: FontWeight.bold)),

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
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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