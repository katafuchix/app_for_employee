// lib/AttendanceScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'attendance_models.dart';
import 'attendance_repository.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    super.key,
    required this.storeId,
    required this.storeWorkerId,
    this.uid,
    this.authId,
    this.fullName,
  });

  final String storeId;
  final String storeWorkerId;
  final String? uid;
  final String? authId;
  final String? fullName;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceRepository _repo = AttendanceRepository();

  late DateTime _targetMonthFirstDay;
  bool _showPerformance = false;

  bool _loading = false;
  String? _error;

  AttendanceMonthViewData? _viewData;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _targetMonthFirstDay = DateTime(now.year, now.month, 1);
    _load();
  }

  DateTime _nextMonthFirstDay(DateTime monthFirstDay) {
    return DateTime(monthFirstDay.year, monthFirstDay.month + 1, 1);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final monthStart = _targetMonthFirstDay;
      final monthEnd = _nextMonthFirstDay(_targetMonthFirstDay);

      final results = await Future.wait([
        _repo.fetchWorkerClocksForMonth(
          storeId: widget.storeId,
          monthStart: monthStart,
          monthEnd: monthEnd,
          storeWorkerId: widget.storeWorkerId,
          uid: widget.uid,
          authId: widget.authId,
        ),
        _repo.fetchDailyScoresForMonth(
          storeId: widget.storeId,
          monthStart: monthStart,
          monthEnd: monthEnd,
          storeWorkerId: widget.storeWorkerId,
          uid: widget.uid,
          authId: widget.authId,
        ),
      ]);

      final clocks = results[0] as List<WorkerClock>;
      final scores = results[1] as List<DailyWorkerScore>;

      final vm = AttendanceAggregator.buildMonthViewData(
        monthStart: monthStart,
        workerClocks: clocks,
        dailyScores: scores,
      );

      if (!mounted) return;
      setState(() {
        _viewData = vm;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _targetMonthFirstDay = DateTime(
        _targetMonthFirstDay.year,
        _targetMonthFirstDay.month + delta,
        1,
      );
    });
    _load();
  }

  Widget _buildBody(AttendanceMonthViewData? vm) {
    if (_loading && vm == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && vm == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('読み込みエラー\n$_error', textAlign: TextAlign.center),
        ),
      );
    }
    if (vm == null) {
      return const Center(child: Text('データがありません'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: vm.days.length + (_error != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (_error != null && index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '読み込みエラー（表示中データは前回のままです）\n$_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final dayIndex = _error != null ? index - 1 : index;
          final day = vm.days[dayIndex];

          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: _DayRow(day: day, showPerformance: _showPerformance),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewData;
    final year = _targetMonthFirstDay.year.toString();
    final month = _targetMonthFirstDay.month.toString();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // Stack をやめて Column に変更
        child: Column(
          children: [
            const SizedBox(height: 24), // 上部の余白 (ShiftPageに合わせる)
            // --- ヘッダー部分 (戻るボタン + タイトル + 右側の月選択) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左側: 戻るボタン + タイトル群
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 戻るボタン
                            InkWell(
                              onTap: () => Navigator.of(context).maybePop(),
                              borderRadius: BorderRadius.circular(24),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 24,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 時計アイコン
                            SvgPicture.asset(
                              "assets/images/Clock.svg",
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 6),

                            // タイトル
                            const Text(
                              "勤怠表",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // サブタイトル
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child: Text(
                            "月別の勤務状況の確認",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 右側: 月選択ブロック & 業務実績スイッチ
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "表示する月を選択",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _changeMonth(-1),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: SvgPicture.asset(
                                "assets/images/Chevron Left.svg",
                                width: 13,
                                height: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            year,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            "年",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            month,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            "月",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _changeMonth(1),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: SvgPicture.asset(
                                "assets/images/Chevron Right.svg",
                                width: 13,
                                height: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 業務実績スイッチ
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "業務実績",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: _showPerformance,
                              onChanged: (v) =>
                                  setState(() => _showPerformance = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Summary Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SummaryBar(
                showPerformance: _showPerformance,
                totalWorkDuration: vm?.totalWorkDuration,
                totalScore: vm?.totalScore,
                totalTodoExecutionDuration: vm?.totalTodoExecutionDuration,
                totalTaskExecutionDuration: vm?.totalTaskExecutionDuration,
                loading: _loading,
              ),
            ),

            const SizedBox(height: 10),

            // Body (リスト部分)
            // Columnの中なので Expanded で伸ばす
            Expanded(child: _buildBody(vm)),
          ],
        ),
      ),
    );
  }
}

// ==========================
// Summary
// ==========================
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.showPerformance,
    required this.totalWorkDuration,
    required this.totalScore,
    required this.totalTodoExecutionDuration,
    required this.totalTaskExecutionDuration,
    required this.loading,
  });

  final bool showPerformance;

  final Duration? totalWorkDuration;
  final double? totalScore;

  final Duration? totalTodoExecutionDuration;
  final Duration? totalTaskExecutionDuration;

  final bool loading;

  // ✅ 濃くて広がらない影（全枠で統一）
  static List<BoxShadow> get _tightShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.40),
      blurRadius: 5,
      spreadRadius: -2,
      offset: const Offset(0, 0),
    ),
  ];

  String _formatHoursNumber(Duration d) {
    final hours = d.inMinutes / 60.0;
    return hours.toStringAsFixed(1);
  }

  String _formatScore(double s) => s.toStringAsFixed(1);

  String _formatHm(Duration d) {
    final totalMin = d.inMinutes;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    if (!showPerformance) {
      final workNumber = totalWorkDuration == null
          ? '--'
          : _formatHoursNumber(totalWorkDuration!);
      final scoreText = totalScore == null ? '--' : _formatScore(totalScore!);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _tightShadow,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "勤務合計:",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    workNumber,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    "時間",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 22),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "合計スコア:",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    scoreText,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      color: (totalScore ?? 0) < 0 ? Colors.red : Colors.black,
                    ),
                  ),
                  if (loading) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    // ✅ 業務実績（黒=ToDo合計 / 赤=タスク合計）
    final todoText = totalTodoExecutionDuration == null
        ? '--'
        : _formatHm(totalTodoExecutionDuration!);
    final taskText = totalTaskExecutionDuration == null
        ? '--'
        : _formatHm(totalTaskExecutionDuration!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: _tightShadow,
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "合計ToDo実施:",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  todoText,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: Colors.black, // 黒
                  ),
                ),
              ],
            ),
            const SizedBox(width: 22),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "合計タスク実施:",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  taskText,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: Colors.red, // 赤
                  ),
                ),
                if (loading) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================
// Day Row
// ==========================
class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.showPerformance});

  final DailyAttendance day;
  final bool showPerformance;

  // ✅ 濃くて広がらない影（全枠で統一）
  static List<BoxShadow> get _tightShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.40),
      blurRadius: 5,
      spreadRadius: -2,
      offset: const Offset(0, 0),
    ),
  ];

  static const _weekdayJa = <int, String>{
    DateTime.monday: '月',
    DateTime.tuesday: '火',
    DateTime.wednesday: '水',
    DateTime.thursday: '木',
    DateTime.friday: '金',
    DateTime.saturday: '土',
    DateTime.sunday: '日',
  };

  Color _weekdayColor(int weekday) {
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return Colors.red;
    }
    return Colors.black;
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _formatTime(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';

  String _formatScore(double s) {
    final sign = s > 0 ? '+' : '';
    return '$sign${s.toStringAsFixed(1)}';
  }

  String _formatHm(Duration d) {
    final totalMin = d.inMinutes;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  Widget _leftDateBlock({
    required DateTime date,
    required String weekdayText,
    required Color leftColor,
    required double height,
  }) {
    return SizedBox(
      width: 50,
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    "${date.day}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: leftColor,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "日",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: leftColor,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Text(
                weekdayText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: leftColor,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = day.date;
    final weekdayText = _weekdayJa[date.weekday] ?? '';
    final leftColor = _weekdayColor(date.weekday);

    final hasClock = day.minIn != null && day.maxOut != null;
    final hasScore = day.score != null;

    final hasPerformanceData =
        day.todoExecutionDuration.inMinutes > 0 ||
        day.taskExecutionDuration.inMinutes > 0;

    const double cardHeight = 50;

    // データなし（スコアも勤怠も業務実績もない）→ 空カード
    if (!hasClock && !hasScore && !hasPerformanceData) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _leftDateBlock(
            date: date,
            weekdayText: weekdayText,
            leftColor: leftColor,
            height: cardHeight,
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: cardHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5FB),
                borderRadius: BorderRadius.circular(10),
                boxShadow: _tightShadow,
              ),
            ),
          ),
        ],
      );
    }

    // 左（スコア：黄色は「値自体が今までと同じ」）
    final scoreValue = day.score ?? 0.0;
    final scoreIsPositive = scoreValue >= 0;
    final scoreBg = scoreIsPositive
        ? const Color(0xFFDFF7EF)
        : const Color(0xFFFBE3E3);
    final scoreFg = scoreIsPositive ? Colors.green : Colors.red;

    // OFF：勤怠表示
    if (!showPerformance) {
      final inOutText = hasClock
          ? '${_formatTime(day.minIn!)} - ${_formatTime(day.maxOut!)}'
          : '--:-- - --:--';

      final workH = day.workDuration.inHours;
      final workM = day.workDuration.inMinutes % 60;
      final breakMin = day.breakDuration.inMinutes;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _leftDateBlock(
            date: date,
            weekdayText: weekdayText,
            leftColor: leftColor,
            height: cardHeight,
          ),
          const SizedBox(width: 3),
          Expanded(
            child: SizedBox(
              height: cardHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _tightShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: scoreBg,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(10),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _formatScore(scoreValue),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scoreFg,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "勤務",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  inOutText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "勤務時間",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          "$workH",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(width: 1),
                                        const Text(
                                          "h",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            height: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          workM.toString().padLeft(2, '0'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(width: 1),
                                        const Text(
                                          "m",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            height: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "休憩:",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$breakMin",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(width: 1),
                                const Text(
                                  "分",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ON：業務実績表示（緑=ToDo、紫=タスク） ※値は minute → 〇h〇〇m 変換
    final todoText = _formatHm(day.todoExecutionDuration);
    final taskText = _formatHm(day.taskExecutionDuration);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _leftDateBlock(
          date: date,
          weekdayText: weekdayText,
          leftColor: leftColor,
          height: cardHeight,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: SizedBox(
            height: cardHeight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: _tightShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: scoreBg,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(10),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _formatScore(scoreValue),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scoreFg,
                        height: 1.0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Todo実施",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                todoText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 22,
                            color: Colors.black12,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "タスク時間",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                taskText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
