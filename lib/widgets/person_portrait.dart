import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/person.dart';

enum PersonImageVariant { portrait, vs }

class PersonPortrait extends StatelessWidget {
  final Person person;
  final double? width;
  final double? height;
  final double borderRadius;
  final PersonImageVariant variant;
  final bool obscured;

  const PersonPortrait({
    super.key,
    required this.person,
    this.width,
    this.height,
    this.borderRadius = 20,
    this.variant = PersonImageVariant.portrait,
    this.obscured = false,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = variant == PersonImageVariant.vs
        ? person.vsAsset
        : person.portraitAsset;
    final rawWidth = width ?? (height ?? 72);
    final rawHeight = height ?? (width ?? 72);
    final resolvedWidth = rawWidth.isFinite ? rawWidth : 72.0;
    final resolvedHeight = rawHeight.isFinite ? rawHeight : 72.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: resolvedWidth,
        height: resolvedHeight,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: variant == PersonImageVariant.vs
              ? Alignment.topCenter
              : Alignment.center,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (obscured) {
              return _buildObscuredImage(child);
            }
            return child;
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallback(resolvedWidth, resolvedHeight);
          },
        ),
      ),
    );
  }

  Widget _buildObscuredImage(Widget child) {
    final accent = switch (person.category) {
      Category.politician => const Color(0xFF9B6A43),
      Category.scientist => const Color(0xFF8D7858),
      Category.artist => const Color(0xFFB07A54),
      Category.athlete => const Color(0xFF6F6A45),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 0.08,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: child,
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xF217110C), Color(0xEC0F0A07)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [accent.withValues(alpha: 0.16), const Color(0x00000000)],
              center: const Alignment(0, -0.2),
              radius: 0.95,
            ),
          ),
        ),
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF110C09).withValues(alpha: 0.86),
              border: Border.all(
                color: const Color(0xFFF1E2CB).withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.person_rounded,
                size: 42,
                color: const Color(0xFFF1E2CB).withValues(alpha: 0.78),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFF1E2CB).withValues(alpha: 0.10),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0x09000000), Color(0x7A000000)],
              center: Alignment.center,
              radius: 1.05,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallback(double resolvedWidth, double resolvedHeight) {
    final color = switch (person.category) {
      Category.politician => const Color(0xFF9B6A43),
      Category.scientist => const Color(0xFF8D7858),
      Category.artist => const Color(0xFFB07A54),
      Category.athlete => const Color(0xFF6F6A45),
    };

    final icon = switch (person.category) {
      Category.politician => Icons.account_balance_rounded,
      Category.scientist => Icons.biotech_rounded,
      Category.artist => Icons.palette_rounded,
      Category.athlete => Icons.emoji_events_rounded,
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.black, 0.45)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(
                      alpha: variant == PersonImageVariant.vs ? 0.18 : 0.10,
                    ),
                    Colors.transparent,
                  ],
                  center: const Alignment(0, -0.4),
                  radius: 0.9,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: -resolvedWidth * 0.12,
            child: Container(
              width: resolvedWidth * 0.45,
              height: resolvedWidth * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF5EAD7).withValues(alpha: 0.14),
                  width: 2,
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              variant == PersonImageVariant.vs ? Icons.person_rounded : icon,
              color: const Color(0xFFF5EAD7).withValues(alpha: 0.88),
              size:
                  resolvedHeight *
                  (variant == PersonImageVariant.vs ? 0.34 : 0.26),
            ),
          ),
          if (variant == PersonImageVariant.vs)
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.black.withValues(alpha: 0.22),
                  border: Border.all(
                    color: const Color(0xFFF5EAD7).withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  'Bild folgt',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFF5EAD7).withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                    fontSize: resolvedHeight * 0.07,
                  ),
                ),
              ),
            )
          else
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                person.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFF5EAD7).withValues(alpha: 0.92),
                  fontSize: resolvedHeight * 0.10,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
