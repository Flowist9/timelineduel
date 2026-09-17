import 'package:flutter/material.dart';

import '../../../models/person.dart';

typedef UnlockHeaderBuilder =
    Widget Function(Person person, String title, String subtitle);
typedef UnlockPanelBuilder =
    Widget Function(Widget child, {EdgeInsetsGeometry? padding});

class UnlockBirthYearStep extends StatelessWidget {
  final Person person;
  final Color color;
  final List<int> birthYearChoices;
  final ValueChanged<int> onSubmitYear;
  final UnlockHeaderBuilder headerBuilder;
  final UnlockPanelBuilder panelBuilder;

  const UnlockBirthYearStep({
    super.key,
    required this.person,
    required this.color,
    required this.birthYearChoices,
    required this.onSubmitYear,
    required this.headerBuilder,
    required this.panelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        headerBuilder(
          person,
          'When was this person born?',
          'Complete the three steps to add ${person.name} to the main game.',
        ),
        const SizedBox(height: 18),
        panelBuilder(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 1',
                style: TextStyle(
                  color: Color(0xFFD4B06A),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose the correct birth year',
                style: TextStyle(
                  color: Color(0xFFF8F0E3),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              ...birthYearChoices.map(
                (year) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onSubmitYear(year),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        foregroundColor: const Color(0xFFF8F0E3),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: color.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      child: Text(
                        '$year',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
