import 'dart:math';

import 'package:flutter/material.dart';

import '../data/persons.dart';
import '../logic/game_session.dart';
import '../models/person.dart';
import '../models/person_status.dart';

class MiniSortScreen extends StatefulWidget {
  final GameSession session;
  final Person? focusPerson;
  final bool unlockMode;

  const MiniSortScreen({
    super.key,
    required this.session,
    this.focusPerson,
    this.unlockMode = false,
  });

  @override
  State<MiniSortScreen> createState() => _MiniSortScreenState();
}

class _MiniSortScreenState extends State<MiniSortScreen> {
  final _rand = Random();

  late final List<Person> _correctOrder;
  late List<Person> _currentOrder;

  bool _submitted = false;
  int _correctPositions = 0;

  @override
  void initState() {
    super.initState();

    final picked = _buildPickedPersons();
    _correctOrder = [...picked]
      ..sort((a, b) => _birthKey(a).compareTo(_birthKey(b)));
    _currentOrder = [...picked]..shuffle(_rand);
  }

  List<Person> _buildPickedPersons() {
    final candidates = allPersons.where((p) {
      final s = widget.session.statusById[p.id];
      return s == PersonStatus.discovered || s == PersonStatus.unlocked;
    }).toList();

    final pool = candidates.isNotEmpty ? candidates : [...allPersons];

    if (widget.focusPerson != null) {
      final focus = widget.focusPerson!;

      final others = pool.where((p) => p.id != focus.id).toList();

      others.sort((a, b) {
        final da = (a.birthYear - focus.birthYear).abs();
        final db = (b.birthYear - focus.birthYear).abs();
        return da.compareTo(db);
      });

      final result = <Person>[focus];

      for (final p in others.take(3)) {
        result.add(p);
      }

      if (result.length < 4) {
        final remaining =
            allPersons.where((p) => !result.any((r) => r.id == p.id)).toList()
              ..shuffle(_rand);

        for (final p in remaining) {
          if (result.length >= 4) break;
          result.add(p);
        }
      }

      result.shuffle(_rand);
      return result;
    }

    final copy = [...pool]..shuffle(_rand);
    final n = copy.length >= 4 ? 4 : min(3, copy.length);
    return copy.take(n).toList();
  }

  int _birthKey(Person p) {
    final d = p.birthDate;
    if (d != null) return d.millisecondsSinceEpoch;
    return p.birthYear * 366;
  }

  void _submit() {
    if (_submitted) return;

    int correct = 0;
    for (int i = 0; i < _currentOrder.length; i++) {
      if (_currentOrder[i].id == _correctOrder[i].id) {
        correct++;
      }
    }

    final total = _currentOrder.length;
    final allCorrect = correct == total;

    setState(() {
      _submitted = true;
      _correctPositions = correct;
    });

    int xp = 0;
    if (!widget.unlockMode) {
      if (correct == total) {
        xp = 60;
      } else if (correct == total - 1) {
        xp = 25;
      } else if (correct >= 1) {
        xp = 10;
      }

      widget.session.xp += xp;
      widget.session.save();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.unlockMode
              ? (allCorrect
                    ? 'Perfectly sorted ✅'
                    : 'You got $correct/$total right. For the unlock, please sort everything correctly.')
              : 'You got $correct/$total right. +$xp XP',
        ),
      ),
    );

    if (widget.unlockMode && allCorrect) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.unlockMode ? 'Unlock: Sorting' : 'Mini-game: Sorting',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              widget.unlockMode
                  ? 'Arrange the people chronologically (early → late). For the unlock, everything must be correct.'
                  : 'Arrange the people chronologically (early → late) via drag and drop.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _currentOrder.length,
                onReorder: _submitted
                    ? (_, __) {}
                    : (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _currentOrder.removeAt(oldIndex);
                          _currentOrder.insert(newIndex, item);
                        });
                      },
                itemBuilder: (context, index) {
                  final p = _currentOrder[index];
                  final isCorrectHere =
                      _submitted && p.id == _correctOrder[index].id;
                  final isFocus =
                      widget.focusPerson != null &&
                      p.id == widget.focusPerson!.id;

                  return Card(
                    key: ValueKey(p.id),
                    child: ListTile(
                      title: Text(
                        p.name,
                        style: TextStyle(
                          fontWeight: isFocus
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        isFocus
                            ? '${p.category.name} • focus person'
                            : p.category.name,
                      ),
                      trailing: _submitted
                          ? Icon(
                              isCorrectHere ? Icons.check_circle : Icons.cancel,
                            )
                          : const Icon(Icons.drag_handle),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitted ? null : _submit,
                    child: const Text('Submit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (widget.unlockMode) {
                        Navigator.pop(context, false);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Back'),
                  ),
                ),
              ],
            ),
            if (_submitted) ...[
              const SizedBox(height: 8),
              Text(
                'Correct order: ${_correctOrder.map((e) => e.name).join(' → ')}',
              ),
              const SizedBox(height: 4),
              Text(
                'Correct placements: $_correctPositions/${_currentOrder.length}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
