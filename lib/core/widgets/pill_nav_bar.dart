import 'package:flutter/material.dart';

import 'package:hms_mobile/core/theme/app_style.dart';

class PillNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const PillNavItem({required this.icon, required this.selectedIcon, required this.label});
}

/// A floating rounded bottom nav bar — replaces the stock Material
/// [NavigationBar] as the app's one tab-bar shape. Sits clear of the
/// screen edges so content can be seen scrolling behind/under it.
class PillNavBar extends StatelessWidget {
  final int currentIndex;
  final List<PillNavItem> items;
  final ValueChanged<int> onTap;

  const PillNavBar({super.key, required this.currentIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: kInk,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: kInk.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              _PillNavButton(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _PillNavButton extends StatelessWidget {
  final PillNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _PillNavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? kCoral : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? item.selectedIcon : item.icon, size: 20, color: selected ? Colors.white : const Color(0xFF98A2C0)),
              if (selected) ...[
                const SizedBox(width: 7),
                Text(
                  item.label,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
