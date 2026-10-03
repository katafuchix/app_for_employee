// manual_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'manual_models.dart';
import 'manual_controller.dart';

class ManualPage extends ConsumerWidget {
  const ManualPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. ストアIDを取得
    final storeIdAsync = ref.watch(manualStoreIdProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: storeIdAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => _ErrorView(
            message: err.toString().replaceFirst('Exception: ', ''),
            onRetry: () async => ref.invalidate(manualStoreIdProvider),
          ),
          data: (storeId) {
            // 2. カテゴリー構造化データを取得
            final categoryListAsync = ref.watch(
              manualCategoryListProvider(storeId),
            );

            return categoryListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _ErrorView(
                message: err.toString().replaceFirst('Exception: ', ''),
                onRetry: () async =>
                    ref.invalidate(manualCategoryListProvider(storeId)),
              ),
              data: (categories) {
                // マニュアル総数を計算（ヘッダー表示用）
                final totalManuals = categories.fold<int>(0, (sum, cat) {
                  final folderCount = cat.folders.fold<int>(
                    0,
                    (s, f) => s + f.manuals.length,
                  );
                  return sum + folderCount + cat.uncategorizedManuals.length;
                });

                if (categories.isEmpty) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _ManualHeader(
                          createdCount: 0,
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'カテゴリー・マニュアルがありません',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return DefaultTabController(
                  length: categories.length,
                  child: Column(
                    children: [
                      // ヘッダー部
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _ManualHeader(
                          createdCount: totalManuals,
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                      ),

                      // タブバー (カテゴリー名)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.black45,
                          indicatorColor: AppColors.blue,
                          indicatorWeight: 3,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          tabs: categories
                              .map((c) => Tab(text: c.category.title))
                              .toList(),
                          dividerColor: Colors.grey.shade200,
                        ),
                      ),

                      // タブの中身
                      Expanded(
                        child: TabBarView(
                          children: categories.map((c) {
                            return _CategoryView(
                              storeId: storeId,
                              content: c,
                              onRefresh: () async {
                                return ref.refresh(
                                  manualCategoryListProvider(storeId).future,
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CategoryView extends StatelessWidget {
  final String storeId;
  final CategoryWithContent content;
  final Future<void> Function() onRefresh;

  const _CategoryView({
    required this.storeId,
    required this.content,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (content.folders.isEmpty && content.uncategorizedManuals.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            Center(
              child: Text(
                'このカテゴリーにはマニュアルがありません',
                style: TextStyle(color: Colors.black45),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 62),
        children: [
          // フォルダごとのセクション
          for (final folderContent in content.folders) ...[
            _FolderSection(storeId: storeId, folderContent: folderContent),
            const SizedBox(height: 24),
          ],

          // フォルダに属さないマニュアル (もしあれば)
          if (content.uncategorizedManuals.isNotEmpty) ...[
            if (content.folders.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'その他',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            for (final manual in content.uncategorizedManuals) ...[
              _ManualRow(
                item: manual,
                onTap: () => _goToDetail(context, storeId, manual),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  void _goToDetail(BuildContext context, String storeId, Manual manual) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManualDetailPage(storeId: storeId, manual: manual),
      ),
    );
  }
}

class _FolderSection extends StatelessWidget {
  final String storeId;
  final FolderWithContent folderContent;

  const _FolderSection({required this.storeId, required this.folderContent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // フォルダヘッダー (PDF仕様: 青色系)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2FF), // 薄い青
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
          ),
          child: Text(
            folderContent.folder.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.blue,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // マニュアルリスト
        if (folderContent.manuals.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text(
              'マニュアルなし',
              style: TextStyle(color: Colors.black38, fontSize: 12),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // 親のListViewでスクロールさせる
            itemCount: folderContent.manuals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final manual = folderContent.manuals[index];
              return _ManualRow(
                item: manual,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ManualDetailPage(storeId: storeId, manual: manual),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 以下、既存コンポーネント (変更なし、または微調整)
// -----------------------------------------------------------------------------

class ManualDetailPage extends ConsumerWidget {
  final String storeId;
  final Manual manual;

  const ManualDetailPage({
    super.key,
    required this.storeId,
    required this.manual,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleText = manual.title.trim().isEmpty
        ? '（タイトルなし）'
        : manual.title.trim();

    const titleStyle = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w900,
      color: Colors.black,
      height: 1.1,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 48.0),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            children: [
              _ManualTopBar(
                manualNo: manual.manualNo,
                createdDate: manual.createdDate,
                updatedDate: manual.updatedDate,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 10),
              Text(titleText, style: titleStyle),
              const SizedBox(height: 6),
              _DottedUnderline(text: titleText, style: titleStyle),
              const SizedBox(height: 14),
              for (final step in manual.steps) ...[
                _StepCard(
                  step: step,
                  storeId: storeId,
                  manualId: manual.manualId,
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final StepItem step;
  final String storeId;
  final String manualId;

  const _StepCard({
    required this.step,
    required this.storeId,
    required this.manualId,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = step.title.trim();
    final contentText = step.content.trim();

    final showTitle = step.useTitle && titleText.isNotEmpty;
    final showUrl = step.useUrl && step.url.trim().isNotEmpty;
    final showImages = step.imageIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 18.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 7,
              spreadRadius: 3,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'ステップ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.blue,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.blue,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: Text(
                          '${step.stepNo}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (showTitle)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    titleText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                ),
              if (showTitle) const SizedBox(height: 8),
              if (contentText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    contentText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),
              if (showUrl) const SizedBox(height: 10),
              if (showUrl)
                SizedBox(
                  width: double.infinity,
                  child: Center(child: _UrlPill(url: step.url.trim())),
                ),
              if (showImages) const SizedBox(height: 12),
              if (showImages)
                const Text(
                  '画像',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    height: 1.0,
                  ),
                ),
              if (showImages) const SizedBox(height: 8),
              if (showImages)
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: step.imageIds.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final imageId = step.imageIds[i];
                      return _Thumb(
                        indexNo: i + 1,
                        storeId: storeId,
                        manualId: manualId,
                        imageId: imageId,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends ConsumerWidget {
  final int indexNo;
  final String storeId;
  final String manualId;
  final String imageId;

  const _Thumb({
    required this.indexNo,
    required this.storeId,
    required this.manualId,
    required this.imageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double s = 84;
    const double numW = 12;
    const double gap = 2;

    final imageAsync = ref.watch(
      manualImageUrlProvider(
        storeId: storeId,
        manualId: manualId,
        imageId: imageId,
      ),
    );

    return SizedBox(
      width: numW + gap + s,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: numW,
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                '$indexNo',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: gap),
          GestureDetector(
            onTap: () {
              showDialog<void>(
                context: context,
                barrierDismissible: true,
                barrierColor: Colors.black87,
                builder: (_) => _ImagePreviewDialog(
                  storeId: storeId,
                  manualId: manualId,
                  imageId: imageId,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox.square(
                dimension: s,
                child: Container(
                  color: const Color(0xFFF2F2F2),
                  child: imageAsync.when(
                    data: (url) {
                      if (url.isEmpty) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 20,
                            color: Colors.black26,
                          ),
                        );
                      }
                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 20,
                            color: Colors.black26,
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 20,
                        color: Colors.black26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreviewDialog extends ConsumerWidget {
  final String storeId;
  final String manualId;
  final String imageId;

  const _ImagePreviewDialog({
    required this.storeId,
    required this.manualId,
    required this.imageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAsync = ref.watch(
      manualImageUrlProvider(
        storeId: storeId,
        manualId: manualId,
        imageId: imageId,
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 900),
            child: imageAsync.when(
              loading: () => const SizedBox(
                width: 60,
                height: 60,
                child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
              ),
              error: (_, __) => const Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Colors.white70,
              ),
              data: (url) {
                if (url.isEmpty) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: Colors.white70,
                  );
                }
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualTopBar extends StatelessWidget {
  final int manualNo;
  final String createdDate;
  final String updatedDate;
  final VoidCallback? onBack;

  const _ManualTopBar({
    required this.manualNo,
    required this.createdDate,
    required this.updatedDate,
    required this.onBack,
  });

  static const double _h = 44.0;
  static const StrutStyle _strutDate = StrutStyle(
    fontSize: 11,
    height: 1.0,
    forceStrutHeight: true,
  );
  static const TextHeightBehavior _thb = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  @override
  Widget build(BuildContext context) {
    final c = createdDate.trim().isEmpty ? '—' : createdDate.trim();
    final u = updatedDate.trim().isEmpty ? '—' : updatedDate.trim();

    return SizedBox(
      height: _h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -8,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: Colors.black,
                ),
                splashRadius: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ),
          Positioned(
            left: 34,
            top: 4,
            child: _ManualNoPill(manualNo: manualNo),
          ),
          Positioned(
            right: 0,
            top: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '作成: $c',
                    textHeightBehavior: _thb,
                    strutStyle: _strutDate,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '最終編集: $u',
                  textHeightBehavior: _thb,
                  strutStyle: _strutDate,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black45,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualNoPill extends StatelessWidget {
  final int manualNo;
  const _ManualNoPill({required this.manualNo});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFF2FB3),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Padding(
        padding: EdgeInsets.only(top: 3.0),
        child: _ManualNoPillText(),
      ),
    );
  }
}

class _ManualNoPillText extends StatelessWidget {
  const _ManualNoPillText();
  @override
  Widget build(BuildContext context) {
    final p = context.findAncestorWidgetOfExactType<_ManualNoPill>();
    final manualNo = (p == null) ? 0 : p.manualNo;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'マニュアル  ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const TextSpan(
            text: 'No.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          TextSpan(
            text: '$manualNo',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedUnderline extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _DottedUnderline({required this.text, required this.style});
  static const double _lineHeight = 2.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: c.maxWidth);
        return SizedBox(
          width: tp.width,
          height: _lineHeight,
          child: CustomPaint(painter: _DottedLinePainter()),
        );
      },
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2B2B2B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashW = 3.0;
    const dashGap = 3.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashW, y), paint);
      x += dashW + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UrlPill extends StatelessWidget {
  final String url;
  const _UrlPill({required this.url});
  @override
  Widget build(BuildContext context) {
    final text = url.length > 36 ? '${url.substring(0, 36)}…' : url;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link, size: 16, color: Color(0xFF2F80ED)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2F80ED),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualHeader extends StatelessWidget {
  final int createdCount;
  final VoidCallback? onBack;

  const _ManualHeader({required this.createdCount, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 24,
                color: Colors.black,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 24,
            ),
            const SizedBox(width: 8),
            // ロゴ (Assetsが必要ですが既存コードに合わせています)
            Image.asset(
              'assets/images/LOGOM.png',
              width: 22,
              height: 22,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
            const SizedBox(width: 6),
            const Text(
              'マニュアル管理',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              '店舗のマニュアルを確認しましょう',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                height: 1.0,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  '作成数: ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '$createdCount',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ManualRow extends StatelessWidget {
  final Manual item;
  final VoidCallback? onTap;

  const _ManualRow({required this.item, this.onTap});

  static const double _cardHeight = 48.0;
  static const StrutStyle _strut11 = StrutStyle(
    fontSize: 11,
    height: 1.0,
    forceStrutHeight: true,
  );
  static const StrutStyle _strut10 = StrutStyle(
    fontSize: 10,
    height: 1.0,
    forceStrutHeight: true,
  );
  static const List<FontFeature> _tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];
  static const TextHeightBehavior _thb = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  @override
  Widget build(BuildContext context) {
    final titleText = item.title.trim().isEmpty
        ? '（タイトルなし）'
        : item.title.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: _cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 6,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
              const BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                spreadRadius: -2,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6, top: 2),
                          child: Text(
                            '${item.index + 1}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppColors.pink,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 2,
                      height: 19,
                      decoration: BoxDecoration(
                        color: const Color(0x22000000),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          titleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  textHeightBehavior: _thb,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      color: Colors.black45,
                    ).copyWith(fontFeatures: _tabularFigures),
                    children: [
                      TextSpan(
                        text: '${item.stepCount}ステップ',
                        style: const TextStyle(
                          color: AppColors.blue,
                        ).copyWith(fontFeatures: _tabularFigures),
                      ),
                      const TextSpan(text: '・'),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.only(left: 2, right: 3),
                          child: Icon(
                            Icons.photo_camera_outlined,
                            size: 14,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: '${item.imageTotal}枚',
                        style: const TextStyle(
                          color: AppColors.blue,
                        ).copyWith(fontFeatures: _tabularFigures),
                      ),
                      const TextSpan(text: '・'),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.only(left: 2, right: 3),
                          child: Icon(
                            Icons.remove_red_eye_outlined,
                            size: 14,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: '${item.viewCount}回',
                        style: const TextStyle(
                          color: AppColors.blue,
                        ).copyWith(fontFeatures: _tabularFigures),
                      ),
                      if (item.isAuto)
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: _AutoBadge(),
                          ),
                        ),
                    ],
                  ),
                  strutStyle: _strut11,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '作成: ${item.createdDate}・最終編集: ${item.updatedDate}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.black45,
                  height: 1.0,
                ).copyWith(fontFeatures: _tabularFigures),
                strutStyle: _strut10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _AutoBadge extends StatelessWidget {
  const _AutoBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2F80ED),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Auto',
        strutStyle: StrutStyle(
          fontSize: 10,
          height: 1.0,
          forceStrutHeight: true,
        ),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => onRetry(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '再読み込み',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
