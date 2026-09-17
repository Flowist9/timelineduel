import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/persons.dart';
import '../logic/game_session.dart';
import '../maps/map_tile_config.dart';
import '../models/category.dart';
import '../models/person.dart';
import '../models/person_status.dart';
import '../widgets/person_archive_card_dialog.dart';
import '../widgets/person_portrait.dart';

class MapScreen extends StatefulWidget {
  final GameSession session;

  const MapScreen({super.key, required this.session});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  RangeValues? _yearRange;

  @override
  Widget build(BuildContext context) {
    final visiblePersons = allPersons.where((person) {
      final status = widget.session.statusById[person.id];
      return status == PersonStatus.discovered ||
          status == PersonStatus.unlocked;
    }).toList();

    final minYear = visiblePersons.isEmpty
        ? 0
        : visiblePersons
              .map((person) => person.birthYear)
              .reduce((a, b) => a < b ? a : b);
    final maxYear = visiblePersons.isEmpty
        ? 1
        : visiblePersons
              .map((person) => person.birthYear)
              .reduce((a, b) => a > b ? a : b);

    final clampedRange = _clampRange(
      _yearRange ?? RangeValues(minYear.toDouble(), maxYear.toDouble()),
      minYear.toDouble(),
      maxYear.toDouble(),
    );
    _yearRange = clampedRange;

    final filteredPersons = visiblePersons.where((person) {
      return person.birthYear >= clampedRange.start.round() &&
          person.birthYear <= clampedRange.end.round();
    }).toList();

    final markers = filteredPersons
        .where((person) => person.birthLat != null && person.birthLng != null)
        .map(
          (person) => Marker(
            point: LatLng(person.birthLat!, person.birthLng!),
            width: 62,
            height: 76,
            child: _MapPersonMarker(
              person: person,
              session: widget.session,
              onTap: () => _showPersonSheet(context, person),
            ),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFF8F0E3),
        elevation: 0,
        title: const Text('Map', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C2017), Color(0xFF140E0A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildToolbar(filteredPersons.length),
                  const SizedBox(height: 12),
                  _buildYearRangeBar(
                    minYear: minYear,
                    maxYear: maxYear,
                    values: clampedRange,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildPanel(
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: FlutterMap(
                          options: const MapOptions(
                            initialCenter: LatLng(20, 0),
                            initialZoom: 2.3,
                            interactionOptions: InteractionOptions(
                              flags:
                                  InteractiveFlag.all & ~InteractiveFlag.rotate,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  MapTileConfig.standardRasterUrlTemplate,
                              userAgentPackageName:
                                  MapTileConfig.userAgentPackageName,
                            ),
                            MarkerLayer(markers: markers),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(int visibleCount) {
    return _buildPanel(
      Row(
        children: [
          const Icon(Icons.public_rounded, color: Color(0xFFD4B06A), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'World Map',
              style: TextStyle(
                color: Color(0xFFF8F0E3),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          _Pill(label: '$visibleCount visible'),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    );
  }

  Widget _buildYearRangeBar({
    required int minYear,
    required int maxYear,
    required RangeValues values,
  }) {
    return _buildPanel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: Color(0xFFD4B06A),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Time window',
                  style: TextStyle(
                    color: Color(0xFFF8F0E3),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              _Pill(
                label:
                    '${_formatYear(values.start.round())} - ${_formatYear(values.end.round())}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFD4B06A),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
              thumbColor: const Color(0xFFD4B06A),
              overlayColor: const Color(0xFFD4B06A).withValues(alpha: 0.12),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10,
              ),
              trackHeight: 4,
            ),
            child: RangeSlider(
              values: values,
              min: minYear.toDouble(),
              max: maxYear.toDouble(),
              divisions: (maxYear - minYear).clamp(1, 4000),
              labels: RangeLabels(
                _formatYear(values.start.round()),
                _formatYear(values.end.round()),
              ),
              onChanged: (next) {
                setState(() {
                  _yearRange = next;
                });
              },
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
    );
  }

  Widget _buildPanel(Widget child, {EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A3323), Color(0xFF2B1C13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFF1E2CB).withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  void _showPersonSheet(BuildContext context, Person person) {
    final status = widget.session.statusById[person.id];
    if (status == null) return;
    showPersonArchiveCardDialog(
      context: context,
      person: person,
      status: status,
    );
  }

  RangeValues _clampRange(RangeValues values, double min, double max) {
    final start = values.start.clamp(min, max).toDouble();
    final end = values.end.clamp(min, max).toDouble();
    if (start > end) {
      return RangeValues(min, max);
    }
    return RangeValues(start, end);
  }

  String _formatYear(int year) => year < 0 ? '${year.abs()} BC' : '$year';
}

class _MapPersonMarker extends StatelessWidget {
  final Person person;
  final GameSession session;
  final VoidCallback onTap;

  const _MapPersonMarker({
    required this.person,
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = session.statusById[person.id];
    final unlocked = status == PersonStatus.unlocked;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2B1C13),
              border: Border.all(
                color: _categoryColor(person.category).withValues(alpha: 0.95),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: PersonPortrait(
                person: person,
                width: 48,
                height: 48,
                borderRadius: 24,
                obscured: !unlocked,
              ),
            ),
          ),
          Container(
            width: 2,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: _categoryColor(person.category).withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(Category category) => switch (category) {
    Category.politician => const Color(0xFF9B6A43),
    Category.scientist => const Color(0xFF8D7858),
    Category.artist => const Color(0xFFB07A54),
    Category.athlete => const Color(0xFF6F6A45),
  };
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF1E2CB).withValues(alpha: 0.10),
        border: Border.all(
          color: const Color(0xFFF1E2CB).withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFF8F0E3),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
