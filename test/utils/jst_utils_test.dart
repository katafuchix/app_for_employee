import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tebanashi/utils/jst_utils.dart';

void main() {
  group('JST Utils Tests', () {
    test('timestampToJST converts UTC correctly', () {
      // UTC: 2024-03-14 15:00:00 → JST: 2024-03-15 00:00:00
      final utcTime = DateTime.utc(2024, 3, 14, 15, 0, 0);
      final timestamp = Timestamp.fromDate(utcTime);
      final jst = timestampToJST(timestamp);

      expect(jst.year, 2024);
      expect(jst.month, 3);
      expect(jst.day, 15);
      expect(jst.hour, 0);
      expect(jst.minute, 0);
    });

    test('timestampToJST handles midnight boundary', () {
      // UTC: 2024-03-14 23:59:00 → JST: 2024-03-15 08:59:00
      final utcTime = DateTime.utc(2024, 3, 14, 23, 59, 0);
      final timestamp = Timestamp.fromDate(utcTime);
      final jst = timestampToJST(timestamp);

      expect(jst.year, 2024);
      expect(jst.month, 3);
      expect(jst.day, 15);
      expect(jst.hour, 8);
      expect(jst.minute, 59);
    });

    test('toJSTDateOnly normalizes to midnight JST', () {
      final dateTime = DateTime(2024, 3, 15, 14, 30, 0);
      final jstDate = toJSTDateOnly(dateTime);

      expect(jstDate.year, 2024);
      expect(jstDate.month, 3);
      expect(jstDate.day, 15);
      expect(jstDate.hour, 0);
      expect(jstDate.minute, 0);
      expect(jstDate.second, 0);
    });

    test('toJSTDateOnly handles UTC date boundary', () {
      // A DateTime that is March 14 in UTC but March 15 in JST
      final utcDateTime = DateTime.utc(2024, 3, 14, 20, 0, 0);
      final jstDate = toJSTDateOnly(utcDateTime);

      // Should be normalized to March 15 00:00:00 JST
      expect(jstDate.year, 2024);
      expect(jstDate.month, 3);
      expect(jstDate.day, 15);
      expect(jstDate.hour, 0);
    });

    test('jstDate creates correct JST date', () {
      final date = jstDate(2024, 3, 15);

      expect(date.year, 2024);
      expect(date.month, 3);
      expect(date.day, 15);
      expect(date.hour, 0);
      expect(date.minute, 0);
      expect(date.second, 0);
    });

    test('jstNow returns JST time', () {
      final now = jstNow();
      final utcNow = DateTime.now().toUtc();
      final expectedJst = utcNow.add(const Duration(hours: 9));

      // Check that jstNow is within a few seconds of expected JST
      final diff = now.difference(expectedJst).inSeconds.abs();
      expect(diff, lessThan(2), reason: 'jstNow should return current JST time');
    });

    test('timestampToJSTNullable handles null', () {
      final result = timestampToJSTNullable(null);
      expect(result, isNull);
    });

    test('timestampToJSTNullable handles non-null', () {
      final utcTime = DateTime.utc(2024, 3, 14, 15, 0, 0);
      final timestamp = Timestamp.fromDate(utcTime);
      final result = timestampToJSTNullable(timestamp);

      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 3);
      expect(result.day, 15);
    });

    test('month-end boundary test - March 31 to April 1', () {
      // UTC: March 31 23:00 → JST: April 1 08:00
      final utcTime = DateTime.utc(2024, 3, 31, 23, 0, 0);
      final timestamp = Timestamp.fromDate(utcTime);
      final jst = timestampToJST(timestamp);

      expect(jst.year, 2024);
      expect(jst.month, 4);
      expect(jst.day, 1);
    });

    test('toJSTDateOnly is idempotent', () {
      final date = jstDate(2024, 3, 15);
      final once = toJSTDateOnly(date);
      final twice = toJSTDateOnly(once);

      expect(once, equals(twice));
    });
  });
}
