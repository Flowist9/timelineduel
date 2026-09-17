import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../battle/battle_targets.dart';
import '../data/historical_events.dart';
import '../localization/app_language.dart';
import '../logic/game_session.dart';
import 'battle_guess_widgets.dart';

enum _DailyChallengeRoundType { date, location }

class _DailyChallengeRound {
  final HistoricalEventRecord event;
  final _DailyChallengeRoundType type;

  const _DailyChallengeRound({required this.event, required this.type});
}

class DailyChallengeScreen extends StatefulWidget {
  final GameSession session;

  const DailyChallengeScreen({super.key, required this.session});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final Distance _distance = const Distance();

  late List<int> _dateDigits;
  LatLng? _mapGuess;

  bool _loading = true;
  bool _finished = false;
  bool _failed = false;
  bool _rewardClaimed = false;
  int _roundIndex = 0;
  int _wrongAnswers = 0;
  int _correctAnswers = 0;
  List<_DailyChallengeRound> _rounds = const [];

  @override
  void initState() {
    super.initState();
    _dateDigits = [0, 1, 0, 1, 1, 9, 0, 0];
    _loadState();
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  List<_DailyChallengeRound> _buildRounds() {
    final seedDate = DateTime.now();
    final random = Random(
      seedDate.year * 10000 + seedDate.month * 100 + seedDate.day,
    );
    final events = [...historicalEventRecords]..shuffle(random);
    final picked = events.take(3).toList();

    return List.generate(picked.length, (index) {
      final type = (random.nextBool() || index == 0)
          ? _DailyChallengeRoundType.date
          : _DailyChallengeRoundType.location;
      return _DailyChallengeRound(event: picked[index], type: type);
    });
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey;
    final rounds = _buildRounds();

    if (!mounted) return;
    setState(() {
      _rounds = rounds;
      _roundIndex = prefs.getInt('daily_estimation_index_$key') ?? 0;
      _wrongAnswers = prefs.getInt('daily_estimation_wrong_$key') ?? 0;
      _correctAnswers = prefs.getInt('daily_estimation_correct_$key') ?? 0;
      _rewardClaimed = prefs.getBool('daily_estimation_reward_$key') ?? false;
      _finished = prefs.getBool('daily_estimation_finished_$key') ?? false;
      _failed = prefs.getBool('daily_estimation_failed_$key') ?? false;
      _prepareRoundState(_currentRoundOrNull);
      _loading = false;
    });
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey;
    await prefs.setInt('daily_estimation_index_$key', _roundIndex);
    await prefs.setInt('daily_estimation_wrong_$key', _wrongAnswers);
    await prefs.setInt('daily_estimation_correct_$key', _correctAnswers);
    await prefs.setBool('daily_estimation_reward_$key', _rewardClaimed);
    await prefs.setBool('daily_estimation_finished_$key', _finished);
    await prefs.setBool('daily_estimation_failed_$key', _failed);
  }

  _DailyChallengeRound? get _currentRoundOrNull {
    if (_rounds.isEmpty || _roundIndex >= _rounds.length) return null;
    return _rounds[_roundIndex];
  }

  void _prepareRoundState(_DailyChallengeRound? round) {
    _mapGuess = null;
    final date = round?.event.date ?? DateTime.utc(1900, 1, 1);
    _dateDigits = [
      date.day ~/ 10,
      date.day % 10,
      date.month ~/ 10,
      date.month % 10,
      date.year ~/ 1000,
      (date.year ~/ 100) % 10,
      (date.year ~/ 10) % 10,
      date.year % 10,
    ];
  }

  DateTime? get _guessedDateFromDigits {
    final day = (_dateDigits[0] * 10) + _dateDigits[1];
    final month = (_dateDigits[2] * 10) + _dateDigits[3];
    final year =
        (_dateDigits[4] * 1000) +
        (_dateDigits[5] * 100) +
        (_dateDigits[6] * 10) +
        _dateDigits[7];
    if (month < 1 || month > 12 || day < 1) return null;
    final candidate = DateTime.utc(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }
    return candidate;
  }

  Future<void> _submitCurrentRound() async {
    final round = _currentRoundOrNull;
    if (round == null) return;

    bool isCorrect;
    String detail;
    if (round.type == _DailyChallengeRoundType.date) {
      final guessedDate = _guessedDateFromDigits;
      if (guessedDate == null) {
        _showSnackBar('Please enter a valid date guess first.');
        return;
      }
      isCorrect =
          guessedDate.year == round.event.date.year &&
          guessedDate.month == round.event.date.month &&
          guessedDate.day == round.event.date.day;
      final dayDiff = guessedDate.difference(round.event.date).inDays.abs();
      detail = isCorrect
          ? 'Exact date. ${formatBattleEventDate(round.event.date)} is correct.'
          : 'Actual date: ${formatBattleEventDate(round.event.date)}. You were off by $dayDiff days.';
    } else {
      final guess = _mapGuess;
      if (guess == null) {
        _showSnackBar('Please place your map guess first.');
        return;
      }
      final km = _distance.as(
        LengthUnit.Kilometer,
        guess,
        LatLng(round.event.lat, round.event.lng),
      );
      isCorrect = km <= 350;
      detail = isCorrect
          ? 'Strong guess. The event happened near ${round.event.locationLabel}, ${round.event.regionLabel}.'
          : 'Actual location: ${round.event.locationLabel}, ${round.event.regionLabel}. Your guess was ${km.round()} km away.';
    }

    if (isCorrect) {
      _correctAnswers += 1;
    } else {
      _wrongAnswers += 1;
    }

    if (_wrongAnswers >= 2) {
      _failed = true;
      _finished = true;
    } else if (_roundIndex >= _rounds.length - 1) {
      _finished = true;
      if (!_rewardClaimed) {
        _rewardClaimed = true;
        widget.session.addCoins(20);
      }
    } else {
      _roundIndex += 1;
      _prepareRoundState(_currentRoundOrNull);
    }

    await _persistState();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        final accent = isCorrect
            ? const Color(0xFFD4B06A)
            : const Color(0xFFC16F5A);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFF3A271B), Color(0xFF1A120D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFF1E2CB).withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.place_rounded,
                  color: accent,
                  size: 46,
                ),
                const SizedBox(height: 14),
                Text(
                  isCorrect ? 'Strong guess' : 'Close, but not enough',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  round.event.title,
                  style: const TextStyle(
                    color: Color(0xFFF8F0E3),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE6D6BF),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: const Color(0xFF1B100A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final round = _currentRoundOrNull;
    final mistakesLeft = max(0, 1 - _wrongAnswers);

    return Scaffold(
      backgroundColor: const Color(0xFF120B07),
      appBar: AppBar(
        title: Text(context.tr('Daily Challenge', 'Daily Challenge')),
        backgroundColor: const Color(0xFF1E120D),
        foregroundColor: const Color(0xFFF7ECDD),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF26170F), Color(0xFF120B07)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _buildHeroCard(context),
                    const SizedBox(height: 14),
                    if (_finished || round == null)
                      _buildFinishedCard(context)
                    else
                      _buildRoundCard(context, round, mistakesLeft),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4B06A).withValues(alpha: 0.16),
            const Color(0xFF2A180F),
            const Color(0xFF170D09),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFD4B06A).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Daily Challenge', 'Daily Challenge'),
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              '3 harte Schaetzfragen aus historischen Ereignissen. Ein Fehler ist erlaubt, der zweite beendet den Lauf.',
              '3 hard historical estimation questions. One mistake is allowed, the second ends the run.',
            ),
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('3 rounds'),
              _pill('1 mistake allowed'),
              _pill(_rewardClaimed ? 'Reward claimed' : 'Reward: 20 coins'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedCard(BuildContext context) {
    final success = _finished && !_failed;
    return _challengePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            success
                ? context.tr('Challenge geschafft', 'Challenge cleared')
                : context.tr('Challenge beendet', 'Challenge ended'),
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            success
                ? context.tr(
                    'You solved $_correctAnswers out of 3 difficult estimation questions. Come back tomorrow for a new set.',
                    'You cleared $_correctAnswers out of 3 hard estimation questions. Come back tomorrow for a new set.',
                  )
                : context.tr(
                    'Du hattest zwei Fehlversuche. Morgen wartet ein neues Daily auf dich.',
                    'You used up both misses. Tomorrow brings a fresh daily run.',
                  ),
            style: const TextStyle(
              color: Color(0xFFE6D6BF),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('Correct: $_correctAnswers / 3'),
              _pill('Mistakes: $_wrongAnswers / 2'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundCard(
    BuildContext context,
    _DailyChallengeRound round,
    int mistakesLeft,
  ) {
    return _challengePanel(
      child: SizedBox(
        height: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Round ${_roundIndex + 1} / 3',
              style: TextStyle(
                color: const Color(0xFFD4B06A).withValues(alpha: 0.95),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              round.type == _DailyChallengeRoundType.date
                  ? context.tr(
                      'Schaetze das genaue Datum',
                      'Guess the exact date',
                    )
                  : context.tr(
                      'Guess the location on the map',
                      'Guess the location on the map',
                    ),
              style: const TextStyle(
                color: Color(0xFFF7ECDD),
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              round.event.title,
              style: const TextStyle(
                color: Color(0xFFE6D6BF),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill('Mistakes left: $mistakesLeft'),
                _pill(
                  round.type == _DailyChallengeRoundType.date
                      ? 'Day / Month / Year'
                      : 'No labels map',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: round.type == _DailyChallengeRoundType.date
                  ? BattleDateGuessPanel(
                      digits: _dateDigits,
                      guessedDate: _guessedDateFromDigits,
                      onDigitChanged: (index, value) {
                        setState(() {
                          _dateDigits[index] = value;
                        });
                      },
                    )
                  : BattleMapGuessPanel(
                      selectedPoint: _mapGuess,
                      onTap: (point) {
                        setState(() {
                          _mapGuess = point;
                        });
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitCurrentRound,
                icon: Icon(
                  round.type == _DailyChallengeRoundType.date
                      ? Icons.dialpad_rounded
                      : Icons.place_rounded,
                ),
                label: Text(
                  round.type == _DailyChallengeRoundType.date
                      ? context.tr('Submit date guess', 'Submit date guess')
                      : context.tr(
                          'Submit location guess',
                          'Submit location guess',
                        ),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD4B06A),
                  foregroundColor: const Color(0xFF1B100A),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _challengePanel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B2418).withValues(alpha: 0.88),
            const Color(0xFF21120B).withValues(alpha: 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFD4B06A).withValues(alpha: 0.18),
        ),
      ),
      child: child,
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF1E2CB).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFFF1E2CB).withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFF7ECDD),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
