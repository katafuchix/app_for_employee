import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'home_models.dart';

class HomeRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String _storageBucket = 'gs://app-5-5b64a.firebasestorage.app';

  HomeRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// 現在のユーザー情報を取得してプロフィールモデルを返す
  Future<HomeWorkerProfile> fetchCurrentWorkerProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('未ログインです。');
    }

    final uid = user.uid;

    final workerMapDoc = await _firestore
        .collection('worker_id_map')
        .doc(uid)
        .get();

    if (!workerMapDoc.exists) {
      throw Exception('worker_id_map にデータがありません。');
    }

    final mapData = workerMapDoc.data() ?? {};
    final authId = mapData['auth_id'] as String?;
    final storeId = mapData['store_id'] as String?;
    final storeWorkerId = mapData['store_worker_id'] as String?;

    if (storeId == null || storeWorkerId == null) {
      throw Exception('store_id または store_worker_id が未設定です。');
    }

    final workerDoc = await _firestore
        .collection('store_data')
        .doc(storeId)
        .collection('worker')
        .doc(storeWorkerId)
        .get();

    if (!workerDoc.exists) {
      throw Exception('該当のワーカー情報が見つかりません。');
    }

    final workerData = workerDoc.data() ?? {};

    final nameInfo = workerData['name_info'];
    String? familyName;
    String? givenName;

    if (nameInfo is List && nameInfo.isNotEmpty) {
      final first = nameInfo.first;
      if (first is Map<String, dynamic>) {
        familyName = first['family_name'] as String?;
        givenName = first['given_name'] as String?;
      }
    } else if (nameInfo is Map<String, dynamic>) {
      familyName = nameInfo['family_name'] as String?;
      givenName = nameInfo['given_name'] as String?;
    }

    final fullName = [
      if (familyName != null && familyName.isNotEmpty) familyName,
      if (givenName != null && givenName.isNotEmpty) givenName,
    ].join(' ');

    final displayName = fullName.isNotEmpty ? fullName : '名前未登録';

    String? photoUrl;
    try {
      final storage = FirebaseStorage.instanceFor(bucket: _storageBucket);
      final ref = storage.ref().child(
        'store_data/$storeId/worker/$storeWorkerId',
      );
      photoUrl = await ref.getDownloadURL();
    } catch (_) {
      photoUrl = null;
    }

    return HomeWorkerProfile(
      uid: uid,
      authId: authId,
      storeId: storeId,
      storeWorkerId: storeWorkerId,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    await _firestore.collection('worker_id_map').doc(uid).delete();
    final querySnapshot = await _firestore
        .collection('worker')
        .where('auth_id', isEqualTo: uid)
        .get();
    for (final doc in querySnapshot.docs) {
      await doc.reference.update({'auth_id': FieldValue.delete()});
    }
    await user.delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamOperationStatus(
    String storeId,
  ) {
    return _firestore
        .collection('store_data')
        .doc(storeId)
        .collection('daily_setup2')
        .where('is_operating', isEqualTo: true)
        .orderBy('base_date.date', descending: false)
        .snapshots();
  }
}
