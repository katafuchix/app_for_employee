import 'package:cloud_firestore/cloud_firestore.dart';
import 'meta_data_model.dart';

class WorkerClock {
  final String id;
  final String workerId;
  final DateTime baseDate;
  final DateTime? inTime;
  final DateTime? outTime;
  final Metadata metadata;

  WorkerClock({
    required this.id,
    required this.workerId,
    required this.baseDate,
    this.inTime,
    this.outTime,
    required this.metadata,
  });

  static WorkerClock? fromMap(Map<String, dynamic> data, String docId) {
    try {
      if (docId.isEmpty) {
        return null;
      }
      if (data['worker_id'] == null || (data['worker_id'] as String).isEmpty) {
        return null;
      }
      final baseDateMap = data['base_date'] as Map<String, dynamic>? ?? {};
      final baseTimestamp = baseDateMap['date'] as Timestamp?;

      final inTimeMap = data['in_time'] as Map<String, dynamic>? ?? {};
      final inTimestamp = inTimeMap['date'] as Timestamp?;
      final outTimeMap = data['out_time'] as Map<String, dynamic>? ?? {};
      final outTimestamp = outTimeMap['date'] as Timestamp?;

      return WorkerClock(
        id: docId,
        workerId: data['worker_id'] as String,
        baseDate: baseTimestamp?.toDate() ?? DateTime.now(),
        inTime: inTimestamp?.toDate(),
        outTime: outTimestamp?.toDate(),
        metadata: data['metadata'] != null
            ? Metadata.fromMap(data['metadata'] as Map<String, dynamic>)
            : Metadata.empty(),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'worker_id': workerId,
      'base_date': {'date': Timestamp.fromDate(baseDate)},
      'in_time': inTime != null ? Timestamp.fromDate(inTime!) : null,
      'out_time': outTime != null ? Timestamp.fromDate(outTime!) : null,
      'metadata': metadata.toMap(),
    };
  }
}
