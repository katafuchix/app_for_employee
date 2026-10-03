import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_version_model.dart';

class AppVersionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<AppVersionModel?> watchOwnerAppVersion() {
    return _firestore
        .collection('console')
        .doc('worker_app')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return null;
          }
          return AppVersionModel.fromMap(snapshot.data()!);
        });
  }
}