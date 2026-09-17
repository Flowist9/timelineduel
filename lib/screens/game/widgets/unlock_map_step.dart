import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/person.dart';
import 'unlock_birth_year_step.dart';

class UnlockMapStep extends StatelessWidget {
  final Person person;
  final Color color;
  final LatLng? mapGuess;
  final double? mapKm;
  final bool mapDone;
  final bool mapWasCorrect;
  final bool mapRevealTarget;
  final int mapAttempts;
  final VoidCallback onSkip;
  final VoidCallback onConfirm;
  final void Function(LatLng latLng) onTapMap;
  final UnlockHeaderBuilder headerBuilder;
  final UnlockPanelBuilder panelBuilder;

  const UnlockMapStep({
    super.key,
    required this.person,
    required this.color,
    required this.mapGuess,
    required this.mapKm,
    required this.mapDone,
    required this.mapWasCorrect,
    required this.mapRevealTarget,
    required this.mapAttempts,
    required this.onSkip,
    required this.onConfirm,
    required this.onTapMap,
    required this.headerBuilder,
    required this.panelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (person.birthLat == null || person.birthLng == null) {
      return Column(
        children: [
          headerBuilder(
            person,
            'Map step unavailable',
            'There are no coordinates stored for this person yet. You can skip this step.',
          ),
          const SizedBox(height: 18),
          panelBuilder(
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSkip,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: const Color(0xFFF8F0E3),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Skip step'),
              ),
            ),
          ),
        ],
      );
    }

    final target = LatLng(person.birthLat!, person.birthLng!);
    final markers = <Marker>[
      if (mapGuess != null)
        Marker(
          point: mapGuess!,
          width: 44,
          height: 44,
          child: const Icon(Icons.location_on, size: 40),
        ),
      if (mapRevealTarget)
        Marker(
          point: target,
          width: 44,
          height: 44,
          child: const Icon(Icons.flag, size: 34),
        ),
    ];

    return Column(
      children: [
        headerBuilder(
          person,
          'Where was this person born?',
          'Tap the map. The target radius depends on your active boosts.',
        ),
        const SizedBox(height: 18),
        panelBuilder(
          Column(
            children: [
              Container(
                height: 420,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFF1E2CB).withValues(alpha: 0.14),
                  ),
                ),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: const LatLng(20, 0),
                        initialZoom: 2.4,
                        onTap: (tapPosition, latLng) => onTapMap(latLng),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.timelineduel.app',
                        ),
                        if (mapRevealTarget && mapGuess != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [mapGuess!, target],
                                strokeWidth: 4,
                                color: const Color(0xFFD4B06A),
                              ),
                            ],
                          ),
                        MarkerLayer(markers: markers),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC07152D),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'Place a marker on the birthplace.',
                          style: TextStyle(
                            color: Color(0xFFF8F0E3),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Attempts: $mapAttempts/3',
                style: const TextStyle(
                  color: Color(0xFFF8F0E3),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (mapKm != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last guess: ${mapKm!.round()} km away',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFE8DCCB)),
                ),
              ],
              if (mapDone) ...[
                const SizedBox(height: 8),
                Text(
                  'Target: ${person.birthPlaceLabel ?? 'unknown'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFE8DCCB)),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: onConfirm,
                  child: Text(mapWasCorrect ? 'Continue' : 'Got it, continue'),
                ),
              ],
            ],
          ),
          padding: const EdgeInsets.all(14),
        ),
      ],
    );
  }
}
