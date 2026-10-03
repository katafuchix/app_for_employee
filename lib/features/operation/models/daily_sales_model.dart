import 'package:cloud_firestore/cloud_firestore.dart';

class DailySales {
  final String id;
  final DateTime baseDate;
  final bool isInputPriority;
  final List<SalesInfo> salesInfos;
  final List<SalesInfo> inputSalesInfos;

  DailySales({
    required this.id,
    required this.baseDate,
    required this.isInputPriority,
    required this.salesInfos,
    required this.inputSalesInfos,
  });

  static DailySales? fromMap(Map<String, dynamic> data, String docId) {
    try {
      if (docId.isEmpty) {
        return null;
      }
      return DailySales(
        id: docId,
        baseDate: (data['base_date'] as Timestamp).toDate(),
        isInputPriority: data['is_input_priority'] ?? false,
        salesInfos:
            (data['sales_infos'] as List<dynamic>?)
                ?.map((e) => SalesInfo.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        inputSalesInfos:
            (data['input_sales_infos'] as List<dynamic>?)
                ?.map((e) => SalesInfo.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (_) {
      return null;
    }
  }
}

class SalesInfo {
  final DateTime date;
  final int sales;

  SalesInfo({required this.date, required this.sales});

  factory SalesInfo.fromMap(Map<String, dynamic> data) {
    return SalesInfo(
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sales: (data['sales'] as num?)?.toInt() ?? 0,
    );
  }
}
