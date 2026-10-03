import 'meta_data_model.dart';

class Worker {
  final String id;
  final String familyName;
  final String givenName;
  final int hourlyWage;
  final String positionId;
  final String positionTitle;
  final String positionColorHex;
  final Metadata metadata;

  Worker({
    required this.id,
    required this.familyName,
    required this.givenName,
    required this.hourlyWage,
    required this.positionId,
    required this.positionTitle,
    required this.positionColorHex,
    required this.metadata,
  });

  static Worker? fromMap(Map<String, dynamic> data, String docId) {
    try {
      if (docId.isEmpty) {
        return null;
      }
      final nameInfo = data['name_info'] as Map<String, dynamic>? ?? {};
      final financialInfo = data['financial_info'] as Map<String, dynamic>? ?? {};
      final positionInfo = data['position_info'] as Map<String, dynamic>? ?? {};
      final positionId = positionInfo['position_id'] as String?;
      if (positionId == null || positionId.isEmpty) {
        return null;
      }

      return Worker(
        id: docId,
        familyName: nameInfo['family_name'] ?? '',
        givenName: nameInfo['given_name'] ?? '',
        hourlyWage: (financialInfo['hourly_wage'] as num?)?.toInt() ?? 0,
        positionId: positionId,
        positionTitle: positionTitles[positionId] ?? '不明',
        positionColorHex:
            positionColors[positionId] ?? '#000000',
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
      'name_info': {'family_name': familyName, 'given_name': givenName},
      'financial_info': {'hourly_wage': hourlyWage},
      'position_info': {'position_id': positionId},
      'metadata': metadata.toMap(),
    };
  }

  // Position id to Position Title mapping
  static const Map<String, String> positionTitles = {
    'employee': '社員',
    'manager': '店長',
    'partTime': 'アルバイト',
  };

  // Position id to Position Color Hex mapping
  static const Map<String, String> positionColors = {
    'employee': '#0000FF', // Blue
    'manager': '#FF0000', // Red
    'partTime': '#00FF00', // Green
  };

  // sorting by position
  static int compareByPosition(Worker a, Worker b) {
    final positionOrder = {'manager': 0, 'employee': 1, 'partTime': 2};

    final aOrder = positionOrder[a.positionId] ?? 99;
    final bOrder = positionOrder[b.positionId] ?? 99;

    return aOrder.compareTo(bOrder);
  }
}
