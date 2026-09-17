import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/person.dart';
import '../models/person_rarity.dart';
import 'person_portrait.dart';

class RewardCardRevealDialog extends StatefulWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String confirmLabel;
  final IconData accentIcon;
  final Color accentColor;
  final String accentLabel;
  final Person? person;
  final bool showOpeningPhase;
  final String openingEyebrow;
  final String openingTitle;
  final String openingBody;

  const RewardCardRevealDialog({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.accentIcon,
    required this.accentColor,
    required this.accentLabel,
    required this.person,
    this.showOpeningPhase = false,
    this.openingEyebrow = 'Preparing reveal',
    this.openingTitle = 'Charging reward',
    this.openingBody = 'Your reward is lining up and about to reveal itself.',
  });

  @override
  State<RewardCardRevealDialog> createState() => _RewardCardRevealDialogState();
}

class _RewardCardRevealDialogState extends State<RewardCardRevealDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _revealed = !widget.showOpeningPhase;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    if (widget.showOpeningPhase) {
      _controller.repeat();
      Future<void>.delayed(const Duration(milliseconds: 1300), () {
        if (!mounted) return;
        _controller.stop();
        setState(() => _revealed = true);
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.25),
                  radius: 1.05,
                  colors: [
                    widget.accentColor.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.86),
                    Colors.black.withValues(alpha: 0.96),
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final orbit = _controller.value * math.pi * 2;
                  return Stack(
                    children: [
                      _lightOrb(
                        left: 30 + (math.sin(orbit) * 18),
                        top: 90 + (math.cos(orbit) * 10),
                        size: 72,
                        opacity: 0.16,
                      ),
                      _lightOrb(
                        right: 26 + (math.cos(orbit * 0.9) * 20),
                        top: 150 + (math.sin(orbit * 1.2) * 14),
                        size: 92,
                        opacity: 0.12,
                      ),
                      _lightOrb(
                        left: 70 + (math.sin(orbit * 1.4) * 12),
                        bottom: 180 + (math.cos(orbit) * 10),
                        size: 56,
                        opacity: 0.1,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _revealed ? _buildReveal(context) : _buildOpening(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpening() {
    return Column(
      key: const ValueKey('reward-opening'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.openingEyebrow,
          style: const TextStyle(
            color: Color(0xFFD4B06A),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.openingTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF8F0E3),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.openingBody,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFE0CFB5), height: 1.45),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 360,
          width: 240,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final wave = math.sin(_controller.value * math.pi * 2);
              final pulse = 1 + (wave * 0.06);
              final glow = 18 + (wave * 8);
              return Transform.scale(
                scale: pulse,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFF17386D), Color(0xFF09162D)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFD4B06A,
                            ).withValues(alpha: 0.12),
                            blurRadius: glow,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Transform.rotate(
                      angle: _controller.value * math.pi * 2,
                      child: Container(
                        width: 154,
                        height: 154,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFF1E2CB,
                            ).withValues(alpha: 0.16),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, 18),
                      child: Transform.rotate(
                        angle: 0.08 * math.sin(_controller.value * math.pi * 2),
                        child: _buildCardBack(
                          _rarityColor(
                            widget.person?.rarity ?? PersonRarity.rare,
                          ),
                          height: 290,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReveal(BuildContext context) {
    final person = widget.person;
    if (person == null) {
      return Column(
        key: const ValueKey('reward-empty'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.accentColor,
            ),
            child: Icon(
              widget.accentIcon,
              color: const Color(0xFFF8F0E3),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.eyebrow,
            style: const TextStyle(
              color: Color(0xFFD4B06A),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF8F0E3),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFE0CFB5), height: 1.45),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD4B06A),
                foregroundColor: const Color(0xFF2A1600),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                widget.confirmLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final rarityColor = _rarityColor(person.rarity);

    return Column(
      key: const ValueKey('reward-card'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.eyebrow,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFD4B06A),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF8F0E3),
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFE0CFB5), height: 1.4),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 400,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1380),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                final clamped = value.clamp(0.0, 1.0);
                final eased = Curves.easeOutBack.transform(clamped);
                final sideFlight = Curves.easeOutExpo.transform(clamped);
                final lift = Curves.easeOutCubic.transform(clamped);
                final flipPhase = ((clamped - 0.42) / 0.58).clamp(0.0, 1.0);
                final rotationY =
                    1.45 * (1 - Curves.easeOutCubic.transform(flipPhase));
                final wobble =
                    math.sin(clamped * math.pi * 5.5) * (1 - clamped) * 0.13;
                final showFront = rotationY <= (math.pi / 2);
                return Opacity(
                  opacity: Curves.easeOut.transform(
                    (clamped - 0.08).clamp(0.0, 1.0),
                  ),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.00145)
                      ..translate(
                        220.0 * (1 - sideFlight),
                        185.0 * (1 - lift),
                        0.0,
                      )
                      ..rotateZ((-0.28 * (1 - eased)) + wobble)
                      ..rotateY(rotationY)
                      ..rotateX(-0.08 * (1 - eased))
                      ..scale(0.58 + (0.42 * eased)),
                    child: showFront
                        ? child!
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildCardBack(rarityColor, height: 320),
                          ),
                  ),
                );
              },
              child: _buildCardFront(person, rarityColor, height: 320),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _RewardChip(
                color: widget.accentColor,
                icon: widget.accentIcon,
                label: widget.accentLabel,
              ),
              _RewardChip(
                color: rarityColor,
                icon: Icons.stars_rounded,
                label: person.rarity.name.toUpperCase(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1050),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.black.withValues(alpha: 0.34),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              person.hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD8CBB8),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD4B06A),
            foregroundColor: const Color(0xFF1B100A),
          ),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(
            widget.confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Color _rarityColor(PersonRarity rarity) {
    switch (rarity) {
      case PersonRarity.common:
        return const Color(0xFFB7BDC9);
      case PersonRarity.rare:
        return const Color(0xFF6FA8FF);
      case PersonRarity.epic:
        return const Color(0xFFD98CFF);
      case PersonRarity.legendary:
        return const Color(0xFFD4B06A);
    }
  }

  Widget _buildCardFront(
    Person person,
    Color rarityColor, {
    double height = 248,
  }) {
    final width = height * 0.7;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            PersonPortrait(person: person, width: width, height: height),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.14),
                      Colors.black.withValues(alpha: 0.42),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 560),
                  curve: Curves.easeOutCubic,
                  builder: (context, flashValue, _) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.25),
                          radius: 0.9,
                          colors: [
                            Colors.white.withValues(
                              alpha: (1 - flashValue) * 0.46,
                            ),
                            widget.accentColor.withValues(
                              alpha: (1 - flashValue) * 0.24,
                            ),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.26, 1],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: rarityColor.withValues(alpha: 0.18),
                    border: Border.all(
                      color: rarityColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    person.rarity.name.toUpperCase(),
                    style: TextStyle(
                      color: rarityColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.black.withValues(alpha: 0.36),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        color: Color(0xFFF8F0E3),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(widget.accentIcon, color: const Color(0xFFD4B06A)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${widget.accentLabel} | ${person.birthYear}',
                            style: const TextStyle(
                              color: Color(0xFFF7ECDD),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(Color rarityColor, {double height = 248}) {
    final width = height * 0.7;
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Color.lerp(widget.accentColor, Colors.white, 0.14)!,
              Color.lerp(widget.accentColor, const Color(0xFF12274A), 0.32)!,
              const Color(0xFF09162D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFF1E2CB).withValues(alpha: 0.18),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.25),
                    radius: 1.1,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFF7ECDD).withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.accentIcon,
                    color: const Color(0xFFF8F0E3),
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.accentLabel,
                    style: const TextStyle(
                      color: Color(0xFFF8F0E3),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.black.withValues(alpha: 0.18),
                      border: Border.all(
                        color: const Color(0xFFF7ECDD).withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Text(
                      'Reward Card',
                      style: TextStyle(
                        color: Color(0xFFE6D8C3),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lightOrb({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              widget.accentColor.withValues(alpha: opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _RewardChip({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
