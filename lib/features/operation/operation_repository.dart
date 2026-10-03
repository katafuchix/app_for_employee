import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/daily_sales_model.dart';
import 'models/daily_setup_model.dart';
import 'models/task_execution_model.dart';
import 'models/todo_mode_model.dart';
import 'models/todo_mapping_model.dart';
import 'models/todo_model.dart';
import 'models/todo_execution_model.dart';
import 'models/worker_clock_model.dart';
import 'models/worker_model.dart';
import 'models/task_models.dart';

final operationRepositoryProvider = Provider((ref) => OperationRepository());

class OperationRepository {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  Future<String> fetchCurrentStoreWorkerId() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('未ログインです');

    final workerMapDoc = await _db
        .collection('worker_id_map')
        .doc(user.uid)
        .get();

    if (!workerMapDoc.exists) {
      throw Exception('worker_id_map にデータがありません');
    }

    final storeWorkerId = workerMapDoc.data()?['store_worker_id'] as String?;
    if (storeWorkerId == null) {
      throw Exception('store_worker_id が未設定です');
    }

    return storeWorkerId;
  }

  // ==========================================
  // 1. 静的データ（マスタ）の一括取得用メソッド
  // ==========================================

  Future<int> fetchStoreIndividualCapacity(String storeId) async {
    final doc = await _db.collection('store_data').doc(storeId).get();

    if (!doc.exists || doc.data() == null) {
      return 12000; // デフォルト値
    }

    final data = doc.data()!;
    return (data['individual_capacity'] as num?)?.toInt() ?? 12000;
  }

  /// DailySetupの取得
  Future<DailySetup?> fetchDailySetup(String storeId, DateTime date) async {
    final targetDate = DateTime(date.year, date.month, date.day);
    final targetTimestamp = Timestamp.fromDate(targetDate);

    final snapshot = await _db
        .collection('store_data')
        .doc(storeId)
        .collection('daily_setup2')
        .where('base_date.date', isEqualTo: targetTimestamp)
        .where('is_operating', isEqualTo: true)
        .orderBy('base_date.date', descending: false)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return DailySetup.fromMap(
      snapshot.docs.first.data(),
      snapshot.docs.first.id,
    );
  }

  /// TodoModeの取得
  Future<TodoMode?> fetchTodoMode(String storeId, String todoModeId) async {
    final doc = await _db
        .collection('store_data')
        .doc(storeId)
        .collection('todo_mode')
        .doc(todoModeId)
        .get();

    if (!doc.exists || doc.data() == null) return null;

    return TodoMode.fromMap(doc.data()!, doc.id);
  }

  /// TodoMappingの取得
  Future<List<TodoMapping>> fetchTodoMappings(
    String storeId,
    String todoModeId,
    DateTime openTime,
    DateTime closeTime,
  ) async {
    final snapshot = await _db
        .collection('store_data')
        .doc(storeId)
        .collection('todo_mapping')
        .where('mode_id', isEqualTo: todoModeId)
        .where(
          'metadata.first_interaction_time.date',
          isLessThanOrEqualTo: Timestamp.fromDate(openTime),
        )
        .where(
          'metadata.deleted_time.date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(closeTime),
        )
        .orderBy('index', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => TodoMapping.fromMap(doc.data(), doc.id))
        .whereType<TodoMapping>()
        .toList();
  }

  /// Todoマスタ (Todo) の取得
  Future<List<Todo>> fetchTodos(String storeId, List<String> todoIds) async {
    if (todoIds.isEmpty) return [];
    final uniqueIds = todoIds.toSet().toList();

    final collectionRef = _db
        .collection('store_data')
        .doc(storeId)
        .collection('todo2');

    List<List<String>> chunks = [];
    const int chunkSize = 30;
    for (var i = 0; i < uniqueIds.length; i += chunkSize) {
      chunks.add(
        uniqueIds.sublist(
          i,
          (i + chunkSize > uniqueIds.length) ? uniqueIds.length : i + chunkSize,
        ),
      );
    }

    final snapshots = await Future.wait(
      chunks.map((chunk) {
        return collectionRef
            .where('metadata.is_deleted', isEqualTo: false)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
      }),
    );

    return snapshots
        .expand((querySnapshot) => querySnapshot.docs)
        .map((doc) => Todo.fromMap(doc.data(), doc.id))
        .whereType<Todo>()
        .toList();
  }

  Future<List<Worker>> fetchAllWorkers(String storeId) async {
    final snapshot = await _db
        .collection('store_data')
        .doc(storeId)
        .collection('worker')
        .get();

    return snapshot.docs
        .map((doc) => Worker.fromMap(doc.data(), doc.id))
        .whereType<Worker>()
        .toList();
  }

  Future<String?> fetchTodoExecutionImageUrl({
    required String storeId,
    required String executionId,
    required String submissionImageId,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('store_data')
          .child(storeId)
          .child('todo_execution')
          .child(executionId)
          .child(submissionImageId);

      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // タスク関連の単発取得 (Joins用)
  // ==========================================

  /// 月次タスク用カテゴリーの取得
  Future<TaskCategory?> fetchMonthlyTaskCategory(
    String storeId,
    String categoryId,
  ) async {
    final doc = await _db
        .collection('store_data')
        .doc(storeId)
        .collection('task_single_category')
        .doc(categoryId)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return TaskCategory.fromJson(doc.data()!, doc.id);
  }

  /// 定期タスク用カテゴリーの取得
  Future<TaskCategory?> fetchTaskCategory(
    String storeId,
    String categoryId,
  ) async {
    final doc = await _db
        .collection('store_data')
        .doc(storeId)
        .collection('task_category')
        .doc(categoryId)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return TaskCategory.fromJson(doc.data()!, doc.id);
  }

  /// 定期タスクの内容(TaskInfo / TaskStepInfo)の取得
  /// コレクション task2 から取得する。呼び出し元で型を判定してパースする。
  Future<Map<String, dynamic>?> fetchTask2Data(
    String storeId,
    String taskId,
  ) async {
    final doc = await _db
        .collection('store_data')
        .doc(storeId)
        .collection('task2')
        .doc(taskId)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  Future<Map<String, dynamic>?> fetchTaskStepData(String storeId, String taskId) async {
    final doc =
        await _db.collection('store_data').doc(storeId).collection('task_step').doc(taskId).get();

    if (!doc.exists) return null;
    return doc.data();
  }

  // ==========================================
  // 2. リアルタイム監視用 Stream (Listeners)
  // ==========================================

  Stream<DailySetup?> watchDailySetup(String storeId, String dailySetupId) {
    return _db
        .collection('store_data')
        .doc(storeId)
        .collection('daily_setup2')
        .doc(dailySetupId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return DailySetup.fromMap(snapshot.data()!, snapshot.id);
        });
  }

  Stream<List<WorkerClock>> watchWorkerClocks(String storeId, DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    final targetTimestamp = Timestamp.fromDate(targetDate);

    return _db
        .collection('store_data')
        .doc(storeId)
        .collection('worker_clock')
        .where('base_date.date', isEqualTo: targetTimestamp)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkerClock.fromMap(doc.data(), doc.id))
              .whereType<WorkerClock>()
              .toList();
        });
  }

  Stream<List<TodoExecution>> watchTodoExecutions(
    String storeId,
    DateTime date,
  ) {
    final targetDate = DateTime(date.year, date.month, date.day);
    final targetTimestamp = Timestamp.fromDate(targetDate);

    return _db
        .collection('store_data')
        .doc(storeId)
        .collection('todo_execution')
        .where('base_date.date', isEqualTo: targetTimestamp)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TodoExecution.fromMap(doc.data(), doc.id))
              .whereType<TodoExecution>()
              .toList();
        });
  }

  Stream<List<TaskExecution>> watchTaskExecutions(
    String storeId,
    DateTime date,
  ) {
    final targetDate = DateTime(date.year, date.month, date.day);
    final targetTimestamp = Timestamp.fromDate(targetDate);

    return _db
        .collection('store_data')
        .doc(storeId)
        .collection('task_execution2')
        .where('base_date.date', isEqualTo: targetTimestamp)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TaskExecution.fromMap(doc.data(), doc.id))
              .whereType<TaskExecution>()
              .toList();
        });
  }

  Stream<List<DailySales>> watchDailySales(String storeId, DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    final targetTimestamp = Timestamp.fromDate(targetDate);

    return _db
        .collection('store_data')
        .doc(storeId)
        .collection('daily_sales')
        .where('base_date', isEqualTo: targetTimestamp)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DailySales.fromMap(doc.data(), doc.id))
              .whereType<DailySales>()
              .toList();
        });
  }

  // ==========================================
  // タスク関連の監視 Stream
  // ==========================================

  /// 月次タスク (TaskTemporary) の監視
  /// 条件:
  /// 1. base_date < 営業日 + 14日
  /// 2. 未実施 (is_executed == false)
  /// 3. スキップなし (is_skipped == false)
  Stream<List<TaskTemporary>> watchTaskTemporaries(
    String storeId,
    DateTime operationDate,
  ) {
    final limitDate = operationDate.add(const Duration(days: 14));
    // 時刻を00:00:00に正規化
    final limitTimestamp = Timestamp.fromDate(
      DateTime(limitDate.year, limitDate.month, limitDate.day),
    );

    return _db
        .collection('store_data')
        .doc(storeId)
        .collection('task_single')
        .where('base_date.date', isLessThan: limitTimestamp)
        .where('is_executed', isEqualTo: false)
        .where('is_skipped', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return TaskTemporary.fromJson(data, doc.id);
          }).whereType<TaskTemporary>().toList();
        });
  }

  /// 定期タスク (TaskSchedule) の監視
  /// 条件は月次タスクと同じ
  Stream<List<TaskSchedule>> watchTaskSchedules(
    String storeId,
    DateTime operationDate,
  ) {
    final limitDate = operationDate.add(const Duration(days: 14));
    final limitTimestamp = Timestamp.fromDate(
      DateTime(limitDate.year, limitDate.month, limitDate.day),
    );

    return _db
        .collection('store_data')
        .doc(storeId)
        .collection('task_schedule')
        .where('base_date.date', isLessThan: limitTimestamp)
        .where('is_executed', isEqualTo: false)
        .where('is_skipped', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return TaskSchedule.fromJson(data, doc.id);
          }).whereType<TaskSchedule>().toList();
        });
  }

  /// 画像アップロード (Task Temporary用)
  /// path: store_data/{store_id}/task_single/{task_id}
  Future<void> uploadTaskTemporaryImage({
    required String storeId,
    required String taskId,
    required File imageFile,
  }) async {
    final ref = _storage
        .ref()
        .child('store_data')
        .child(storeId)
        .child('task_single')
        .child(taskId);

    await ref.putFile(imageFile);
  }

  /// Task Executionの作成
  Future<void> createTaskExecution({
    required String storeId,
    required TaskExecution execution,
  }) async {
    await _db
        .collection('store_data')
        .doc(storeId)
        .collection('task_execution2')
        .doc(execution.id)
        .set(execution.toMap());
  }

  /// Task Temporaryのステータス更新 (完了)
  /// is_executed = true
  Future<void> completeTaskTemporary({
    required String storeId,
    required String taskId,
  }) async {
    await _db
        .collection('store_data')
        .doc(storeId)
        .collection('task_single')
        .doc(taskId)
        .update({'is_executed': true});
  }

  /// Task Scheduleのステータス更新 (完了)
  /// is_executed = true
  Future<void> completeTaskSchedule({
    required String storeId,
    required String scheduleId,
  }) async {
    await _db
        .collection('store_data')
        .doc(storeId)
        .collection('task_schedule')
        .doc(scheduleId)
        .update({'is_executed': true});
  }

  /// Task Schedule (Step) の進捗更新
  /// executed_step_ids に追加
  Future<void> updateTaskScheduleStep({
    required String storeId,
    required String scheduleId,
    required String stepId,
  }) async {
    await _db
        .collection('store_data')
        .doc(storeId)
        .collection('task_schedule')
        .doc(scheduleId)
        .update({
          'executed_step_ids': FieldValue.arrayUnion([stepId]),
        });
  }

  // ==========================================
  // その他メソッド
  // ==========================================

  Future<TodoExecution?> fetchLatestTodoExecution({
    required String storeId,
    required String todoId,
  }) async {
    final snapshot = await _db
        .collection('store_data')
        .doc(storeId)
        .collection('todo_execution')
        .where('todo_id', isEqualTo: todoId)
        .where('is_skipped', isEqualTo: false)
        .orderBy('execution_end_time.date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return TodoExecution.fromMap(
      snapshot.docs.first.data(),
      snapshot.docs.first.id,
    );
  }

  Future<Worker?> fetchWorker(String storeId, String workerId) async {
    if (workerId.isEmpty) return null;

    final doc = await _db
        .collection('store_data')
        .doc(storeId)
        .collection('worker')
        .doc(workerId)
        .get();

    if (!doc.exists) return null;
    return Worker.fromMap(doc.data()!, doc.id);
  }

  Future<String?> fetchWorkerPhotoUrl({
    required String storeId,
    required String workerId,
  }) async {
    try {
      final ref = _storage.ref().child('store_data/$storeId/worker/$workerId');
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> uploadTodoExecutionImage({
    required String storeId,
    required String executionId,
    required String submissionImageId,
    required File imageFile,
  }) async {
    final ref = _storage
        .ref()
        .child('store_data')
        .child(storeId)
        .child('todo_execution')
        .child(executionId)
        .child(submissionImageId);

    await ref.putFile(imageFile);
  }

  Future<void> createTodoExecution({
    required String storeId,
    required TodoExecution execution,
  }) async {
    await _db
        .collection('store_data')
        .doc(storeId)
        .collection('todo_execution')
        .doc(execution.id)
        .set(execution.toMap());
  }

  Future<void> deleteTodoExecution({
    required String storeId,
    required String executionId,
  }) async {
    await _db
        .collection('store_data')
        .doc(storeId)
        .collection('todo_execution')
        .doc(executionId)
        .delete();
  }
}
