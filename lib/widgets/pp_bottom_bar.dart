import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';

class PPNavItem {
  const PPNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

const kPPNavItems = <PPNavItem>[
  PPNavItem(LucideIcons.sprout, 'Home'),
  PPNavItem(LucideIcons.layoutGrid, 'Plants'),
  PPNavItem(LucideIcons.bookOpen, 'Journal'),
  PPNavItem(LucideIcons.user, 'Profile'),
];

/// The black nav pill + floating lime scan button, exactly as the mockups.
class PPBottomBar extends StatelessWidget {
  const PPBottomBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onScan,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
        child: SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: PP.ink,
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < kPPNavItems.length; i++)
                        if (i == currentIndex)
                          _ActiveChip(item: kPPNavItems[i])
                        else
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onSelect(i),
                              child: Icon(
                                kPPNavItems[i].icon,
                                size: 21,
                                color: PP.bone.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onScan,
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    color: PP.lime,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: PP.forest.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.scan, size: 24, color: PP.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.item});
  final PPNavItem item;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 17, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration:
                  const BoxDecoration(color: PP.pale1, shape: BoxShape.circle),
              child: Icon(item.icon, size: 16, color: PP.forest),
            ),
            const SizedBox(width: 9),
            Text(
              item.label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: PP.ink),
            ),
          ],
        ),
      ),
    );
  }
}
