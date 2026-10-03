// lib/TodoPage.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tebanashi/features/todo/todo_repository.dart';

import '../../core/theme/app_colors.dart';
import 'todo_detail_modal.dart';
import 'todo_models.dart';

/// 4文字以上は...（セレクタ/ポップ表示用）
/// ※ Todoカードの title/detail は切らない（TextOverflow.ellipsis のみ）
String _ellipsis4(String s) {
  final r = s.runes.toList();
  if (r.length <= 4) return s;
  return '${String.fromCharCodes(r.take(4))}...';
}

class TodoPage extends StatefulWidget {
  const TodoPage({
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
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  // 全体の左右余白
  static const double _pageHPad = 16.0;

  final TodoRepository _repo = TodoRepository();

  // ===== State =====
  bool _loadingModes = true;
  String? _modeError;

  List<TodoModeDoc> _modes = [];
  TodoModeDoc? _selectedMode;
  TimezoneInfo? _selectedTimezone;
  PositionInfo? _selectedPosition;

  bool _loadingTodos = false;
  String? _todoError;
  List<TodoRowVM> _todos = [];

  @override
  void initState() {
    super.initState();
    _loadTodoModes();
  }

  // =========================
  // Load Todo Mode
  // =========================
  Future<void> _loadTodoModes() async {
    setState(() {
      _loadingModes = true;
      _modeError = null;
    });

    try {
      final modes = await _repo.fetchTodoModes(widget.storeId);

      if (!mounted) return;
      setState(() {
        _modes = modes;
        _loadingModes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingModes = false;
        _modeError = e.toString();
      });
    }
  }

  // =========================
  // Load Todos (todo_mapping -> todo2)
  // =========================
  Future<void> _maybeLoadTodos() async {
    final mode = _selectedMode;
    final tz = _selectedTimezone;
    final pos = _selectedPosition;

    if (mode == null || tz == null || pos == null) {
      setState(() {
        _todos = [];
        _todoError = null;
      });
      return;
    }

    await _loadTodos(modeId: mode.id, timezoneId: tz.id, positionId: pos.id);
  }

  Future<void> _loadTodos({
    required String modeId,
    required String timezoneId,
    required String positionId,
  }) async {
    setState(() {
      _loadingTodos = true;
      _todoError = null;
    });

    try {
      final todos = await _repo.fetchTodos(
        storeId: widget.storeId,
        modeId: modeId,
        timezoneId: timezoneId,
        positionId: positionId,
      );

      if (!mounted) return;
      setState(() {
        _todos = todos;
        _loadingTodos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingTodos = false;
        _todoError = e.toString();
      });
    }
  }

  // =========================
  // Time helpers
  // =========================
  String _two(int n) => n.toString().padLeft(2, '0');

  String _minuteToHHmm(int minute) {
    final m = minute % (24 * 60);
    final h = m ~/ 60;
    final mm = m % 60;
    return '${_two(h)}:${_two(mm)}';
  }

  String _minuteToHm(int minute) {
    final h = minute ~/ 60;
    final m = minute % 60;
    return '${h}h ${_two(m)}m';
  }

  int _modeStartMinute(TodoModeDoc mode) => mode.operationStartClockMinute;

  int _modeEndMinute(TodoModeDoc mode) {
    final sum = mode.timezones.fold<int>(0, (p, e) => p + e.durationMinute);
    return mode.operationStartClockMinute + sum;
  }

  int _timezoneStartMinute(TodoModeDoc mode, TimezoneInfo tz) {
    int acc = mode.operationStartClockMinute;
    for (final t in mode.timezones) {
      if (t.id == tz.id) break;
      acc += t.durationMinute;
    }
    return acc;
  }

  int _timezoneEndMinute(TodoModeDoc mode, TimezoneInfo tz) =>
      _timezoneStartMinute(mode, tz) + tz.durationMinute;

  int _timezoneTodoTotalMinute(TodoModeDoc mode, String timezoneId) {
    int sum = 0;
    for (final s in mode.summaryInfos) {
      if (s.timezoneId == timezoneId) sum += s.totalDurationMinute;
    }
    return sum;
  }

  // =========================
  // 未選択メッセージ（欠けている組み合わせで出し分け）
  // =========================
  String _missingMessage({
    required TodoModeDoc? mode,
    required TimezoneInfo? tz,
    required PositionInfo? pos,
  }) {
    final missing = <String>[];
    if (mode == null) missing.add('Todoモード');
    if (tz == null) missing.add('タイムゾーン');
    if (pos == null) missing.add('ポジション');

    if (missing.isEmpty) return '';
    if (missing.length == 1) return '${missing[0]}を選択してください';
    if (missing.length == 2) return '${missing[0]}と${missing[1]}を選択してください';
    return 'Todoモードとタイムゾーンとポジションを選択してください';
  }

  // =========================
  // Popup dialogs
  // =========================
  Future<void> _openModePopup() async {
    if (_loadingModes) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'mode_popup',
      barrierColor: Colors.black.withValues(alpha: 0.60),
      transitionDuration: const Duration(milliseconds: 170),
      pageBuilder: (context, _, __) {
        return _PopupScaffold(
          title: 'モード一覧',
          subtitle: 'Todoモードを選択してください',
          onClose: () => Navigator.of(context).pop(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            itemCount: _modes.length,
            itemBuilder: (context, i) {
              final mode = _modes[i];
              final selected = _selectedMode?.id == mode.id;

              final start = _minuteToHHmm(_modeStartMinute(mode));
              final end = _minuteToHHmm(_modeEndMinute(mode));

              final tzCount = mode.timezones.length;
              final posCount = mode.positions.length;

              final totalTodoMin = mode.summaryInfos.fold<int>(
                0,
                (p, e) => p + e.totalDurationMinute,
              );
              final totalHm = _minuteToHm(totalTodoMin);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMode = mode;
                      _selectedTimezone = null;
                      _selectedPosition = null;
                      _todos = [];
                      _todoError = null;
                    });
                    Navigator.of(context).pop();
                  },
                  child: _ModeRowCard(
                    selected: selected,
                    modeTitle: _ellipsis4(mode.title),
                    timeText: '$start ~ $end',
                    timezoneCount: tzCount,
                    positionCount: posCount,
                    totalHm: totalHm,
                  ),
                ),
              );
            },
          ),
        );
      },
      transitionBuilder: (context, anim, __, child) {
        final a = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(a),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _openTimezonePopup() async {
    final mode = _selectedMode;
    if (mode == null) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'timezone_popup',
      barrierColor: Colors.black.withValues(alpha: 0.60),
      transitionDuration: const Duration(milliseconds: 170),
      pageBuilder: (context, _, __) {
        return _PopupScaffold(
          title: 'タイムゾーン一覧',
          subtitle: 'タイムゾーンを選択してください',
          onClose: () => Navigator.of(context).pop(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            itemCount: mode.timezones.length,
            itemBuilder: (context, i) {
              final tz = mode.timezones[i];
              final selected = _selectedTimezone?.id == tz.id;

              final start = _minuteToHHmm(_timezoneStartMinute(mode, tz));
              final end = _minuteToHHmm(_timezoneEndMinute(mode, tz));

              final todoMin = _timezoneTodoTotalMinute(mode, tz.id);
              final todoHm = _minuteToHm(todoMin);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTimezone = tz;
                      _todos = [];
                      _todoError = null;
                    });
                    Navigator.of(context).pop();
                    _maybeLoadTodos();
                  },
                  child: _TimezoneRowCard(
                    selected: selected,
                    title: _ellipsis4(tz.title),
                    timeText: '$start ~ $end',
                    todoHm: todoHm,
                  ),
                ),
              );
            },
          ),
        );
      },
      transitionBuilder: (context, anim, __, child) {
        final a = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(a),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _openPositionPopup() async {
    final mode = _selectedMode;
    if (mode == null) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'position_popup',
      barrierColor: Colors.black.withValues(alpha: 0.60),
      transitionDuration: const Duration(milliseconds: 170),
      pageBuilder: (context, _, __) {
        return _PopupScaffold(
          title: 'ポジション一覧',
          subtitle: 'ポジションを選択してください',
          onClose: () => Navigator.of(context).pop(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            itemCount: mode.positions.length,
            itemBuilder: (context, i) {
              final pos = mode.positions[i];
              final selected = _selectedPosition?.id == pos.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPosition = pos;
                      _todos = [];
                      _todoError = null;
                    });
                    Navigator.of(context).pop();
                    _maybeLoadTodos();
                  },
                  child: _PositionRowCard(
                    selected: selected,
                    peopleCount: pos.peopleCount,
                    title: _ellipsis4(pos.title),
                  ),
                ),
              );
            },
          ),
        );
      },
      transitionBuilder: (context, anim, __, child) {
        final a = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(a),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _openTodoDetail(TodoRowVM row) async {
    final posTitle = _selectedPosition?.title ?? 'ポジション未選択';

    await showDialog(
      context: context,
      builder: (context) {
        return TodoDetailViewerModal(
          row: row,
          storeId: widget.storeId,
          positionTitle: posTitle,
        );
      },
    );
  }

  // =========================
  // Main UI
  // =========================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_pageHPad, 24, _pageHPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 戻るボタン
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: const Icon(
                  // SvgPictureからIconに変更して統一感を出す（SVGのままでも可）
                  Icons.arrow_back_ios_new_rounded,
                  size: 24,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),

              SvgPicture.asset(
                'assets/images/List.svg',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),

              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  'Todoリスト',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Text(
              'モード・タイムゾーン・ポジション別のTodoの確認',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9A9A9A),
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSelectors() {
    final modeText = _ellipsis4(_selectedMode?.title ?? '未選択');
    final tzText = _ellipsis4(_selectedTimezone?.title ?? '未選択');
    final posText = _ellipsis4(_selectedPosition?.title ?? '未選択');

    return Padding(
      padding: const EdgeInsets.fromLTRB(_pageHPad, 2, _pageHPad, 6),
      child: Row(
        children: [
          Expanded(
            child: _TopSelectorPill(
              label: 'モード',
              value: modeText,
              enabled: !_loadingModes && _modeError == null,
              onTap: _openModePopup,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TopSelectorPill(
              label: 'タイムゾーン',
              value: tzText,
              enabled: _selectedMode != null,
              onTap: _openTimezonePopup,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TopSelectorPill(
              label: 'ポジション',
              value: posText,
              enabled: _selectedMode != null,
              onTap: _openPositionPopup,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // 青バー + タイムゾーンバー（カード一体）
  // =========================
  Widget _buildModeTimezoneCard() {
    final modeDoc = _selectedMode;
    if (modeDoc == null) return const SizedBox.shrink();

    final mode = _ellipsis4(modeDoc.title);
    final tzDoc = _selectedTimezone;
    final pos = _ellipsis4(_selectedPosition?.title ?? '未選択');

    final windowStart = _modeStartMinute(modeDoc);
    final windowEnd = _modeEndMinute(modeDoc);
    final span = (windowEnd - windowStart).clamp(1, 24 * 60);

    int? tzStart;
    int? tzEnd;
    String tzDurText = '';
    String tzTitle = '未選択';

    if (tzDoc != null) {
      tzTitle = _ellipsis4(tzDoc.title);
      tzStart = _timezoneStartMinute(
        modeDoc,
        tzDoc,
      ).clamp(windowStart, windowEnd);
      tzEnd = _timezoneEndMinute(modeDoc, tzDoc).clamp(windowStart, windowEnd);
      tzDurText = _minuteToHm(tzDoc.durationMinute);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(_pageHPad, 6, _pageHPad, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.whiteBoarder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              spreadRadius: -10,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            // 青いタイトルバー（中央寄せ）
            Container(
              height: 46,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                      children: [
                        TextSpan(
                          text: '$mode の $tzTitle の $pos',
                          style: const TextStyle(fontSize: 22),
                        ),
                        const TextSpan(
                          text: ' の',
                          style: TextStyle(fontSize: 22),
                        ),
                        const TextSpan(
                          text: 'Todoリスト',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),

            if (tzDoc != null) ...[
              // ★ここを増やすと「タイムゾーンの上に空白」
              const SizedBox(height: 10),

              // 左右時間 + 中央ラベル
              SizedBox(
                height: 18,
                width: double.infinity,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _minuteToHHmm(windowStart),
                        style: const TextStyle(
                          color: Color(0xFFC8C8C8),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'タイムゾーン時間: $tzDurText',
                        style: const TextStyle(
                          color: AppColors.cyan, // #63CEFF
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _minuteToHHmm(windowEnd),
                        style: const TextStyle(
                          color: Color(0xFFC8C8C8),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 隙間なし
              const SizedBox(height: 0),

              LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;

                  final leftRatio = ((tzStart! - windowStart) / span).clamp(
                    0.0,
                    1.0,
                  );
                  final rightRatio = ((tzEnd! - windowStart) / span).clamp(
                    0.0,
                    1.0,
                  );

                  final leftX = (w * leftRatio).clamp(0.0, w);
                  final rightX = (w * rightRatio).clamp(0.0, w);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 18,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 7,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                            Positioned(
                              left: leftX,
                              top: 7,
                              width: (rightX - leftX).clamp(0.0, w),
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.cyan,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 2,
                                height: 18,
                                color: const Color(0xFFD0D0D0),
                              ),
                            ),
                            Positioned(
                              left: leftX - 6,
                              top: 3,
                              child: const _Knob(),
                            ),
                            Positioned(
                              left: rightX - 6,
                              top: 3,
                              child: const _Knob(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 16,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              child: Text(
                                _minuteToHHmm(windowStart),
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            Positioned(
                              left: rightX - 2,
                              child: Text(
                                _minuteToHHmm(tzEnd),
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodoArea() {
    if (_modeError != null) {
      return Expanded(
        child: Center(
          child: Text(
            '読み込みエラー\n$_modeError',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    final mode = _selectedMode;
    final tz = _selectedTimezone;
    final pos = _selectedPosition;

    if (mode == null || tz == null || pos == null) {
      final msg = _missingMessage(mode: mode, tz: tz, pos: pos);
      return Expanded(
        child: Center(
          child: Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB5B5B5),
            ),
          ),
        ),
      );
    }

    if (_loadingTodos) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_todoError != null) {
      return Expanded(
        child: Center(
          child: Text(
            '読み込みエラー\n$_todoError',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(_pageHPad, 4, _pageHPad, 20),
        itemCount: _todos.length,
        itemBuilder: (context, i) {
          final row = _todos[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              // Add InkWell for tap effect
              onTap: () => _openTodoDetail(row), // Open the modal
              borderRadius: BorderRadius.circular(14),
              child: _TodoCard2Row(row: row),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loadingModes
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(),
                  _buildSelectors(),
                  _buildModeTimezoneCard(),
                  _buildTodoArea(),
                ],
              ),
      ),
    );
  }
}

// ==========================
// UI Parts
// ==========================
class _Knob extends StatelessWidget {
  const _Knob();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCFCFCF), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            spreadRadius: -4,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _TopSelectorPill extends StatelessWidget {
  const _TopSelectorPill({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = value != '未選択';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9A9A9A),
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.pillGrey,
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.blue
                          : const Color(0xFFDADADA),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF6F6F6F),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Color(0xFF808080),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================
// Popup
// ==========================
class _PopupScaffold extends StatelessWidget {
  const _PopupScaffold({
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.child,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.86,
        heightFactor: 0.82,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9A9A9A),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.modalRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================
// Popup Rows
// ==========================
class _ModeRowCard extends StatelessWidget {
  const _ModeRowCard({
    required this.selected,
    required this.modeTitle,
    required this.timeText,
    required this.timezoneCount,
    required this.positionCount,
    required this.totalHm,
  });

  final bool selected;
  final String modeTitle;
  final String timeText;
  final int timezoneCount;
  final int positionCount;
  final String totalHm;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.blue : Colors.white;
    final border = selected ? null : Border.all(color: const Color(0xFFE2E2E2));
    final topText = selected ? Colors.white : const Color(0xFF111111);

    return Column(
      children: [
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Text(
                modeTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: topText,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  timeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: topText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: topText,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                  children: [
                    const TextSpan(
                      text: 'タイムゾーン数: ',
                      style: TextStyle(fontSize: 11),
                    ),
                    TextSpan(
                      text: '$timezoneCount',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'ポジション数: ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF9A9A9A),
                height: 1.0,
              ),
            ),
            Text(
              '$positionCount',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111111),
                height: 1.0,
              ),
            ),
            const Text(
              ' ・ ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF9A9A9A),
                height: 1.0,
              ),
            ),
            const Text(
              'Todo合計時間: ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF9A9A9A),
                height: 1.0,
              ),
            ),
            Text(
              totalHm,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111111),
                height: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimezoneRowCard extends StatelessWidget {
  const _TimezoneRowCard({
    required this.selected,
    required this.title,
    required this.timeText,
    required this.todoHm,
  });

  final bool selected;
  final String title;
  final String timeText;
  final String todoHm;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: selected ? AppColors.blue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: selected ? null : Border.all(color: const Color(0xFFE2E2E2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.blue : const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              timeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          Text(
            'Todo時間: $todoHm',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionRowCard extends StatelessWidget {
  const _PositionRowCard({
    required this.selected,
    required this.peopleCount,
    required this.title,
  });

  final bool selected;
  final int peopleCount;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: selected ? AppColors.blue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: selected ? null : Border.all(color: const Color(0xFFE2E2E2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.black,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$peopleCount',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: selected ? AppColors.blue : Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================
// Todo Card（完全に2段）
// ==========================
class _TodoCard2Row extends StatelessWidget {
  const _TodoCard2Row({required this.row});

  final TodoRowVM row;

  @override
  Widget build(BuildContext context) {
    final t = row.todo;
    final hasManual = t.manualIds.isNotEmpty;

    final title = t.title;
    final detail = t.useDetail ? t.detail : '';
    final hasDetail = detail.trim().isNotEmpty;

    const cardH = 108.0;

    const rightColW = 56.0;
    const padL = 16.0;
    const padR = 12.0;
    const topRowH = 22.0;
    const gapTopBottom = 8.0;
    const bottomRowH = 50.0;

    return SizedBox(
      height: cardH,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              spreadRadius: -7,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(padL, 12, padR, 12),
        child: Column(
          children: [
            SizedBox(
              height: topRowH,
              child: Row(
                children: [
                  Text(
                    'Lv. ${t.difficulty}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.lvPurple,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // _SmallIconPill(
                  //   active: t.isShared,
                  //   icon: Icons.star,
                  // ),
                  // const SizedBox(width: 8),
                  _SmallSvgPill(
                    active: t.isSkippable,
                    assetPath: 'assets/images/bac.svg',
                  ),

                  const Spacer(),

                  // ★枠はそのまま、SVGだけ小さく（14→12）
                  _TopRightBtn(
                    bg: AppColors.pillOff,
                    child: SvgPicture.asset(
                      'assets/images/menu.svg',
                      width: 10,
                      height: 10,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        AppColors.iconOff,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ★枠はそのまま、SVGだけ小さく（14→12）
                  _TopRightBtn(
                    bg: hasManual ? AppColors.modalRed : AppColors.pillOff,
                    child: SvgPicture.asset(
                      'assets/images/book.svg',
                      width: 12,
                      height: 12,
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(
                        hasManual ? Colors.white : AppColors.iconOff,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: gapTopBottom),

            SizedBox(
              height: bottomRowH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${row.displayIndex}.',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.indexBlue,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: hasDetail
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                        height: 1.05,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      detail,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.subGrey,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87,
                                      height: 1.05,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: rightColW,
                    height: double.infinity,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.border, width: 1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${t.durationMinute}分',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB0B0B0),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================
// 小さいピル（枠はそのまま、中身だけ小さく）
// ==========================
class _SmallSvgPill extends StatelessWidget {
  const _SmallSvgPill({required this.active, required this.assetPath});

  final bool active;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 枠はそのまま
      width: 28,
      height: 18,
      decoration: BoxDecoration(
        color: active ? AppColors.blue : AppColors.pillOff,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: SvgPicture.asset(
          assetPath,
          // ★中身だけ小さく（14→12）
          width: 12,
          height: 12,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            active ? Colors.white : AppColors.iconOff,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _TopRightBtn extends StatelessWidget {
  const _TopRightBtn({required this.bg, required this.child});

  final Color bg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 枠はそのまま
      width: 28,
      height: 18,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(child: child),
    );
  }
}
