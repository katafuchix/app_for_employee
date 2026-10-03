import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Todo2Docなどが定義されているファイルをインポート
import '../manual/manual_controller.dart';
import 'todo_models.dart';
// マニュアル一覧取得用（パスはプロジェクト構成に合わせて調整してください）
import '../../features/manual/manual_page.dart';

class TodoDetailViewerModal extends ConsumerWidget {
  const TodoDetailViewerModal({
    super.key,
    required this.row,
    required this.storeId,
    required this.positionTitle,
  });

  final TodoRowVM row;
  final String storeId;
  final String positionTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = row.todo;
    final index = row.displayIndex;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            // === ヘッダー ===
            _buildHeader(context, todo),

            // === コンテンツ ===
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル・基本情報
                    _buildTitleSection(todo, index),
                    const SizedBox(height: 24),

                    // マニュアル
                    _buildManualSection(context, ref, todo),

                    // チェックリスト (今回追加)
                    if (todo.checklistItems.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildChecklistSection(todo),
                    ],
                  ],
                ),
              ),
            ),

            // === 閉じるボタン ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.grey[700],
                ),
                child: const Text(
                  '閉じる',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ヘッダーとタイトル部分は変更なし（省略または前回のコードを使用）
  Widget _buildHeader(BuildContext context, Todo2Doc todo) {
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
                  border: Border.all(color: Colors.black54),
                ),
                child: Text(
                  positionTitle,
                  style: const TextStyle(
                    color: Colors.black87,
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

  Widget _buildTitleSection(Todo2Doc todo, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '確認モード',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$index. ${todo.title}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (todo.useDetail && todo.detail.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(todo.detail, style: const TextStyle(color: Colors.black87)),
        ],
        const SizedBox(height: 8),
        Text(
          '${todo.durationMinute}分',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // マニュアル表示部分（前回と同じロジック）
  Widget _buildManualSection(
    BuildContext context,
    WidgetRef ref,
    Todo2Doc todo,
  ) {
    if (todo.manualIds.isEmpty) return const SizedBox.shrink();

    final manualListAsync = ref.watch(manualListProvider(storeId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'マニュアル',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF4081),
          ),
        ),
        const SizedBox(height: 8),
        manualListAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (manuals) {
            final targetManuals = manuals
                .where((m) => todo.manualIds.contains(m.manualId))
                .toList();
            if (targetManuals.isEmpty) {
              return const Text(
                'マニュアルが見つかりません',
                style: TextStyle(color: Colors.grey),
              );
            }
            return Column(
              children: targetManuals.map((manual) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ManualDetailPage(
                            storeId: storeId,
                            manual: manual,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4081),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.menu_book,
                            color: Colors.white,
                            size: 18,
                          ),
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
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ★今回追加: チェックリスト表示用ウィジェット
  Widget _buildChecklistSection(Todo2Doc todo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'チェックリスト',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF4081), // マニュアルの見出し色と統一（または任意のテーマ色）
          ),
        ),
        const SizedBox(height: 8),

        // リスト項目を展開
        // Todo2DocのchecklistItemsはChecklistItemのリストと想定
        // ChecklistItemは { String content } を持っている前提
        ...todo.checklistItems.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 未チェック状態のアイコンを表示（閲覧モードなので操作不可であることを示す）
                const Icon(
                  Icons.check_box_outline_blank,
                  size: 22,
                  color: Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.content, // 内容を表示
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
