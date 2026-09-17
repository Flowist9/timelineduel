import 'dart:math';

import '../data/historical_events.dart';

class BattleYearTarget {
  final String label;
  final int year;
  final String context;

  const BattleYearTarget({
    required this.label,
    required this.year,
    required this.context,
  });
}

class BattleLocationTarget {
  final String label;
  final String regionLabel;
  final double lat;
  final double lng;
  final String context;

  const BattleLocationTarget({
    required this.label,
    required this.regionLabel,
    required this.lat,
    required this.lng,
    required this.context,
  });
}

class BattleHistoricalEventTarget {
  final String title;
  final DateTime date;
  final String locationLabel;
  final String regionLabel;
  final double lat;
  final double lng;
  final String summary;

  BattleHistoricalEventTarget({
    required this.title,
    required this.date,
    required this.locationLabel,
    required this.regionLabel,
    required this.lat,
    required this.lng,
    required this.summary,
  });

  String get datePrompt => 'When did $title happen?';
  String get locationPrompt => 'Where did $title happen?';
}

const List<BattleYearTarget> battleYearTargets = [
  BattleYearTarget(
    label: 'French Revolution',
    year: 1789,
    context: 'Which figure was born closer to the French Revolution?',
  ),
  BattleYearTarget(
    label: 'American Independence',
    year: 1776,
    context: 'Which figure was born closer to American Independence?',
  ),
  BattleYearTarget(
    label: 'World War I',
    year: 1914,
    context: 'Which figure was born closer to the start of World War I?',
  ),
  BattleYearTarget(
    label: 'Moon Landing',
    year: 1969,
    context: 'Which figure was born closer to the Moon Landing?',
  ),
  BattleYearTarget(
    label: 'Fall of the Berlin Wall',
    year: 1989,
    context: 'Which figure was born closer to the fall of the Berlin Wall?',
  ),
];

const List<BattleLocationTarget> battleLocationTargets = [
  BattleLocationTarget(
    label: 'Rome',
    regionLabel: 'Italy',
    lat: 41.9028,
    lng: 12.4964,
    context: 'Which figure was born closer to Rome?',
  ),
  BattleLocationTarget(
    label: 'Athens',
    regionLabel: 'Greece',
    lat: 37.9838,
    lng: 23.7275,
    context: 'Which figure was born closer to Athens?',
  ),
  BattleLocationTarget(
    label: 'Paris',
    regionLabel: 'France',
    lat: 48.8566,
    lng: 2.3522,
    context: 'Which figure was born closer to Paris?',
  ),
  BattleLocationTarget(
    label: 'London',
    regionLabel: 'United Kingdom',
    lat: 51.5072,
    lng: -0.1276,
    context: 'Which figure was born closer to London?',
  ),
  BattleLocationTarget(
    label: 'Cairo',
    regionLabel: 'Egypt',
    lat: 30.0444,
    lng: 31.2357,
    context: 'Which figure was born closer to Cairo?',
  ),
  BattleLocationTarget(
    label: 'New York',
    regionLabel: 'USA',
    lat: 40.7128,
    lng: -74.0060,
    context: 'Which figure was born closer to New York?',
  ),
  BattleLocationTarget(
    label: 'Tokyo',
    regionLabel: 'Japan',
    lat: 35.6762,
    lng: 139.6503,
    context: 'Which figure was born closer to Tokyo?',
  ),
  BattleLocationTarget(
    label: 'Sydney',
    regionLabel: 'Australia',
    lat: -33.8688,
    lng: 151.2093,
    context: 'Which figure was born closer to Sydney?',
  ),
  BattleLocationTarget(
    label: 'Lima',
    regionLabel: 'Peru',
    lat: -12.0464,
    lng: -77.0428,
    context: 'Which figure was born closer to Lima?',
  ),
  BattleLocationTarget(
    label: 'Cape Town',
    regionLabel: 'South Africa',
    lat: -33.9249,
    lng: 18.4241,
    context: 'Which figure was born closer to Cape Town?',
  ),
  BattleLocationTarget(
    label: 'Reykjavik',
    regionLabel: 'Iceland',
    lat: 64.1466,
    lng: -21.9426,
    context: 'Which figure was born closer to Reykjavik?',
  ),
  BattleLocationTarget(
    label: 'Delhi',
    regionLabel: 'India',
    lat: 28.6139,
    lng: 77.2090,
    context: 'Which figure was born closer to Delhi?',
  ),
  BattleLocationTarget(
    label: 'Mexico City',
    regionLabel: 'Mexico',
    lat: 19.4326,
    lng: -99.1332,
    context: 'Which figure was born closer to Mexico City?',
  ),
];

final List<BattleHistoricalEventTarget> battleHistoricalEventTargets =
    historicalEventRecords
        .map(
          (event) => BattleHistoricalEventTarget(
            title: event.title,
            date: event.date,
            locationLabel: event.locationLabel,
            regionLabel: event.regionLabel,
            lat: event.lat,
            lng: event.lng,
            summary: event.summary,
          ),
        )
        .toList(growable: false);

BattleYearTarget randomBattleYearTarget(Random random) {
  final year = 1450 + random.nextInt(571);
  return BattleYearTarget(
    label: 'Year $year',
    year: year,
    context: 'Which figure was born closer to the year $year?',
  );
}

BattleLocationTarget randomBattleLocationTarget(Random random) {
  return battleLocationTargets[random.nextInt(battleLocationTargets.length)];
}

BattleHistoricalEventTarget randomBattleHistoricalEventTarget(Random random) {
  return battleHistoricalEventTargets[random.nextInt(
    battleHistoricalEventTargets.length,
  )];
}

String formatBattleEventDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String formatBattleEventDateCompact(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
