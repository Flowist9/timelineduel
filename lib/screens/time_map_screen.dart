import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/persons.dart';
import '../logic/game_session.dart';
import '../models/category.dart';
import '../models/person.dart';
import '../models/person_status.dart';
import '../maps/map_tile_config.dart';

class TimeMapScreen extends StatefulWidget {
  final GameSession session;

  const TimeMapScreen({super.key, required this.session});

  @override
  State<TimeMapScreen> createState() => _TimeMapScreenState();
}

class _TimeMapScreenState extends State<TimeMapScreen> {
  double? _startYear;
  double? _endYear;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final visiblePersons = allPersons.where((p) {
      final status = widget.session.statusById[p.id];
      return status == PersonStatus.discovered ||
          status == PersonStatus.unlocked;
    }).toList();

    if (visiblePersons.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF081A34),
        appBar: AppBar(
          title: const Text('Time + Map'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'No people available for this view yet.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final minYear = visiblePersons.map((p) => p.birthYear).reduce(min);
    final maxYear = visiblePersons
        .map((p) => p.deathYear ?? DateTime.now().year)
        .reduce(max);

    if (!_initialized) {
      _startYear = minYear.toDouble();
      _endYear = maxYear.toDouble();
      _initialized = true;
    }

    _startYear = _startYear!
        .clamp(minYear.toDouble(), maxYear.toDouble())
        .toDouble();
    _endYear = _endYear!
        .clamp(minYear.toDouble(), maxYear.toDouble())
        .toDouble();
    if (_startYear! > _endYear!) {
      _startYear = minYear.toDouble();
      _endYear = maxYear.toDouble();
    }

    final filteredPersons = visiblePersons.where((p) {
      final endOfLife = (p.deathYear ?? DateTime.now().year).toDouble();
      return p.birthYear <= _endYear! && endOfLife >= _startYear!;
    }).toList()..sort((a, b) => a.birthYear.compareTo(b.birthYear));

    final markers = filteredPersons
        .where((p) => p.birthLat != null && p.birthLng != null)
        .map(
          (p) => Marker(
            point: LatLng(p.birthLat!, p.birthLng!),
            width: 110,
            height: 64,
            child: _PersonMarker(
              person: p,
              unlocked:
                  widget.session.statusById[p.id] == PersonStatus.unlocked,
              onTap: () => _showPersonSheet(context, p),
            ),
          ),
        )
        .toList();

    Widget buildMapPanel() {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xCC142C55), Color(0xE60B1730)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        padding: const EdgeInsets.all(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(20, 0),
              initialZoom: 2.3,
            ),
            children: [
              TileLayer(
                urlTemplate: MapTileConfig.standardRasterUrlTemplate,
                userAgentPackageName: MapTileConfig.userAgentPackageName,
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
      );
    }

    Widget buildListPanel() {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xCC142C55), Color(0xE60B1730)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        padding: const EdgeInsets.all(14),
        child: filteredPersons.isEmpty
            ? const Center(
                child: Text(
                  'No people in this time range.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              )
            : ListView.separated(
                itemCount: filteredPersons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final person = filteredPersons[index];
                  final unlocked =
                      widget.session.statusById[person.id] ==
                      PersonStatus.unlocked;
                  final color = _categoryColor(person.category);

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showPersonSheet(context, person),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: color.withValues(alpha: 0.38),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _categoryIcon(person.category),
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  person.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_formatYear(person.birthYear)} - ${person.deathYear == null ? 'Today' : _formatYear(person.deathYear!)}',
                            style: TextStyle(
                              color: color.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unlocked ? 'Unlocked' : 'Discovered',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Time + Map',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF081A34), Color(0xFF150A25)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF54C8FF).withValues(alpha: 0.22),
                    blurRadius: 90,
                    spreadRadius: 16,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -30,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8AAE).withValues(alpha: 0.16),
                    blurRadius: 90,
                    spreadRadius: 16,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4F8CFF),
                          Color(0xFF2FD0C7),
                          Color(0xFF07152D),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF4F8CFF,
                          ).withValues(alpha: 0.28),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                              child: const Icon(
                                Icons.travel_explore_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                              child: Text(
                                '${filteredPersons.length} aktiv',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Historical map by time window',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Choose a time range. Only people who lived in this window appear on the map.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xCC142C55), Color(0xE60B1730)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Time window',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_formatYear(_startYear!.round())} - ${_formatYear(_endYear!.round())}',
                              style: const TextStyle(
                                color: Color(0xFFD7E5FF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: RangeValues(_startYear!, _endYear!),
                          min: minYear.toDouble(),
                          max: maxYear.toDouble(),
                          labels: RangeLabels(
                            _formatYear(_startYear!.round()),
                            _formatYear(_endYear!.round()),
                          ),
                          onChanged: (values) {
                            setState(() {
                              _startYear = values.start;
                              _endYear = values.end;
                            });
                          },
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _InfoPill(
                              icon: Icons.people_alt_rounded,
                              label:
                                  '${filteredPersons.length} Personen im Fenster',
                            ),
                            _InfoPill(
                              icon: Icons.place_rounded,
                              label: '${markers.length} Marker sichtbar',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final vertical = constraints.maxWidth < 900;

                        if (vertical) {
                          return Column(
                            children: [
                              Expanded(flex: 6, child: buildMapPanel()),
                              const SizedBox(height: 16),
                              Expanded(flex: 5, child: buildListPanel()),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(flex: 7, child: buildMapPanel()),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: buildListPanel()),
                          ],
                        );
                      },
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

  void _showPersonSheet(BuildContext context, Person person) {
    final status = widget.session.statusById[person.id];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF102242),
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                person.hint,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Lifespan: ${_formatYear(person.birthYear)} - ${person.deathYear == null ? 'Today' : _formatYear(person.deathYear!)}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${status?.name ?? 'unbekannt'}',
                style: const TextStyle(color: Colors.white),
              ),
              if (person.birthPlaceLabel != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Place: ${person.birthPlaceLabel}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatYear(int year) {
    if (year < 0) return '${-year} v. Chr.';
    return '$year';
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

  IconData _categoryIcon(Category category) {
    switch (category) {
      case Category.politician:
        return Icons.account_balance_rounded;
      case Category.scientist:
        return Icons.biotech_rounded;
      case Category.artist:
        return Icons.palette_rounded;
      case Category.athlete:
        return Icons.emoji_events_rounded;
    }
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonMarker extends StatelessWidget {
  final Person person;
  final bool unlocked;
  final VoidCallback onTap;

  const _PersonMarker({
    required this.person,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (person.category) {
      Category.politician => const Color(0xFFFF7A59),
      Category.scientist => const Color(0xFF53B8FF),
      Category.artist => const Color(0xFFFF6EC7),
      Category.athlete => const Color(0xFF45D29E),
    };

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xE6112648),
              border: Border.all(color: color.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              person.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unlocked
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.82),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(Icons.location_on_rounded, size: 34, color: color),
        ],
      ),
    );
  }
}
