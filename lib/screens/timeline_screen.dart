import 'package:flutter/material.dart';

import '../data/persons.dart';
import '../logic/game_session.dart';
import '../models/person.dart';
import '../models/person_status.dart';
import '../widgets/person_archive_card_dialog.dart';
import '../widgets/timeline_canvas.dart';

class TimelineScreen extends StatefulWidget {
  final GameSession session;

  const TimelineScreen({super.key, required this.session});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  double _pixelsPerYear = 3.0;

  @override
  Widget build(BuildContext context) {
    final visiblePersons = allPersons.where((person) {
      final status = widget.session.statusById[person.id];
      return status == PersonStatus.discovered ||
          status == PersonStatus.unlocked;
    }).toList()..sort((a, b) => a.birthYear.compareTo(b.birthYear));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFF8F0E3),
        elevation: 0,
        title: const Text(
          'Timeline',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildToolbar(visiblePersons.length),
                  const SizedBox(height: 12),
                  _buildZoomPanel(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildPanel(
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: TimelineCanvas(
                          persons: visiblePersons,
                          statusById: widget.session.statusById,
                          pixelsPerYear: _pixelsPerYear,
                          onPersonTap: (person) =>
                              _showPersonSheet(context, person),
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
          const Icon(
            Icons.timeline_rounded,
            color: Color(0xFFD4B06A),
            size: 22,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Timeline',
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

  Widget _buildZoomPanel() {
    return _buildPanel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Zoom',
                style: TextStyle(
                  color: Color(0xFFF8F0E3),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                _pixelsPerYear.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFFE8DCCB),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(
            value: _pixelsPerYear,
            min: 1,
            max: 20,
            activeColor: const Color(0xFFD4B06A),
            onChanged: (value) => setState(() => _pixelsPerYear = value),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
    );
  }

  Widget _buildPanel(Widget child, {EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xCC4C3929), Color(0xE62A1B12)],
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
    showPersonArchiveCardDialog(
      context: context,
      person: person,
      status: status ?? PersonStatus.undiscovered,
    );
  }
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
