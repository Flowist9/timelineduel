import 'package:flutter/material.dart';

import '../../../data/quiz_facts.dart';
import '../../../models/person.dart';
import 'unlock_birth_year_step.dart';

class UnlockFamousForStep extends StatelessWidget {
  final Person person;
  final Color color;
  final FamousForQuiz? quiz;
  final List<String> options;
  final bool isAnswered;
  final bool wasCorrect;
  final String? correctAnswer;
  final VoidCallback onSkip;
  final VoidCallback onRetry;
  final ValueChanged<String> onSubmitAnswer;
  final UnlockHeaderBuilder headerBuilder;
  final UnlockPanelBuilder panelBuilder;

  const UnlockFamousForStep({
    super.key,
    required this.person,
    required this.color,
    required this.quiz,
    required this.options,
    required this.isAnswered,
    required this.wasCorrect,
    required this.correctAnswer,
    required this.onSkip,
    required this.onRetry,
    required this.onSubmitAnswer,
    required this.headerBuilder,
    required this.panelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (quiz == null) {
      return Column(
        children: [
          headerBuilder(
            person,
            'What is this person best known for?',
            'There is no knowledge fact for this person yet. You can skip this step.',
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

    return Column(
      children: [
        headerBuilder(
          person,
          'What is this person best known for?',
          'Choose the most fitting description to fully unlock ${person.name}.',
        ),
        const SizedBox(height: 18),
        panelBuilder(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 3',
                style: TextStyle(
                  color: Color(0xFFD4B06A),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'What is this person best known for?',
                style: TextStyle(
                  color: Color(0xFFF8F0E3),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < options.length; i++) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isAnswered
                        ? null
                        : () => onSubmitAnswer(options[i]),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      foregroundColor: const Color(0xFFF8F0E3),
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: color.withValues(alpha: 0.45)),
                      ),
                    ),
                    child: Text(
                      options[i],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                if (i != options.length - 1) const SizedBox(height: 12),
              ],
              if (isAnswered) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  child: Column(
                    children: [
                      Text(
                        wasCorrect ? 'Correct answer.' : 'Not quite.',
                        style: TextStyle(
                          color: wasCorrect
                              ? const Color(0xFFB7A16A)
                              : const Color(0xFFD4B06A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Correct answer: ${correctAnswer ?? quiz!.correct}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE6D6BF),
                          height: 1.4,
                        ),
                      ),
                      if (!wasCorrect) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: onRetry,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF8F0E3),
                              side: BorderSide(
                                color: color.withValues(alpha: 0.45),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Try again'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
