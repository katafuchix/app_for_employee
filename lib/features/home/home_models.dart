// lib/home_models.dart

class HomeWorkerProfile {
  final String uid;
  final String? authId;
  final String? storeId;
  final String? storeWorkerId;
  final String displayName;
  final String? photoUrl;

  HomeWorkerProfile({
    required this.uid,
    this.authId,
    this.storeId,
    this.storeWorkerId,
    required this.displayName,
    this.photoUrl,
  });

  /// 未登録時などの初期状態用ファクトリ
  factory HomeWorkerProfile.empty() {
    return HomeWorkerProfile(uid: '', displayName: '名前未登録');
  }
}
