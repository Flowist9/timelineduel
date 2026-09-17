import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../battle/battle_targets.dart';
import '../maps/map_tile_config.dart';

class BattleDateGuessPanel extends StatelessWidget {
  final List<int> digits;
  final DateTime? guessedDate;
  final void Function(int index, int value) onDigitChanged;
  final String invalidHint;
  final String validHint;
  final String dayLabel;
  final String monthLabel;
  final String yearLabel;

  const BattleDateGuessPanel({
    super.key,
    required this.digits,
    required this.guessedDate,
    required this.onDigitChanged,
    this.invalidHint = 'Set a valid date',
    this.validHint = 'Day . Month . Year',
    this.dayLabel = 'Day',
    this.monthLabel = 'Month',
    this.yearLabel = 'Year',
  });

  @override
  Widget build(BuildContext context) {
    final compactMobile = MediaQuery.sizeOf(context).width < 430;
    final headline = guessedDate == null
        ? '--.--.----'
        : formatBattleEventDateCompact(guessedDate!);

    Widget buildGroup(String label, int start, int length) {
      return Expanded(
        flex: length,
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFFD8CBB8).withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
                fontSize: compactMobile ? 10 : 11,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: List.generate(length, (offset) {
                  final index = start + offset;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _BattleGuessDigitWheel(
                        value: digits[index],
                        onChanged: (value) => onDigitChanged(index, value),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compactMobile ? 12 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compactMobile ? 20 : 28),
        color: Colors.black.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            headline,
            style: TextStyle(
              color: const Color(0xFFF7ECDD),
              fontWeight: FontWeight.w900,
              fontSize: compactMobile ? 26 : 36,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            guessedDate == null ? invalidHint : validHint,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compactMobile ? 12 : 18),
          Expanded(
            child: Row(
              children: [
                buildGroup(dayLabel, 0, 2),
                const SizedBox(width: 8),
                buildGroup(monthLabel, 2, 2),
                const SizedBox(width: 8),
                buildGroup(yearLabel, 4, 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BattleMapGuessPanel extends StatelessWidget {
  final LatLng? selectedPoint;
  final ValueChanged<LatLng> onTap;
  final String emptyHint;
  final String Function(LatLng point)? selectedHintBuilder;

  const BattleMapGuessPanel({
    super.key,
    required this.selectedPoint,
    required this.onTap,
    this.emptyHint = 'Tap the historical location on a borders-only map',
    this.selectedHintBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final compactMobile = MediaQuery.sizeOf(context).width < 430;
    final selectedHint = selectedPoint == null
        ? emptyHint
        : (selectedHintBuilder?.call(selectedPoint!) ??
              'Guess set: ${selectedPoint!.latitude.toStringAsFixed(1)}, ${selectedPoint!.longitude.toStringAsFixed(1)}');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compactMobile ? 10 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compactMobile ? 20 : 28),
        color: Colors.black.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedHint,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.90),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(compactMobile ? 18 : 22),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(18, 8),
                  initialZoom: 1.45,
                  minZoom: 1.2,
                  maxZoom: 6.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onTap: (_, point) => onTap(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapTileConfig.mysteryNoLabelsUrlTemplate,
                    subdomains: MapTileConfig.mysterySubdomains,
                    userAgentPackageName: MapTileConfig.userAgentPackageName,
                  ),
                  if (selectedPoint != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedPoint!,
                          width: 42,
                          height: 42,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFD4B06A),
                              border: Border.all(
                                color: const Color(0xFF1B100A),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.place_rounded,
                              color: Color(0xFF1B100A),
                            ),
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
    );
  }
}

class _BattleGuessDigitWheel extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _BattleGuessDigitWheel({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final controller = FixedExtentScrollController(initialItem: value);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: const Color(0xFFD4B06A).withValues(alpha: 0.18),
        ),
      ),
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 46,
        physics: const FixedExtentScrollPhysics(),
        perspective: 0.0025,
        diameterRatio: 1.4,
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: 10,
          builder: (context, index) {
            return Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: index == value
                      ? const Color(0xFFF7ECDD)
                      : const Color(0xFFD8CBB8).withValues(alpha: 0.58),
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
