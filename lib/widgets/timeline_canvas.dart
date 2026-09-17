import 'dart:math';

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/person.dart';
import '../models/person_status.dart';
import 'person_portrait.dart';

class TimelineCanvas extends StatefulWidget {
  final List<Person> persons;
  final Map<String, PersonStatus> statusById;
  final double pixelsPerYear;
  final ValueChanged<Person>? onPersonTap;

  const TimelineCanvas({
    super.key,
    required this.persons,
    required this.statusById,
    required this.pixelsPerYear,
    this.onPersonTap,
  });

  @override
  State<TimelineCanvas> createState() => _TimelineCanvasState();
}

class _TimelineCanvasState extends State<TimelineCanvas> {
  final ScrollController _controller = ScrollController();
  double _scrollOffset = 0;
  double _viewportHeight = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _scrollOffset = _controller.offset);
    });
  }

  @override
  void didUpdateWidget(covariant TimelineCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pixelsPerYear == widget.pixelsPerYear ||
        !_controller.hasClients) {
      return;
    }

    final oldMetrics = _buildMetrics(
      oldWidget.persons,
      oldWidget.pixelsPerYear,
    );
    final newMetrics = _buildMetrics(widget.persons, widget.pixelsPerYear);
    if (oldMetrics == null || newMetrics == null || _viewportHeight <= 0) {
      return;
    }

    final centerY = _controller.offset + (_viewportHeight / 2);
    final anchor = _anchorForPosition(centerY, oldMetrics);
    final desiredCenterY = _positionForAnchor(anchor, newMetrics);
    final targetOffset = (desiredCenterY - (_viewportHeight / 2))
        .clamp(0.0, max(0.0, newMetrics.totalHeight - _viewportHeight))
        .toDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      _controller.jumpTo(targetOffset);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.persons.isEmpty) {
      return Container(
        color: const Color(0xFF09152A),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore_outlined, color: Color(0xFF6EE7F9), size: 42),
              SizedBox(height: 14),
              Text(
                'Noch keine Entdeckungen auf dem Zeitstrahl',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = [...widget.persons]
      ..sort((a, b) {
        final ad = _effectiveBirthDateOrNull(a);
        final bd = _effectiveBirthDateOrNull(b);
        if (ad != null && bd != null) return ad.compareTo(bd);
        return a.birthYear.compareTo(b.birthYear);
      });

    final minYear = sorted.map((p) => p.birthYear).reduce(min);
    final maxYear = sorted.map((p) => p.birthYear).reduce(max);

    final latestDate = sorted
        .map(_effectiveBirthDateOrNull)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (acc, d) => acc == null ? d : (d.isAfter(acc) ? d : acc),
        );

    const dayModeThreshold = 12.0;
    final dayMode = widget.pixelsPerYear >= dayModeThreshold;
    final pixelsPerDay = dayMode
        ? (widget.pixelsPerYear / dayModeThreshold)
        : 0.0;

    const splitYear = 1400;
    final splitDate = DateTime(splitYear, 1, 1);

    const paddingTop = 120.0;
    const paddingBottom = 200.0;

    double preHeight;
    if (splitYear <= minYear) {
      preHeight = 0;
    } else {
      final preEndYear = min(splitYear, maxYear);
      preHeight = (preEndYear - minYear) * widget.pixelsPerYear;
    }

    double modernHeight = 0;
    if (dayMode && latestDate != null && latestDate.isAfter(splitDate)) {
      modernHeight = latestDate.difference(splitDate).inDays * pixelsPerDay;
    } else if (maxYear > splitYear) {
      modernHeight = (maxYear - max(splitYear, minYear)) * widget.pixelsPerYear;
    }

    final totalHeight = paddingTop + preHeight + modernHeight + paddingBottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = constraints.maxHeight;
        const outerPadding = 14.0;
        final lineX = max(170.0, constraints.maxWidth * 0.46);
        final visibleTop = _scrollOffset;
        final visibleBottom = _scrollOffset + constraints.maxHeight;

        return Container(
          color: const Color(0xFF09152A),
          child: SingleChildScrollView(
            controller: _controller,
            child: SizedBox(
              height: totalHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TimelinePainter(
                        persons: sorted,
                        statusById: widget.statusById,
                        minYear: minYear,
                        pixelsPerYear: widget.pixelsPerYear,
                        dayMode: dayMode,
                        pixelsPerDay: pixelsPerDay,
                        splitYear: splitYear,
                        splitDate: splitDate,
                        paddingTop: paddingTop,
                        preHeight: preHeight,
                        scrollOffset: _scrollOffset,
                        viewportHeight: constraints.maxHeight,
                      ),
                    ),
                  ),
                  ..._buildPersonWidgets(
                    persons: sorted,
                    width: constraints.maxWidth,
                    lineX: lineX,
                    visibleTop: visibleTop,
                    visibleBottom: visibleBottom,
                    minYear: minYear,
                    dayMode: dayMode,
                    pixelsPerDay: pixelsPerDay,
                    splitYear: splitYear,
                    splitDate: splitDate,
                    paddingTop: paddingTop,
                    preHeight: preHeight,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _TimelineMetrics? _buildMetrics(List<Person> persons, double pixelsPerYear) {
    if (persons.isEmpty) return null;

    final sorted = [...persons]
      ..sort((a, b) {
        final ad = _effectiveBirthDateOrNull(a);
        final bd = _effectiveBirthDateOrNull(b);
        if (ad != null && bd != null) return ad.compareTo(bd);
        return a.birthYear.compareTo(b.birthYear);
      });

    final minYear = sorted.map((p) => p.birthYear).reduce(min);
    final maxYear = sorted.map((p) => p.birthYear).reduce(max);
    final latestDate = sorted
        .map(_effectiveBirthDateOrNull)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (acc, d) => acc == null ? d : (d.isAfter(acc) ? d : acc),
        );

    const dayModeThreshold = 12.0;
    final dayMode = pixelsPerYear >= dayModeThreshold;
    final pixelsPerDay = dayMode ? (pixelsPerYear / dayModeThreshold) : 0.0;
    const splitYear = 1400;
    final splitDate = DateTime(splitYear, 1, 1);
    const paddingTop = 120.0;
    const paddingBottom = 200.0;

    double preHeight;
    if (splitYear <= minYear) {
      preHeight = 0;
    } else {
      final preEndYear = min(splitYear, maxYear);
      preHeight = (preEndYear - minYear) * pixelsPerYear;
    }

    double modernHeight = 0;
    if (dayMode && latestDate != null && latestDate.isAfter(splitDate)) {
      modernHeight = latestDate.difference(splitDate).inDays * pixelsPerDay;
    } else if (maxYear > splitYear) {
      modernHeight = (maxYear - max(splitYear, minYear)) * pixelsPerYear;
    }

    final totalHeight = paddingTop + preHeight + modernHeight + paddingBottom;

    return _TimelineMetrics(
      minYear: minYear,
      maxYear: maxYear,
      pixelsPerYear: pixelsPerYear,
      dayMode: dayMode,
      pixelsPerDay: pixelsPerDay,
      splitYear: splitYear,
      splitDate: splitDate,
      paddingTop: paddingTop,
      preHeight: preHeight,
      totalHeight: totalHeight,
    );
  }

  _TimelineAnchor _anchorForPosition(double y, _TimelineMetrics metrics) {
    final contentY = y - metrics.paddingTop;
    if (!metrics.dayMode || contentY <= metrics.preHeight) {
      final year = metrics.minYear + (contentY / metrics.pixelsPerYear);
      return _TimelineAnchor.year(year);
    }

    final days = (contentY - metrics.preHeight) / metrics.pixelsPerDay;
    return _TimelineAnchor.day(
      metrics.splitDate.add(Duration(days: days.round())),
    );
  }

  double _positionForAnchor(_TimelineAnchor anchor, _TimelineMetrics metrics) {
    return switch (anchor) {
      _TimelineAnchor(kind: _TimelineAnchorKind.year, :final year) =>
        !metrics.dayMode || year! < metrics.splitYear
            ? metrics.paddingTop +
                  ((year! - metrics.minYear) * metrics.pixelsPerYear)
            : metrics.paddingTop +
                  metrics.preHeight +
                  (DateTime(
                        year.round(),
                        7,
                        1,
                      ).difference(metrics.splitDate).inDays *
                      metrics.pixelsPerDay),
      _TimelineAnchor(kind: _TimelineAnchorKind.day, :final date) =>
        !metrics.dayMode || date!.isBefore(metrics.splitDate)
            ? metrics.paddingTop +
                  ((date!.year.toDouble() - metrics.minYear) *
                      metrics.pixelsPerYear)
            : metrics.paddingTop +
                  metrics.preHeight +
                  (date.difference(metrics.splitDate).inDays *
                      metrics.pixelsPerDay),
    };
  }

  List<Widget> _buildPersonWidgets({
    required List<Person> persons,
    required double width,
    required double lineX,
    required double visibleTop,
    required double visibleBottom,
    required int minYear,
    required bool dayMode,
    required double pixelsPerDay,
    required int splitYear,
    required DateTime splitDate,
    required double paddingTop,
    required double preHeight,
  }) {
    final widgets = <Widget>[];
    const cardGap = 22.0;
    const outerPadding = 14.0;
    final leftCardWidth = max(132.0, lineX - cardGap - outerPadding);
    final rightCardWidth = max(140.0, width - lineX - cardGap - outerPadding);

    for (int i = 0; i < persons.length; i++) {
      final person = persons[i];
      final status = widget.statusById[person.id] ?? PersonStatus.undiscovered;
      if (status == PersonStatus.undiscovered) continue;

      final y = _yForBirth(
        person,
        minYear: minYear,
        dayMode: dayMode,
        pixelsPerDay: pixelsPerDay,
        splitYear: splitYear,
        splitDate: splitDate,
        paddingTop: paddingTop,
        preHeight: preHeight,
      );
      if (y < visibleTop - 140 || y > visibleBottom + 140) continue;

      final accent = _categoryColor(person.category);
      final isUnlocked = status == PersonStatus.unlocked;
      final cardOnLeft = i.isEven;
      final cardWidth = cardOnLeft ? leftCardWidth : rightCardWidth;
      final cardHeight = 72.0;
      final dotRadius = isUnlocked ? 8.0 : 6.0;
      final connectorLeft = cardOnLeft ? lineX - cardGap : lineX;
      final cardLeft = cardOnLeft
          ? max(outerPadding, lineX - cardGap - cardWidth)
          : min(width - outerPadding - cardWidth, lineX + cardGap);

      widgets.add(
        Positioned(
          left: connectorLeft,
          top: y - 1,
          width: 22,
          height: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isUnlocked ? 0.80 : 0.42),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      );

      widgets.add(
        Positioned(
          left: lineX - (dotRadius + 5),
          top: y - (dotRadius + 5),
          width: (dotRadius + 5) * 2,
          height: (dotRadius + 5) * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? accent : const Color(0xFFB4C1D7),
              boxShadow: [
                BoxShadow(
                  color: (isUnlocked ? accent : const Color(0xFFB4C1D7))
                      .withValues(alpha: 0.28),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );

      widgets.add(
        Positioned(
          left: cardLeft,
          top: y - cardHeight / 2,
          width: cardWidth,
          height: cardHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPersonTap == null
                ? null
                : () => widget.onPersonTap!(person),
            child: _TimelinePersonCard(
              person: person,
              accent: accent,
              unlocked: isUnlocked,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  double _yForBirth(
    Person person, {
    required int minYear,
    required bool dayMode,
    required double pixelsPerDay,
    required int splitYear,
    required DateTime splitDate,
    required double paddingTop,
    required double preHeight,
  }) {
    if (!dayMode || person.birthYear < splitYear) {
      return paddingTop + (person.birthYear - minYear) * widget.pixelsPerYear;
    }

    final date = person.birthDate ?? DateTime(person.birthYear, 7, 1);
    final days = date.difference(splitDate).inDays;
    return paddingTop + preHeight + (days * pixelsPerDay);
  }

  DateTime? _effectiveBirthDateOrNull(Person p) {
    if (p.birthYear < 1400) return null;
    return p.birthDate ?? DateTime(p.birthYear, 7, 1);
  }

  Color _categoryColor(Category category) {
    switch (category) {
      case Category.politician:
        return const Color(0xFFFF7A59);
      case Category.scientist:
        return const Color(0xFF53B8FF);
      case Category.artist:
        return const Color(0xFFFF6EC7);
      case Category.athlete:
        return const Color(0xFF45D29E);
    }
  }
}

enum _TimelineAnchorKind { year, day }

class _TimelineAnchor {
  final _TimelineAnchorKind kind;
  final double? year;
  final DateTime? date;

  const _TimelineAnchor.year(this.year)
    : kind = _TimelineAnchorKind.year,
      date = null;

  const _TimelineAnchor.day(this.date)
    : kind = _TimelineAnchorKind.day,
      year = null;
}

class _TimelineMetrics {
  final int minYear;
  final int maxYear;
  final double pixelsPerYear;
  final bool dayMode;
  final double pixelsPerDay;
  final int splitYear;
  final DateTime splitDate;
  final double paddingTop;
  final double preHeight;
  final double totalHeight;

  const _TimelineMetrics({
    required this.minYear,
    required this.maxYear,
    required this.pixelsPerYear,
    required this.dayMode,
    required this.pixelsPerDay,
    required this.splitYear,
    required this.splitDate,
    required this.paddingTop,
    required this.preHeight,
    required this.totalHeight,
  });
}

class TimelinePainter extends CustomPainter {
  final List<Person> persons;
  final Map<String, PersonStatus> statusById;
  final int minYear;
  final double pixelsPerYear;
  final bool dayMode;
  final double pixelsPerDay;
  final int splitYear;
  final DateTime splitDate;
  final double paddingTop;
  final double preHeight;
  final double scrollOffset;
  final double viewportHeight;

  TimelinePainter({
    required this.persons,
    required this.statusById,
    required this.minYear,
    required this.pixelsPerYear,
    required this.dayMode,
    required this.pixelsPerDay,
    required this.splitYear,
    required this.splitDate,
    required this.paddingTop,
    required this.preHeight,
    required this.scrollOffset,
    required this.viewportHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final visibleTop = scrollOffset;
    final visibleBottom = scrollOffset + viewportHeight;
    final lineX = max(150.0, size.width * 0.43);

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6EE7F9), Color(0xFFFFCF70), Color(0xFFFF8AAE)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(lineX - 2, visibleTop, 4, viewportHeight))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF56CCF2).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    canvas.drawLine(
      Offset(lineX, visibleTop),
      Offset(lineX, visibleBottom),
      glowPaint,
    );
    canvas.drawLine(
      Offset(lineX, visibleTop),
      Offset(lineX, visibleBottom),
      linePaint,
    );

    _drawTicks(canvas, size, lineX, visibleTop, visibleBottom);
    _drawEraMarker(canvas, size, lineX);
  }

  void _drawEraMarker(Canvas canvas, Size size, double lineX) {
    final y = paddingTop + (splitYear - minYear) * pixelsPerYear;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(lineX - 54, y - 16, 108, 32),
      const Radius.circular(16),
    );

    final fill = Paint()..color = const Color(0xCC0F2345);
    final border = Paint()
      ..color = const Color(0x66FFCF70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, border);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(
      text: '1400+ Detail',
      style: TextStyle(
        color: Color(0xFFFFCF70),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(lineX - tp.width / 2, y - tp.height / 2));
  }

  void _drawTicks(
    Canvas canvas,
    Size size,
    double lineX,
    double visibleTop,
    double visibleBottom,
  ) {
    if (!dayMode) {
      _drawYearTicks(
        canvas,
        lineX,
        visibleTop,
        visibleBottom,
        pixelsPerYear < 2
            ? 200
            : pixelsPerYear < 4
            ? 100
            : pixelsPerYear < 8
            ? 50
            : 25,
      );
    } else {
      _drawYearTicks(
        canvas,
        lineX,
        visibleTop,
        visibleBottom,
        100,
        maxYear: splitYear,
      );
      _drawModernTicks(canvas, lineX, visibleTop, visibleBottom);
    }
  }

  void _drawYearTicks(
    Canvas canvas,
    double lineX,
    double visibleTop,
    double visibleBottom,
    int tickStepYears, {
    int? maxYear,
  }) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final tickPaint = Paint()..color = const Color(0x33FFFFFF);
    final guidePaint = Paint()..color = const Color(0x10FFFFFF);

    final minVisibleYear =
        minYear + ((visibleTop - paddingTop) / pixelsPerYear).floor();
    final maxVisibleYear =
        minYear + ((visibleBottom - paddingTop) / pixelsPerYear).ceil();
    final capMax = maxYear == null
        ? maxVisibleYear
        : min(maxVisibleYear, maxYear);

    int start = (minVisibleYear / tickStepYears).floor() * tickStepYears;
    for (int year = start; year <= capMax; year += tickStepYears) {
      final y = paddingTop + (year - minYear) * pixelsPerYear;
      if (y < visibleTop - 30 || y > visibleBottom + 30) continue;

      canvas.drawLine(Offset(0, y), Offset(lineX - 16, y), guidePaint);
      canvas.drawLine(Offset(lineX - 12, y), Offset(lineX, y), tickPaint);

      textPainter.text = TextSpan(
        text: _formatYear(year),
        style: const TextStyle(
          color: Color(0xFF8EA6C8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout(maxWidth: lineX - 24);
      textPainter.paint(canvas, Offset(12, y - 7));
    }
  }

  void _drawModernTicks(
    Canvas canvas,
    double lineX,
    double visibleTop,
    double visibleBottom,
  ) {
    final monthTickPaint = Paint()..color = const Color(0x33FFFFFF);
    final dayTickPaint = Paint()..color = const Color(0x18FFFFFF);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final dayStep = pixelsPerDay >= 3.0 ? 1 : (pixelsPerDay >= 2.0 ? 3 : 7);
    final visibleModernTop = max(0.0, visibleTop - (paddingTop + preHeight));
    final visibleModernBottom = max(
      0.0,
      visibleBottom - (paddingTop + preHeight),
    );

    final startDay = (visibleModernTop / pixelsPerDay).floor();
    final endDay = (visibleModernBottom / pixelsPerDay).ceil();
    final startDate = splitDate.add(Duration(days: startDay));
    final endDate = splitDate.add(Duration(days: endDay));

    DateTime month = DateTime(startDate.year, startDate.month, 1);
    if (month.isBefore(splitDate)) month = splitDate;

    while (!month.isAfter(endDate)) {
      final daysFromSplit = month.difference(splitDate).inDays;
      final y = paddingTop + preHeight + (daysFromSplit * pixelsPerDay);
      if (y >= visibleTop - 30 && y <= visibleBottom + 30) {
        canvas.drawLine(
          Offset(0, y),
          Offset(lineX - 18, y),
          Paint()..color = const Color(0x10FFFFFF),
        );
        canvas.drawLine(
          Offset(lineX - 14, y),
          Offset(lineX, y),
          monthTickPaint,
        );
        textPainter.text = TextSpan(
          text: _monthLabel(month),
          style: const TextStyle(
            color: Color(0xFF8EA6C8),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        );
        textPainter.layout(maxWidth: lineX - 24);
        textPainter.paint(canvas, Offset(12, y - 7));
      }
      month = DateTime(month.year, month.month + 1, 1);
    }

    int start = startDay - (startDay % dayStep);
    for (int day = start; day <= endDay; day += dayStep) {
      final y = paddingTop + preHeight + (day * pixelsPerDay);
      if (y < visibleTop - 12 || y > visibleBottom + 12) continue;
      canvas.drawLine(Offset(lineX - 6, y), Offset(lineX, y), dayTickPaint);
    }
  }

  String _monthLabel(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _formatYear(int year) {
    if (year < 0) return '${-year} BC';
    return year.toString();
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.pixelsPerYear != pixelsPerYear ||
        oldDelegate.dayMode != dayMode ||
        oldDelegate.pixelsPerDay != pixelsPerDay ||
        oldDelegate.persons != persons ||
        oldDelegate.statusById != statusById;
  }
}

class _TimelinePersonCard extends StatelessWidget {
  final Person person;
  final Color accent;
  final bool unlocked;

  const _TimelinePersonCard({
    required this.person,
    required this.accent,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: unlocked ? const Color(0xE6142C55) : const Color(0xCC1A2944),
        border: Border.all(
          color: accent.withValues(alpha: unlocked ? 0.55 : 0.26),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          PersonPortrait(
            person: person,
            width: 44,
            height: 56,
            borderRadius: 14,
            obscured: !unlocked,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unlocked ? person.name : '???',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: unlocked ? 0.96 : 0.88,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  unlocked ? _formatYear(person.birthYear) : '???',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.94),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accent.withValues(alpha: 0.90),
            ),
            child: Text(
              _categoryShort(person.category),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryShort(Category category) {
    switch (category) {
      case Category.politician:
        return 'POL';
      case Category.scientist:
        return 'SCI';
      case Category.artist:
        return 'ART';
      case Category.athlete:
        return 'SPT';
    }
  }

  String _formatYear(int year) {
    if (year < 0) return '${-year} BC';
    return year.toString();
  }
}
