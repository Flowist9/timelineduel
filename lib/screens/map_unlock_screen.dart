import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../logic/game_session.dart';
import '../models/person.dart';
import '../maps/map_tile_config.dart';

class MapUnlockScreen extends StatefulWidget {
  final GameSession session;
  final Person person;
  final double radiusKm;

  const MapUnlockScreen({
    super.key,
    required this.session,
    required this.person,
    this.radiusKm = 300,
  });

  @override
  State<MapUnlockScreen> createState() => _MapUnlockScreenState();
}

class _MapUnlockScreenState extends State<MapUnlockScreen> {
  LatLng? _guess;
  double? _km;
  bool _done = false;

  final _distance = const Distance();

  @override
  Widget build(BuildContext context) {
    final p = widget.person;

    if (p.birthLat == null || p.birthLng == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Map-Unlock')),
        body: const Center(
          child: Text('No coordinates are stored for this person.'),
        ),
      );
    }

    final target = LatLng(p.birthLat!, p.birthLng!);

    final markers = <Marker>[
      if (_guess != null)
        Marker(
          point: _guess!,
          width: 44,
          height: 44,
          child: const Icon(Icons.location_on, size: 40),
        ),
      if (_done)
        Marker(
          point: target,
          width: 44,
          height: 44,
          child: const Icon(Icons.flag, size: 34),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Map-Unlock')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Tap the map: where was ${p.name} born?\n'
              '(Radius: ${widget.radiusKm.toStringAsFixed(0)} km)',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(20, 0),
                initialZoom: 2.4,
                onTap: _done
                    ? null
                    : (tapPos, latLng) {
                        final km = _distance.as(
                          LengthUnit.Kilometer,
                          latLng,
                          target,
                        );

                        final correct = km <= widget.radiusKm;

                        setState(() {
                          _guess = latLng;
                          _km = km;
                          _done = true;
                        });

                        // MVP: einfach XP
                        widget.session.xp += correct ? 50 : 2;
                        widget.session.save();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              correct
                                  ? 'Correct! (${km.round()} km) +50 XP'
                                  : 'Too far away: ${km.round()} km (+2 XP)',
                            ),
                          ),
                        );
                      },
              ),
              children: [
                TileLayer(
                  urlTemplate: MapTileConfig.standardRasterUrlTemplate,
                  userAgentPackageName: MapTileConfig.userAgentPackageName,
                ),
                if (_done && _guess != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: [_guess!, target], strokeWidth: 3),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          if (_done) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _km == null
                    ? ''
                    : 'Dein Tipp war ${_km!.round()} km entfernt.\n'
                          'Target: ${p.birthPlaceLabel ?? 'unknown'}',
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
