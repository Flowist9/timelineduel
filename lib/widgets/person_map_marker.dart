import 'package:flutter/material.dart';

import '../models/person.dart';
import 'person_portrait.dart';

class PersonMapMarker extends StatelessWidget {
  final Person person;
  final bool unlocked;
  final VoidCallback? onTap;

  const PersonMapMarker({
    super.key,
    required this.person,
    required this.unlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: unlocked
                    ? const Color(0xFFD4B06A)
                    : const Color(0xFFF1E2CB).withValues(alpha: 0.28),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: PersonPortrait(
                person: person,
                width: 50,
                height: 50,
                borderRadius: 29,
                variant: PersonImageVariant.portrait,
                obscured: !unlocked,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 118),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: unlocked
                  ? const Color(0xCC77552F)
                  : const Color(0xCC4C3929),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unlocked
                    ? const Color(0xFFD4B06A)
                    : const Color(0xFFF1E2CB).withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              unlocked ? person.name : '???',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF8F0E3),
                fontWeight: FontWeight.w700,
                height: 1.1,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
