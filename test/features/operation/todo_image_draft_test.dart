import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tebanashi/features/operation/controllers/todo_action_controller.dart';

void main() {
  test('keeps drafts isolated by store, base date, and mapping', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(todoImageDraftProvider.notifier);
    final baseDate = DateTime(2026, 4, 21, 9);
    final sameMappingInStoreA = TodoImageDraftScope(
      storeId: 'store_a',
      baseDate: baseDate,
      mappingId: 'mapping_1',
    );
    final sameMappingInStoreB = TodoImageDraftScope(
      storeId: 'store_b',
      baseDate: baseDate,
      mappingId: 'mapping_1',
    );
    final sameMappingOnNextDay = TodoImageDraftScope(
      storeId: 'store_a',
      baseDate: baseDate.add(const Duration(days: 1)),
      mappingId: 'mapping_1',
    );
    final firstFile = File('/tmp/store_a_today.jpg');
    final secondFile = File('/tmp/store_b_today.jpg');
    final thirdFile = File('/tmp/store_a_tomorrow.jpg');

    notifier.saveDraft(
      scope: sameMappingInStoreA,
      submissionId: 'quality_1',
      file: firstFile,
    );
    notifier.saveDraft(
      scope: sameMappingInStoreB,
      submissionId: 'quality_1',
      file: secondFile,
    );
    notifier.saveDraft(
      scope: sameMappingOnNextDay,
      submissionId: 'quality_1',
      file: thirdFile,
    );

    final drafts = container.read(todoImageDraftProvider);
    expect(drafts[sameMappingInStoreA.key]?['quality_1'], firstFile);
    expect(drafts[sameMappingInStoreB.key]?['quality_1'], secondFile);
    expect(drafts[sameMappingOnNextDay.key]?['quality_1'], thirdFile);
    expect(drafts, hasLength(3));
  });

  test('removes and clears only drafts in the requested scope', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(todoImageDraftProvider.notifier);
    final baseDate = DateTime(2026, 4, 21, 9);
    final firstScope = TodoImageDraftScope(
      storeId: 'store_a',
      baseDate: baseDate,
      mappingId: 'mapping_1',
    );
    final secondScope = TodoImageDraftScope(
      storeId: 'store_a',
      baseDate: baseDate,
      mappingId: 'mapping_2',
    );

    notifier.saveDraft(
      scope: firstScope,
      submissionId: 'quality_1',
      file: File('/tmp/quality.jpg'),
    );
    notifier.saveDraft(
      scope: firstScope,
      submissionId: 'service_1',
      file: File('/tmp/service.jpg'),
    );
    notifier.saveDraft(
      scope: secondScope,
      submissionId: 'quality_1',
      file: File('/tmp/other.jpg'),
    );

    notifier.removeDraft(scope: firstScope, submissionId: 'quality_1');

    var drafts = container.read(todoImageDraftProvider);
    expect(drafts[firstScope.key]?.keys, ['service_1']);
    expect(drafts[secondScope.key]?.keys, ['quality_1']);

    notifier.clearDrafts(firstScope);

    drafts = container.read(todoImageDraftProvider);
    expect(drafts, isNot(contains(firstScope.key)));
    expect(drafts, contains(secondScope.key));
  });
}
