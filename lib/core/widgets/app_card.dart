import 'package:flutter/material.dart';

import 'package:hms_mobile/core/theme/app_style.dart';

/// The app's one "floating surface" shape: white on the warm page
/// background, lifted with a soft shadow instead of a flat border. Used
/// wherever a screen needs to group content into a card.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: kInk.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: card),
    );
  }
}

/// A small pill-shaped status indicator: a colored dot plus a label,
/// matching the tinted bg/fg pairs in `app_style.dart` (kSuccessBg/Fg etc).
class StatusPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const StatusPill({super.key, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
