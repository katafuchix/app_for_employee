import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'todo_models.dart';

class TodoRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // コレクション参照のヘルパー（privateでもOK）
  CollectionReference<Map<String, dynamic>> _todoModeCol(String storeId) =>
      _db.collection('store_data').doc(storeId).collection('todo_mode');

  CollectionReference<Map<String, dynamic>> _todoMappingCol(String storeId) =>
      _db.collection('store_data').doc(storeId).collection('todo_mapping');

  CollectionReference<Map<String, dynamic>> _todo2Col(String storeId) =>
      _db.collection('store_data').doc(storeId).collection('todo2');

  // 1. TodoMode一覧を取得するメソッド
  Future<List<TodoModeDoc>> fetchTodoModes(String storeId) async {
    debugPrint('Fetching TodoModes for storeId: $storeId');
    final snap = await _todoModeCol(storeId).get();
    final list = snap.docs.map((d) => TodoModeDoc.fromDoc(d)).toList();
    // ソートロジックもここに含める
    list.sort(
      (a, b) =>
          a.operationStartClockMinute.compareTo(b.operationStartClockMinute),
    );
    return list;
  }

  // 2. Todoリストを取得するメソッド
  Future<List<TodoRowVM>> fetchTodos({
    required String storeId,
    required String modeId,
    required String timezoneId,
    required String positionId,
  }) async {
    debugPrint('storeId: $storeId');
    debugPrint(
      'Fetching todos for modeId: $modeId, timezoneId: $timezoneId, positionId: $positionId',
    );
    final snap = await _todoMappingCol(storeId)
        .where('mode_id', isEqualTo: modeId)
        .where('timezone_id', isEqualTo: timezoneId)
        .where('position_id', isEqualTo: positionId)
        .where('metadata.is_deleted', isEqualTo: false)
        .get();

    final mappings = snap.docs.map((d) => TodoMappingDoc.fromDoc(d)).toList();
    mappings.sort((a, b) => a.index.compareTo(b.index));

    final futures = mappings
        .map((m) => _todo2Col(storeId).doc(m.todoId).get())
        .toList();
    final todoDocs = await Future.wait(futures);
    final todos = todoDocs.map((d) => Todo2Doc.fromDoc(d)).toList();

    final todoRowVMs = <TodoRowVM>[];
    for (int i = 0; i < todos.length; i++) {
      todoRowVMs.add(TodoRowVM(displayIndex: i + 1, todo: todos[i]));
    }

    return todoRowVMs;
  }
}
