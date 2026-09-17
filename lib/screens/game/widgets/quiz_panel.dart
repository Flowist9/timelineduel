import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../maps/map_tile_config.dart';
import '../../../models/category.dart';
import '../../../models/person.dart';
import '../../../models/question.dart';
import '../../../widgets/person_portrait.dart';

typedef QuizPanelBuilder =
    Widget Function(Widget child, {EdgeInsetsGeometry? padding});
typedef TimelineCardBuilder =
    Widget Function(Person person, int? slotNumber, {bool showLabel});

class QuizPanel extends StatelessWidget {
  final int unlockedCount;
  final Question? question;
  final bool fitViewport;
  final bool buttonsLocked;
  final List<Person> quizOrderSequence;
  final List<Person> quizClosestPairSelection;
  final LatLng? birthMapGuess;
  final double? birthMapDistanceKm;
  final int birthMapRadiusKm;
  final Future<void> Function(String selectedOption) onSubmitAnswer;
  final ValueChanged<LatLng> onTapBirthMap;
  final Future<void> Function(Person person) onToggleClosestPairSelection;
  final VoidCallback onSubmitOrderSequenceAnswer;
  final ValueChanged<List<Person>> onOrderSequenceChanged;
  final String Function(Category category) categoryLabel;
  final Color Function(Category category) categoryColor;
  final TimelineCardBuilder timelineCardBuilder;
  final QuizPanelBuilder panelBuilder;

  const QuizPanel({
    super.key,
    required this.unlockedCount,
    required this.question,
    this.fitViewport = false,
    required this.buttonsLocked,
    required this.quizOrderSequence,
    required this.quizClosestPairSelection,
    required this.birthMapGuess,
    required this.birthMapDistanceKm,
    required this.birthMapRadiusKm,
    required this.onSubmitAnswer,
    required this.onTapBirthMap,
    required this.onToggleClosestPairSelection,
    required this.onSubmitOrderSequenceAnswer,
    required this.onOrderSequenceChanged,
    required this.categoryLabel,
    required this.categoryColor,
    required this.timelineCardBuilder,
    required this.panelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (unlockedCount < 2 || question == null) {
      return panelBuilder(
        const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFFD4B06A),
                size: 42,
              ),
              SizedBox(height: 14),
              Text(
                'Not enough people unlocked yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF8F0E3),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'As soon as at least two people are in the pool, your quiz starts here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFE6D6BF), height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = question!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 760;
    final viewportCompact = fitViewport;
    final figures = currentQuestion.figures.isNotEmpty
        ? currentQuestion.figures
        : [
            if (currentQuestion.subject != null) currentQuestion.subject!,
            if (currentQuestion.a != null) currentQuestion.a!,
            if (currentQuestion.b != null) currentQuestion.b!,
          ];
    final options = currentQuestion.options;
    final showDuel =
        figures.length == 2 &&
        (currentQuestion.type == QuestionType.overlap ||
            currentQuestion.type == QuestionType.earlierPerson);

    Widget personCard(
      Person person, {
      bool tall = true,
      bool compact = false,
      VoidCallback? onTap,
      bool expandImage = false,
    }) {
      final color = categoryColor(person.category);
      final imageHeight = compact
          ? (viewportCompact ? 76.0 : 120.0)
          : tall
          ? (viewportCompact
                ? (isCompact ? 170.0 : 210.0)
                : (isCompact ? 340.0 : 430.0))
          : (viewportCompact
                ? (isCompact ? 126.0 : 156.0)
                : (isCompact ? 300.0 : 360.0));
      final borderRadius = BorderRadius.circular(
        compact ? (viewportCompact ? 18 : 24) : (viewportCompact ? 24 : 34),
      );

      final cardChild = Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            colors: [
              Color.lerp(color, const Color(0xFF30231D), 0.72)!,
              const Color(0xFF201713),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: const Color(0xFFF1E2CB).withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: compact
                  ? (viewportCompact ? 14 : 18)
                  : (viewportCompact ? 20 : 28),
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(
            compact ? (viewportCompact ? 7 : 10) : (viewportCompact ? 8 : 14),
          ),
          child: Column(
            children: [
              if (expandImage)
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: PersonPortrait(
                      person: person,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: compact
                          ? (viewportCompact ? 14 : 18)
                          : (viewportCompact ? 18 : 28),
                      variant: compact
                          ? PersonImageVariant.portrait
                          : PersonImageVariant.vs,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: PersonPortrait(
                    person: person,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: compact
                        ? (viewportCompact ? 14 : 18)
                        : (viewportCompact ? 18 : 28),
                    variant: compact
                        ? PersonImageVariant.portrait
                        : PersonImageVariant.vs,
                  ),
                ),
              SizedBox(
                height: compact
                    ? (viewportCompact ? 8 : 10)
                    : (viewportCompact ? 10 : 14),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: compact
                      ? (viewportCompact ? 8 : 10)
                      : (viewportCompact ? 8 : 14),
                  vertical: compact
                      ? (viewportCompact ? 7 : 10)
                      : (viewportCompact ? 7 : 12),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    compact
                        ? (viewportCompact ? 12 : 16)
                        : (viewportCompact ? 16 : 20),
                  ),
                  color: const Color(0xFFF1E2CB).withValues(alpha: 0.08),
                  border: Border.all(
                    color: const Color(0xFFF1E2CB).withValues(alpha: 0.10),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      person.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF8F0E3),
                        fontSize: compact
                            ? (viewportCompact ? 12 : 14)
                            : (viewportCompact
                                  ? (isCompact ? 13 : 16)
                                  : (isCompact ? 18 : 24)),
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: viewportCompact ? 4 : 6),
                    Text(
                      categoryLabel(person.category),
                      style: TextStyle(
                        color: color.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w700,
                        fontSize: compact
                            ? (viewportCompact ? 10 : 11)
                            : (viewportCompact ? 10 : 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      if (onTap == null) {
        return cardChild;
      }

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: cardChild,
        ),
      );
    }

    Widget answerButton(String option, int index) {
      return ElevatedButton(
        onPressed: buttonsLocked ? null : () => onSubmitAnswer(option),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF30231D),
          foregroundColor: const Color(0xFFFFF6E7),
          overlayColor: const Color(0xFFE6B968),
          side: const BorderSide(color: Color(0x557F6847)),
          padding: EdgeInsets.symmetric(
            vertical: viewportCompact ? 10 : 18,
            horizontal: viewportCompact ? 12 : 16,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(viewportCompact ? 18 : 22),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0x22E6B968),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Color(0xFFE6B968), fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: viewportCompact ? 14 : 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget compactChoiceRow(
      Person person, {
      required VoidCallback? onTap,
      Widget? trailing,
      bool expand = false,
    }) {
      final color = categoryColor(person.category);
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: expand ? null : (viewportCompact ? 68 : 74),
          padding: EdgeInsets.symmetric(
            horizontal: viewportCompact ? 8 : 10,
            vertical: viewportCompact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                Color.lerp(color, Colors.white, 0.08)!,
                Color.lerp(color, const Color(0xFF2B1E14), 0.48)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFF1E2CB).withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            crossAxisAlignment: expand
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
            children: [
              if (expand)
                AspectRatio(
                  aspectRatio: 1.0,
                  child: PersonPortrait(
                    person: person,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 14,
                    variant: PersonImageVariant.portrait,
                  ),
                )
              else
                PersonPortrait(
                  person: person,
                  width: viewportCompact ? 50 : 56,
                  height: viewportCompact ? 50 : 56,
                  borderRadius: 14,
                  variant: PersonImageVariant.portrait,
                ),
              SizedBox(width: viewportCompact ? 8 : 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF8F0E3),
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: viewportCompact ? 2 : 4),
                    Text(
                      categoryLabel(person.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w700,
                        fontSize: viewportCompact ? 10 : 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
        ),
      );
    }

    Widget targetMeetingCard(Person person) {
      final color = categoryColor(person.category);
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(viewportCompact ? 10 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Color.lerp(color, Colors.white, 0.10)!,
              Color.lerp(color, const Color(0xFF2B1E14), 0.52)!,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: const Color(0xFFF1E2CB).withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: viewportCompact ? 156 : 184,
              width: double.infinity,
              child: PersonPortrait(
                person: person,
                width: double.infinity,
                height: double.infinity,
                borderRadius: 18,
                variant: PersonImageVariant.vs,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF1E2CB).withValues(alpha: 0.08),
                border: Border.all(
                  color: const Color(0xFFF1E2CB).withValues(alpha: 0.10),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    person.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFF8F0E3),
                      fontSize: viewportCompact ? 14 : 16,
                      fontWeight: FontWeight.w900,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categoryLabel(person.category),
                    style: TextStyle(
                      color: color.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
                      fontSize: viewportCompact ? 10 : 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget targetBirthplaceCard(Person person) {
      final color = categoryColor(person.category);
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(viewportCompact ? 10 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Color.lerp(color, Colors.white, 0.08)!,
              Color.lerp(color, const Color(0xFF2B1E14), 0.56)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFF1E2CB).withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            PersonPortrait(
              person: person,
              width: viewportCompact ? 78 : 96,
              height: viewportCompact ? 78 : 96,
              borderRadius: 18,
              variant: PersonImageVariant.portrait,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target person',
                    style: TextStyle(
                      color: const Color(0xFFD4B06A),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: viewportCompact ? 11 : 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    person.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFF8F0E3),
                      fontWeight: FontWeight.w900,
                      fontSize: viewportCompact ? 18 : 20,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    categoryLabel(person.category),
                    style: TextStyle(
                      color: color.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: viewportCompact ? 12 : 13,
                    ),
                  ),
                  if (person.birthPlaceLabel != null ||
                      person.birthCountry.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFFF1E2CB).withValues(alpha: 0.08),
                        border: Border.all(
                          color: const Color(
                            0xFFF1E2CB,
                          ).withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: 14,
                            color: Color(0xFFD4B06A),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              person.birthPlaceLabel ?? person.birthCountry,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFE6D6BF),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget figureBlock() {
      if (currentQuestion.type == QuestionType.orderSequence ||
          currentQuestion.type == QuestionType.closestPair ||
          currentQuestion.type == QuestionType.birthplaceMap ||
          currentQuestion.type == QuestionType.mapEventLocation) {
        return const SizedBox.shrink();
      }

      final usesPersonChoiceCards =
          currentQuestion.type == QuestionType.birthCentury ||
          currentQuestion.type == QuestionType.meetingCandidate ||
          currentQuestion.type == QuestionType.northernmostBirthplace ||
          currentQuestion.type == QuestionType.southernmostBirthplace ||
          currentQuestion.type == QuestionType.scientistTheory ||
          currentQuestion.type == QuestionType.scientistFormula ||
          currentQuestion.type == QuestionType.scientistDiscovery ||
          currentQuestion.type == QuestionType.artistWork ||
          currentQuestion.type == QuestionType.artistQuote ||
          currentQuestion.type == QuestionType.workDescription ||
          currentQuestion.type == QuestionType.athleteAchievement ||
          currentQuestion.type == QuestionType.sportStatline ||
          currentQuestion.type == QuestionType.politicianRole ||
          currentQuestion.type == QuestionType.politicianEventMatch ||
          currentQuestion.type == QuestionType.twoCluesOnePerson ||
          currentQuestion.type == QuestionType.multiClueExpert;

      if ((currentQuestion.type == QuestionType.meetingCandidate ||
              currentQuestion.type == QuestionType.birthCentury) &&
          currentQuestion.subject != null) {
        return Column(
          children: [
            SizedBox(
              width: isCompact ? double.infinity : 420,
              child: currentQuestion.type == QuestionType.birthCentury
                  ? targetBirthplaceCard(currentQuestion.subject!)
                  : targetMeetingCard(currentQuestion.subject!),
            ),
            const SizedBox(height: 12),
            if (currentQuestion.type == QuestionType.birthCentury)
              const Text(
                'Choose the person whose birthplace is closest to the target.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE6D6BF),
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        );
      }

      if (usesPersonChoiceCards) {
        return const SizedBox.shrink();
      }

      if (showDuel) {
        final badgeSize = isCompact ? 58.0 : 72.0;
        return Stack(
          fit: fitViewport ? StackFit.expand : StackFit.loose,
          alignment: Alignment.center,
          children: [
            Row(
              crossAxisAlignment: fitViewport
                  ? CrossAxisAlignment.stretch
                  : CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: personCard(
                    figures[0],
                    expandImage: fitViewport,
                    onTap:
                        currentQuestion.type == QuestionType.earlierPerson &&
                            !buttonsLocked
                        ? () => onSubmitAnswer(figures[0].name)
                        : null,
                  ),
                ),
                SizedBox(width: isCompact ? 18 : 28),
                Expanded(
                  child: personCard(
                    figures[1],
                    expandImage: fitViewport,
                    onTap:
                        currentQuestion.type == QuestionType.earlierPerson &&
                            !buttonsLocked
                        ? () => onSubmitAnswer(figures[1].name)
                        : null,
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: Center(
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE5C98F), Color(0xFFC9974E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4B06A).withValues(alpha: 0.28),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      currentQuestion.type == QuestionType.overlap
                          ? 'VS'
                          : 'WHO?',
                      style: TextStyle(
                        color: const Color(0xFF4A3118),
                        fontWeight: FontWeight.w900,
                        fontSize: isCompact ? 18 : 22,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }

      if (figures.length == 1) {
        return SizedBox(
          width: isCompact ? double.infinity : 420,
          child: personCard(
            figures.first,
            tall: false,
            expandImage: fitViewport,
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: figures.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: figures.length >= 4 ? 2 : figures.length,
          mainAxisSpacing: viewportCompact ? 8 : 12,
          crossAxisSpacing: viewportCompact ? 8 : 12,
          childAspectRatio: viewportCompact ? 1.0 : 0.68,
        ),
        itemBuilder: (context, index) {
          return personCard(figures[index], compact: true);
        },
      );
    }

    Widget buildMeetingCandidateChoices() {
      final candidatePersons = currentQuestion.options
          .map((name) => figures.firstWhere((person) => person.name == name))
          .toList();

      if (viewportCompact) {
        return Column(
          children: [
            for (int index = 0; index < candidatePersons.length; index++) ...[
              if (fitViewport)
                Expanded(
                  child: compactChoiceRow(
                    candidatePersons[index],
                    onTap: buttonsLocked
                        ? null
                        : () => onSubmitAnswer(candidatePersons[index].name),
                    expand: true,
                  ),
                )
              else
                compactChoiceRow(
                  candidatePersons[index],
                  onTap: buttonsLocked
                      ? null
                      : () => onSubmitAnswer(candidatePersons[index].name),
                ),
              if (index != candidatePersons.length - 1)
                const SizedBox(height: 8),
            ],
          ],
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: candidatePersons.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isCompact ? 1 : candidatePersons.length,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isCompact ? 1.9 : 0.72,
        ),
        itemBuilder: (context, index) {
          final person = candidatePersons[index];
          final color = categoryColor(person.category);
          return InkWell(
            onTap: buttonsLocked ? null : () => onSubmitAnswer(person.name),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(color, Colors.white, 0.08)!,
                    Color.lerp(color, const Color(0xFF2B1E14), 0.48)!,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(
                  color: const Color(0xFFF1E2CB).withValues(alpha: 0.14),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: PersonPortrait(
                      person: person,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 18,
                      variant: PersonImageVariant.portrait,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    person.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF8F0E3),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    Widget buildClosestPairInteraction() {
      if (viewportCompact) {
        return Column(
          children: [
            const Text(
              'Tap two people directly. The reveal appears right after the second choice.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFE6D6BF),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (int index = 0; index < figures.length; index++) ...[
              Builder(
                builder: (context) {
                  final person = figures[index];
                  final selectionIndex = quizClosestPairSelection.indexWhere(
                    (p) => p.id == person.id,
                  );
                  final isSelected = selectionIndex != -1;
                  final row = compactChoiceRow(
                    person,
                    onTap: buttonsLocked
                        ? null
                        : () => onToggleClosestPairSelection(person),
                    expand: fitViewport,
                    trailing: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: isSelected ? 1 : 0.25,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFFD4B06A)
                              : const Color(0xFFF1E2CB).withValues(alpha: 0.10),
                        ),
                        child: Center(
                          child: Text(
                            isSelected ? '${selectionIndex + 1}' : '+',
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF2D2012)
                                  : const Color(0xFFE6D6BF),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  return fitViewport ? Expanded(child: row) : row;
                },
              ),
              if (index != figures.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      }

      return Column(
        children: [
          const Text(
            'Tap two people directly. The reveal appears right after the second choice.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE6D6BF),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: figures.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isCompact ? 2 : figures.length,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isCompact ? 0.9 : 0.72,
            ),
            itemBuilder: (context, index) {
              final person = figures[index];
              final color = categoryColor(person.category);
              final selectionIndex = quizClosestPairSelection.indexWhere(
                (p) => p.id == person.id,
              );
              final isSelected = selectionIndex != -1;

              return InkWell(
                onTap: buttonsLocked
                    ? null
                    : () => onToggleClosestPairSelection(person),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(
                          color,
                          Colors.white,
                          isSelected ? 0.28 : 0.10,
                        )!,
                        Color.lerp(
                          color,
                          const Color(0xFF2B1E14),
                          isSelected ? 0.22 : 0.52,
                        )!,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFD4B06A)
                          : const Color(0xFFF1E2CB).withValues(alpha: 0.12),
                      width: isSelected ? 2.4 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFFD4B06A,
                              ).withValues(alpha: 0.20),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : const [],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 160),
                          opacity: isSelected ? 1 : 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFD4B06A),
                            ),
                            child: Center(
                              child: Text(
                                (selectionIndex + 1).toString(),
                                style: const TextStyle(
                                  color: Color(0xFF2D2012),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: PersonPortrait(
                          person: person,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 18,
                          variant: PersonImageVariant.portrait,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        person.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFF8F0E3),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    Widget buildBirthLocationInteraction() {
      final person = currentQuestion.subject;
      final isEventMap = currentQuestion.type == QuestionType.mapEventLocation;
      final targetLat = isEventMap
          ? currentQuestion.supportingLat
          : person?.birthLat;
      final targetLng = isEventMap
          ? currentQuestion.supportingLng
          : person?.birthLng;
      if (targetLat == null || targetLng == null) {
        return const SizedBox.shrink();
      }

      final title = isEventMap ? 'EVENT LOCATION' : 'BIRTHPLACE';
      final focusLabel = isEventMap
          ? (currentQuestion.supportingLabel ?? 'Historic event')
          : (person?.name ?? 'Unknown');

      final markers = <Marker>[
        if (birthMapGuess != null)
          Marker(
            point: birthMapGuess!,
            width: 118,
            height: 92,
            child: const _GuessMapMarker(),
          ),
      ];

      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF1C2C3A), Color(0xFF0F1924)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFF1E2CB).withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (fitViewport)
                Positioned.fill(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter:
                          birthMapGuess ?? LatLng(targetLat, targetLng),
                      initialZoom: birthMapGuess == null ? 2.3 : 3.0,
                      onTap: buttonsLocked
                          ? null
                          : (tapPosition, latLng) => onTapBirthMap(latLng),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: MapTileConfig.standardRasterUrlTemplate,
                        userAgentPackageName:
                            MapTileConfig.userAgentPackageName,
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: viewportCompact ? 300 : (isCompact ? 420 : 500),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter:
                          birthMapGuess ?? LatLng(targetLat, targetLng),
                      initialZoom: birthMapGuess == null ? 2.3 : 3.0,
                      onTap: buttonsLocked
                          ? null
                          : (tapPosition, latLng) => onTapBirthMap(latLng),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: MapTileConfig.standardRasterUrlTemplate,
                        userAgentPackageName:
                            MapTileConfig.userAgentPackageName,
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(viewportCompact ? 10 : 12),
                        decoration: BoxDecoration(
                          color: const Color(0xCC08131E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFFF1E2CB,
                            ).withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isEventMap
                                  ? Icons.flag_rounded
                                  : Icons.public_rounded,
                              color: const Color(0xFFD4B06A),
                              size: 26,
                            ),
                            SizedBox(width: viewportCompact ? 8 : 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: Color(0xFFD4B06A),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: viewportCompact ? 2 : 4),
                                  Text(
                                    focusLabel,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFF8F0E3),
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: viewportCompact ? 8 : 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _MapPill(label: 'Radius $birthMapRadiusKm km'),
                        if (birthMapDistanceKm != null) ...[
                          const SizedBox(height: 8),
                          if (viewportCompact) const SizedBox(height: 0),
                          _MapPill(
                            label: 'Tipp ${birthMapDistanceKm!.round()} km',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC08131E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF1E2CB).withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Text(
                    'Tap directly on the map. No sketch panel, just the full map.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFE6D6BF),
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildOrderSequenceInteraction() {
      final placedIds = quizOrderSequence.map((p) => p.id).toSet();
      final availablePersons = currentQuestion.figures
          .where((person) => !placedIds.contains(person.id))
          .toList();

      Widget timelineSlot(int index) {
        final assigned = index < quizOrderSequence.length
            ? quizOrderSequence[index]
            : null;

        return Expanded(
          child: DragTarget<Person>(
            onAcceptWithDetails: buttonsLocked
                ? null
                : (details) {
                    final nextSequence = [...quizOrderSequence]
                      ..removeWhere((p) => p.id == details.data.id);
                    if (index > nextSequence.length) {
                      nextSequence.add(details.data);
                    } else {
                      nextSequence.insert(index, details.data);
                    }
                    onOrderSequenceChanged(nextSequence);
                  },
            builder: (context, candidateData, rejectedData) {
              final highlight = candidateData.isNotEmpty;
              return Container(
                alignment: Alignment.topCenter,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 4,
                      margin: EdgeInsets.only(top: viewportCompact ? 30 : 58),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: highlight
                            ? const Color(0xFFD4B06A)
                            : const Color(0xFFD4B06A).withValues(alpha: 0.35),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, viewportCompact ? -15 : -30),
                      child: assigned == null
                          ? Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: highlight
                                      ? const Color(0xFFD4B06A)
                                      : const Color(
                                          0xFFF1E2CB,
                                        ).withValues(alpha: 0.18),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFFE6D6BF),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            )
                          : Draggable<Person>(
                              data: assigned,
                              feedback: Material(
                                color: Colors.transparent,
                                child: timelineCardBuilder(
                                  assigned,
                                  null,
                                  showLabel: false,
                                ),
                              ),
                              childWhenDragging: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.05),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFF1E2CB,
                                    ).withValues(alpha: 0.18),
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: timelineCardBuilder(
                                assigned,
                                viewportCompact ? null : index + 1,
                                showLabel: false,
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      Widget availableCard(Person person) {
        return Draggable<Person>(
          data: person,
          feedback: Material(
            color: Colors.transparent,
            child: timelineCardBuilder(person, null, showLabel: true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.25,
            child: timelineCardBuilder(person, null, showLabel: true),
          ),
          child: timelineCardBuilder(person, null, showLabel: true),
        );
      }

      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: const Color(0xFFF1E2CB).withValues(alpha: 0.10),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Drag the portraits onto the timeline from earliest to latest.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE6D6BF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: viewportCompact ? 12 : 20),
                Row(
                  children: [
                    const Text(
                      'Early',
                      style: TextStyle(
                        color: Color(0xFFD4B06A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(
                            0xFFD4B06A,
                          ).withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    const Text(
                      'Late',
                      style: TextStyle(
                        color: Color(0xFFD4B06A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: viewportCompact ? 118 : 176,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < currentQuestion.figures.length; i++)
                        timelineSlot(i),
                    ],
                  ),
                ),
                SizedBox(height: viewportCompact ? 6 : 8),
                SizedBox(
                  height: availablePersons.isEmpty
                      ? 32
                      : (viewportCompact ? 108 : 140),
                  child: availablePersons.isEmpty
                      ? Center(
                          child: Text(
                            'All portraits are placed.',
                            style: TextStyle(
                              color: const Color(
                                0xFFE6D6BF,
                              ).withValues(alpha: 0.8),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (
                                int i = 0;
                                i < availablePersons.length;
                                i++
                              ) ...[
                                availableCard(availablePersons[i]),
                                if (i != availablePersons.length - 1)
                                  const SizedBox(width: 12),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  buttonsLocked ||
                      quizOrderSequence.length != currentQuestion.figures.length
                  ? null
                  : onSubmitOrderSequenceAnswer,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD4B06A),
                foregroundColor: const Color(0xFF2D2012),
                padding: EdgeInsets.symmetric(
                  vertical: viewportCompact ? 14 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Check order',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      );
    }

    Widget answerArea() {
      if (currentQuestion.type == QuestionType.orderSequence) {
        return buildOrderSequenceInteraction();
      }

      if (currentQuestion.type == QuestionType.birthCentury ||
          currentQuestion.type == QuestionType.meetingCandidate ||
          currentQuestion.type == QuestionType.northernmostBirthplace ||
          currentQuestion.type == QuestionType.southernmostBirthplace ||
          currentQuestion.type == QuestionType.scientistTheory ||
          currentQuestion.type == QuestionType.scientistFormula ||
          currentQuestion.type == QuestionType.scientistDiscovery ||
          currentQuestion.type == QuestionType.artistWork ||
          currentQuestion.type == QuestionType.artistQuote ||
          currentQuestion.type == QuestionType.workDescription ||
          currentQuestion.type == QuestionType.athleteAchievement ||
          currentQuestion.type == QuestionType.sportStatline ||
          currentQuestion.type == QuestionType.politicianRole ||
          currentQuestion.type == QuestionType.politicianEventMatch ||
          currentQuestion.type == QuestionType.twoCluesOnePerson ||
          currentQuestion.type == QuestionType.multiClueExpert) {
        return buildMeetingCandidateChoices();
      }

      if (currentQuestion.type == QuestionType.closestPair) {
        return buildClosestPairInteraction();
      }

      if (currentQuestion.type == QuestionType.birthplaceMap ||
          currentQuestion.type == QuestionType.mapEventLocation) {
        return buildBirthLocationInteraction();
      }

      if (options.length == 2) {
        if (currentQuestion.type == QuestionType.earlierPerson) {
          return const SizedBox.shrink();
        }
        return Row(
          children: [
            Expanded(child: answerButton(options[0], 0)),
            SizedBox(width: viewportCompact ? 10 : 14),
            Expanded(child: answerButton(options[1], 1)),
          ],
        );
      }

      if (options.length == 4) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: viewportCompact ? 8 : 12,
            crossAxisSpacing: viewportCompact ? 8 : 12,
            childAspectRatio: viewportCompact ? 1.9 : 2.05,
          ),
          itemBuilder: (context, index) {
            return SizedBox(
              width: double.infinity,
              child: answerButton(options[index], index),
            );
          },
        );
      }

      return Column(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            SizedBox(
              width: double.infinity,
              child: answerButton(options[i], i),
            ),
            if (i != options.length - 1)
              SizedBox(height: viewportCompact ? 8 : 12),
          ],
        ],
      );
    }

    final promptBlock = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          currentQuestion.prompt,
          textAlign: TextAlign.center,
          maxLines: viewportCompact ? 3 : null,
          overflow: viewportCompact
              ? TextOverflow.ellipsis
              : TextOverflow.visible,
          style: TextStyle(
            color: const Color(0xFFF8F0E3),
            fontSize: viewportCompact
                ? (isCompact ? 17 : 20)
                : (isCompact ? 22 : 30),
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        if (currentQuestion.supportingLabel != null) ...[
          SizedBox(height: viewportCompact ? 6 : 8),
          Text(
            currentQuestion.supportingLabel!,
            textAlign: TextAlign.center,
            maxLines: viewportCompact ? 2 : null,
            overflow: viewportCompact
                ? TextOverflow.ellipsis
                : TextOverflow.visible,
            style: TextStyle(
              color: const Color(0xFFE6D6BF),
              fontWeight: FontWeight.w700,
              fontSize: viewportCompact ? 12 : 14,
            ),
          ),
        ],
      ],
    );

    final figureWidget = figureBlock();
    final answersWidget = answerArea();

    if (fitViewport) {
      return panelBuilder(
        SizedBox.expand(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              promptBlock,
              SizedBox(height: viewportCompact ? 8 : 16),
              if (currentQuestion.figures.length == 1 &&
                  currentQuestion.type != QuestionType.birthplaceMap &&
                  currentQuestion.type != QuestionType.mapEventLocation)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: figureWidget),
                      SizedBox(height: viewportCompact ? 10 : 18),
                      answersWidget,
                    ],
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if ((currentQuestion.type ==
                                  QuestionType.meetingCandidate ||
                              currentQuestion.type ==
                                  QuestionType.birthCentury) &&
                          currentQuestion.subject != null) ...[
                        figureWidget,
                        SizedBox(height: viewportCompact ? 10 : 18),
                        Expanded(child: answersWidget),
                      ] else if (showDuel) ...[
                        Expanded(child: figureWidget),
                        SizedBox(height: viewportCompact ? 10 : 18),
                        answersWidget,
                      ] else if (currentQuestion.type ==
                              QuestionType.birthplaceMap ||
                          currentQuestion.type ==
                              QuestionType.mapEventLocation ||
                          (currentQuestion.type ==
                                  QuestionType.meetingCandidate &&
                              currentQuestion.subject != null)) ...[
                        Expanded(child: answersWidget),
                      ] else ...[
                        Expanded(child: answersWidget),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return panelBuilder(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          promptBlock,
          SizedBox(height: viewportCompact ? 8 : 16),
          figureWidget,
          SizedBox(height: viewportCompact ? 10 : 18),
          answersWidget,
        ],
      ),
    );
  }
}

class _GuessMapMarker extends StatelessWidget {
  const _GuessMapMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF8C5A43),
            border: Border.all(color: const Color(0xFFF8F0E3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.place_rounded,
            color: Color(0xFFF8F0E3),
            size: 28,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxWidth: 118),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xCC4C3929),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF1E2CB).withValues(alpha: 0.18),
            ),
          ),
          child: const Text(
            'Dein Tipp',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFF8F0E3),
              fontWeight: FontWeight.w700,
              height: 1.1,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPill extends StatelessWidget {
  final String label;

  const _MapPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF1E2CB).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFFF1E2CB).withValues(alpha: 0.12),
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
