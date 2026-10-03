import 'package:flutter/material.dart';
import 'package:tebanashi/features/shift/shift_repository.dart';

import '../../core/theme/app_colors.dart';
import 'shift_models.dart';

class ShiftPage extends StatefulWidget {
  final String uid;
  final String authId;
  final String storeId;
  final String storeWorkerId;
  final String fullName;

  const ShiftPage({
    super.key,
    required this.uid,
    required this.authId,
    required this.storeId,
    required this.storeWorkerId,
    required this.fullName,
  });

  @override
  State<ShiftPage> createState() => _ShiftPageState();
}

class _ShiftPageState extends State<ShiftPage> {
  final ShiftRepository _repo = ShiftRepository();
  bool _loading = true;
  String? _errorMessage;

  late DateTime _currentMonth; // 年月のみ（1日固定）

  /// day(1-31) -> DailyShiftSummary
  Map<int, DailyShiftSummary> _daySummaries = {};
  Duration _monthlyTotalWork = Duration.zero;
  int _monthlyWorkingDays = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _loadShiftsForMonth();
  }

  Future<void> _loadShiftsForMonth() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repo.fetchMonthlyShiftSummaries(
        storeId: widget.storeId,
        workerId: widget.storeWorkerId,
        month: _currentMonth,
      );

      if (!mounted) return;
      setState(() {
        _daySummaries = data.daySummaries;
        _monthlyTotalWork = data.monthlyTotalWork;
        _monthlyWorkingDays = data.monthlyWorkingDays;
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('ShiftPage _loadShiftsForMonth error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'シフトデータの取得中にエラーが発生しました。';
      });
    }
  }

  void _changeMonth(int diff) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + diff,
        1,
      );
    });
    _loadShiftsForMonth();
  }

  // ==== モーダル（日別・スクショ通りのレイアウト） ====
  void _openDayDetail(DailyShiftSummary summary) {
    final d = summary.date;
    final monthStr = d.month.toString();
    final dayStr = d.day.toString();
    final weekdayStr = _weekdayJp(d.weekday);

    final firstInStr = _formatTime(summary.firstIn);
    final lastOutStr = _formatTime(summary.lastOut);
    final workRangeLabel = '$firstInStr 〜 $lastOutStr';

    final totalWorkStr = _formatDuration(summary.totalWork);
    final totalBreakStr = _formatDuration(summary.totalBreak);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (_) {
        final media = MediaQuery.of(context);

        final double modalHeight = media.size.height * 0.68;

        // デバイスの高さに応じて Coming Soon 高さを変える
        final double csHeight;
        if (media.size.height <= 680) {
          csHeight = media.size.height * 0.32;
        } else if (media.size.height <= 820) {
          csHeight = media.size.height * 0.38;
        } else {
          csHeight = media.size.height * 0.41;
        }

        return SizedBox(
          height: modalHeight,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル「11月16日（木）の出勤情報」
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: monthStr, // 「11」
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.headerBlack,
                              ),
                            ),
                            const TextSpan(
                              text: '月',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.headerBlack,
                              ),
                            ),
                            TextSpan(
                              text: dayStr, // 「16」
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.headerBlack,
                              ),
                            ),
                            const TextSpan(
                              text: '日（',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.headerBlack,
                              ),
                            ),
                            TextSpan(
                              text: weekdayStr, // 「木」は数字と同じくらい
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.headerBlack,
                              ),
                            ),
                            const TextSpan(
                              text: '）',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.headerBlack,
                              ),
                            ),
                            const TextSpan(
                              text: ' の出勤情報',
                              style: TextStyle(
                                fontSize: 14, // 数字より小さめ
                                fontWeight: FontWeight.w500,
                                color: AppColors.subText, // やや薄めグレー
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 上段：左＝出勤時間（左寄せのまま、重ね順で中央合わせ）／右＝勤務・休憩
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 出勤時間（左寄せのまま、Stackで重ねる）
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: _OverlayCenterLabel(
                              label: '出勤時間',
                              labelStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.headerBlack,
                                height: 1.3,
                              ),
                              valueText: workRangeLabel, // 例: "10:00 〜 15:00"
                              valueStyle: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.headerBlack,
                                height: 1.6,
                              ),
                              spacing: 3,
                              nudgeDown: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // 勤務・休憩（右寄せ）
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 勤務
                            Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    '勤務',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.headerBlack,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  RichText(
                                    text: TextSpan(
                                      children: _buildDurationSpans(
                                        totalWorkStr,
                                        isBreak: false,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),

                            // 休憩
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  '休憩',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.subText,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                RichText(
                                  text: TextSpan(
                                    children: _buildDurationSpans(
                                      totalBreakStr,
                                      isBreak: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Coming Soon
                    Container(
                      height: csHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text(
                          'Coming Soon...',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF9E9E9E),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        '${_currentMonth.year}年 ${_currentMonth.month.toString().padLeft(2, '0')}月';
    final monthTotalHours = _monthlyTotalWork.inMinutes / 60.0; // 小数1桁で表示する

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadShiftsForMonth,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(child: _HeaderBlock()),
                            const SizedBox(width: 8),
                            _MonthSelector(
                              monthLabel: monthLabel,
                              onPrev: () => _changeMonth(-1),
                              onNext: () => _changeMonth(1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MonthlySummaryCard(
                        totalHours: monthTotalHours,
                        workingDays: _monthlyWorkingDays,
                      ),
                      const SizedBox(height: 16),
                      const _WeekdayHeaderRow(),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _ShiftCalendarGrid(
                          currentMonth: _currentMonth,
                          daySummaries: _daySummaries,
                          onTapDay: (summary) {
                            if (summary != null) {
                              _openDayDetail(summary);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ===== ヘッダー部分 =====

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(8.0), // タップ領域を確保
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.headerBlack,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 4), // ボタンとアイコンの間隔
            Image.asset('assets/images/icon.png', width: 24, height: 24),
            const SizedBox(width: 6),
            const Text(
              'シフト確認',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.headerBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '出勤日を確認することができます',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.subText,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '表示する月を選択',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.headerBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onPrev,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_left, size: 20),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headerBlack,
                ),
              ),
              const SizedBox(width: 2),
              InkWell(
                onTap: onNext,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_right, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  final double totalHours;
  final int workingDays;

  const _MonthlySummaryCard({
    required this.totalHours,
    required this.workingDays,
  });

  @override
  Widget build(BuildContext context) {
    final totalHoursStr = totalHours.toStringAsFixed(1);
    final baseStyle = TextStyle(
      fontSize: 13,
      color: AppColors.darkGrey,
      fontWeight: FontWeight.w700,
    );
    final numberStyle = baseStyle.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w800,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBoarder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('今月の合計シフト: ', style: baseStyle),
            Text(totalHoursStr, style: numberStyle),
            Text('時間', style: baseStyle),
            const SizedBox(width: 18),
            Text('出勤日数: ', style: baseStyle),
            Text(workingDays.toString(), style: numberStyle),
            Text('日', style: baseStyle),
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow();

  @override
  Widget build(BuildContext context) {
    const labels = ['日', '月', '火', '水', '木', '金', '土'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(labels.length, (index) {
          final label = labels[index];
          Color color = Colors.black87;
          if (index == 0) color = Colors.red;
          if (index == 6) color = Colors.red;
          return Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          );
        }),
      ),
    );
  }
}

// ===== カレンダーグリッド =====

class _CalendarCellData {
  final int? day;
  final DailyShiftSummary? summary;
  final bool isToday;

  _CalendarCellData({
    required this.day,
    required this.summary,
    required this.isToday,
  });

  const _CalendarCellData.placeholder()
    : day = null,
      summary = null,
      isToday = false;
}

class _ShiftCalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final Map<int, DailyShiftSummary> daySummaries;
  final void Function(DailyShiftSummary? summary) onTapDay;

  const _ShiftCalendarGrid({
    required this.currentMonth,
    required this.daySummaries,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      currentMonth.year,
      currentMonth.month,
    );

    final int weekday = firstDayOfMonth.weekday;
    final int prefixEmpty = weekday % 7;

    final now = DateTime.now();
    final bool sameMonth =
        now.year == currentMonth.year && now.month == currentMonth.month;

    final List<_CalendarCellData> cells = [];

    for (int i = 0; i < prefixEmpty; i++) {
      cells.add(const _CalendarCellData.placeholder());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final summary = daySummaries[day];
      final isToday = sameMonth && now.day == day;
      cells.add(
        _CalendarCellData(day: day, summary: summary, isToday: isToday),
      );
    }

    return GridView.builder(
      itemCount: cells.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        // 枠を高くするため、childAspectRatio を小さめに
        childAspectRatio: 0.6,
      ),
      itemBuilder: (context, index) {
        final cell = cells[index];
        return _DayCell(
          cell: cell,
          onTap: () {
            if (cell.summary != null) {
              onTapDay(cell.summary);
            }
          },
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  final _CalendarCellData cell;
  final VoidCallback onTap;

  const _DayCell({required this.cell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (cell.day == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }

    final summary = cell.summary;
    final bool hasShift = summary != null && summary.segments.isNotEmpty;

    // 予定なし
    if (!hasShift) {
      final bool isToday = cell.isToday;

      final Widget contentNoShift = Container(
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(6),
          border: isToday
              ? Border.all(color: Colors.lightBlue, width: 2.0)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    cell.day!.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isToday ? Colors.lightBlue : AppColors.headerBlack,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const Spacer(flex: 2),
              const Center(
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subText,
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      );

      return contentNoShift;
    }

    // シフトあり
    final bool isToday = cell.isToday;
    final String startLabel = '${_formatTime(summary.firstIn)}〜';
    final String hoursLabel = _formatDurationHours(summary.totalWork);

    final Widget content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday ? Colors.lightBlue : AppColors.cardBoarder,
          width: isToday ? 2.0 : 1.0,
        ),
        boxShadow: isToday
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  cell.day!.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.lightBlue : AppColors.headerBlack,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.check_circle,
                  size: 11,
                  color: AppColors.green,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.center,
              child: Text(
                startLabel,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headerBlack,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.center,
              child: Text(
                hoursLabel,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headerBlack,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(onTap: onTap, child: content);
  }
}

// ===== 出勤時間ラベルを“重ね順”で中央に合わせるウィジェット =====

class _OverlayCenterLabel extends StatelessWidget {
  final String label;
  final TextStyle labelStyle;
  final String valueText;
  final TextStyle valueStyle;
  final double spacing; // ラベルと値の間隔
  final double nudgeDown; // 全体を下にずらす量（px）

  const _OverlayCenterLabel({
    required this.label,
    required this.labelStyle,
    required this.valueText,
    required this.valueStyle,
    this.spacing = 2.0,
    this.nudgeDown = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: nudgeDown),
      child: IntrinsicWidth(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: (labelStyle.fontSize ?? 13) + spacing,
              ),
              child: Text(
                valueText,
                style: valueStyle,
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Text(
                label,
                style: labelStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 「4時間30分」みたいな文字列を「数字大・時間/分小」に分ける =====

List<TextSpan> _buildDurationSpans(String text, {required bool isBreak}) {
  final spans = <TextSpan>[];
  final numberColor = isBreak ? AppColors.subText : AppColors.headerBlack;
  final unitColor = isBreak ? AppColors.subText : AppColors.headerBlack;

  final numberStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: numberColor,
    height: 1.0,
    letterSpacing: 0.2,
  );

  final unitStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: unitColor,
    height: 1.0,
  );

  final regex = RegExp(r'(\d+)|(\D+)');
  for (final m in regex.allMatches(text)) {
    final part = m.group(0) ?? '';
    if (part.isEmpty) continue;
    final bool isNumber = RegExp(r'^\d+$').hasMatch(part);
    spans.add(TextSpan(text: part, style: isNumber ? numberStyle : unitStyle));
  }

  return spans;
}

// ===== ヘルパー =====

String _weekdayJp(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return '月';
    case DateTime.tuesday:
      return '火';
    case DateTime.wednesday:
      return '水';
    case DateTime.thursday:
      return '木';
    case DateTime.friday:
      return '金';
    case DateTime.saturday:
      return '土';
    case DateTime.sunday:
    default:
      return '日';
  }
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatDuration(Duration d) {
  final totalMinutes = d.inMinutes;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '$hours時間${minutes.toString().padLeft(2, '0')}分';
}

String _formatDurationHours(Duration d) {
  final totalMinutes = d.inMinutes;
  final double hours = totalMinutes / 60.0;
  final String hStr = hours % 1 == 0
      ? hours.toStringAsFixed(1).replaceAll('.0', '')
      : hours.toStringAsFixed(1);
  return '$hStr時間';
}
