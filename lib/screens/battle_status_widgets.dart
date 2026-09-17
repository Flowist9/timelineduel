import 'package:flutter/material.dart';

import '../design/app_theme.dart';

class BattleStatusItem {
  final IconData icon;
  final String label;

  const BattleStatusItem({required this.icon, required this.label});
}

class BattleStatusRow extends StatelessWidget {
  final List<BattleStatusItem> items;

  const BattleStatusRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AppPalette.ink.withValues(alpha: 0.32),
                border: Border.all(
                  color: AppPalette.gold.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 16, color: AppPalette.gold),
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: Color(0xFFF7ECDD),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
