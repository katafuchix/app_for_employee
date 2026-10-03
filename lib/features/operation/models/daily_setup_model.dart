import 'package:cloud_firestore/cloud_firestore.dart';
import 'meta_data_model.dart';

class DailySetup {
  final String id;
  final DateTime baseDate;
  final bool isOperating;
  final String todoModeId;
  final List<SalesForecastInfo> salesForecastInfos;
  final Metadata metadata;

  DailySetup({
    required this.id,
    required this.baseDate,
    required this.isOperating,
    required this.todoModeId,
    required this.salesForecastInfos,
    required this.metadata,
  });

  factory DailySetup.fromMap(Map<String, dynamic> data, String docId) {
    final baseDateMap = data['base_date'] as Map<String, dynamic>? ?? {};
    final timestamp = baseDateMap['date'] as Timestamp?;

    return DailySetup(
      id: docId,
      baseDate: timestamp?.toDate() ?? DateTime.now(),
      isOperating: data['is_operating'] ?? false,
      todoModeId: data['todo_mode_id'] ?? '',
      salesForecastInfos:
          (data['sales_forecast_infos'] as List<dynamic>?)
              ?.map((e) => SalesForecastInfo.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: data['metadata'] != null
          ? Metadata.fromMap(data['metadata'] as Map<String, dynamic>)
          : Metadata.empty(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'base_date': {'date': Timestamp.fromDate(baseDate)},
      'is_operating': isOperating,
      'todo_mode_id': todoModeId,
      'sales_forecast_infos': salesForecastInfos.map((e) => e.toMap()).toList(),
      'metadata': metadata.toMap(),
    };
  }
}

// 簡易的な予測情報クラス (構造が不明確な場合は柔軟に対応できるようvalueのみでも可)
class SalesForecastInfo {
  final int value;
  final DateTime date;

  SalesForecastInfo({required this.value, required this.date});

  factory SalesForecastInfo.fromMap(Map<String, dynamic> data) {
    final dateMap = data['base_date'] as Map<String, dynamic>? ?? {};
    final timestamp = dateMap['date'] as Timestamp?;

    return SalesForecastInfo(
      value: (data['value'] as num?)?.toInt() ?? 0,
      date: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'value': value,
    'base_date': {'date': Timestamp.fromDate(date)},
  };
}
