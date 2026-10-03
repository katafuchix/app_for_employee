import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo_model.dart';
import '../providers/operation_todo_provider.dart';

class TodoImageButton extends ConsumerWidget {
  final String storeId;
  final String executionId;
  final List<String> submissionImageIds;
  final List<ImageSubmissionInfo> imageSubmissionInfos;

  const TodoImageButton({
    super.key,
    required this.storeId,
    required this.executionId,
    required this.submissionImageIds,
    required this.imageSubmissionInfos,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.image, color: Colors.blue),
      onPressed: submissionImageIds.isEmpty
          ? null
          : () {
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 420,
                        maxHeight: 560,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '提出画像',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.separated(
                              itemCount: submissionImageIds.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, index) {
                                final submissionId = submissionImageIds[index];
                                final info = imageSubmissionInfos
                                    .firstWhereOrNull(
                                      (element) => element.id == submissionId,
                                    );
                                return _TodoImagePreviewTile(
                                  storeId: storeId,
                                  executionId: executionId,
                                  submissionId: submissionId,
                                  title: info?.title ?? 'その他',
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('閉じる'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
    );
  }
}

class _TodoImagePreviewTile extends ConsumerWidget {
  final String storeId;
  final String executionId;
  final String submissionId;
  final String title;

  const _TodoImagePreviewTile({
    required this.storeId,
    required this.executionId,
    required this.submissionId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(
      todoExecutionImageUrlProvider(
        storeId: storeId,
        executionId: executionId,
        submissionImageId: submissionId,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColoredBox(
              color: Colors.grey.shade100,
              child: urlAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
                data: (url) {
                  if (url == null || url.isEmpty) {
                    return const Center(
                      child: Icon(Icons.image_not_supported_outlined),
                    );
                  }
                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.broken_image_outlined)),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
