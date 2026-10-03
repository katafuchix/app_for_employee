import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_version_repository.dart';
import 'app_version_model.dart';

// アプリ内の現在のバージョン（リリース時にここを更新します）
const String currentOwnerAppVersion = '1.1';

final appVersionRepositoryProvider = Provider((ref) => AppVersionRepository());

final ownerAppVersionStreamProvider = StreamProvider<AppVersionModel?>((ref) {
  final repository = ref.watch(appVersionRepositoryProvider);
  return repository.watchOwnerAppVersion();
});