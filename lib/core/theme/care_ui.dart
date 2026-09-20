import 'package:flutter/material.dart';

import 'package:hms_mobile/core/theme/app_style.dart';

/// "Care" design kit — the teal, curved-header look (modelled on the
/// PatientCare Flutter UI kit) used by the patient app and the auth screens.
/// Other roles still use the blue tokens in app_style.dart; they can move
/// over to this kit one role at a time.
const kCare = Color(0xFF1FA99A);
const kCareDark = Color(0xFF15877B);
const kCareDeep = Color(0xFF0E6B61);
const kCareSoft = Color(0xFFE3F5F2);
const kCareBg = Color(0xFFF4F8F8);
const kCareBorder = Color(0xFFE2ECEA);
const kCarePinkBg = Color(0xFFFDE8EF);
const kCarePinkFg = Color(0xFFD6336C);

const kCareShadow = [
  BoxShadow(color: Color(0x0F0E6B61), blurRadius: 18, offset: Offset(0, 6)),
];

const kCareGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kCare, kCareDark],
);

/// Teal theme for a subtree. Pushed routes sit above whatever Theme wraps
/// the home shell, so every patient page wraps itself in this too.
class CareTheme extends StatelessWidget {
  final Widget child;
  const CareTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: kCare, primary: kCare),
        scaffoldBackgroundColor: kCareBg,
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: kCare),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kCare,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kCare,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kCareDark,
            side: const BorderSide(color: kCare, width: 1.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: kCareDark)),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        dividerColor: kCareBorder,
      ),
      child: child,
    );
  }
}

/// Faint circles and plus-marks drawn over the teal header — the kit's
/// "medical pattern" background.
class _CarePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.05), size.width * 0.28, ring);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 1.05), size.width * 0.22, ring);

    final plus = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final p in [
      Offset(size.width * 0.62, size.height * 0.22),
      Offset(size.width * 0.18, size.height * 0.30),
      Offset(size.width * 0.80, size.height * 0.72),
      Offset(size.width * 0.42, size.height * 0.82),
    ]) {
      canvas.drawLine(p.translate(-6, 0), p.translate(6, 0), plus);
      canvas.drawLine(p.translate(0, -6), p.translate(0, 6), plus);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Teal gradient block with the pattern and rounded bottom corners. The
/// home screen and auth screens put their own content inside it.
class CareHeaderBackground extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  const CareHeaderBackground({
    super.key,
    required this.child,
    this.radius = 30,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      child: Container(
        decoration: const BoxDecoration(gradient: kCareGradient),
        child: CustomPaint(
          painter: _CarePatternPainter(),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// App bar for inner pages: teal, centered white title, back arrow.
class CarePageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;

  const CarePageHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return CareHeaderBackground(
      radius: 24,
      padding: EdgeInsets.fromLTRB(8, topInset + 6, 8, 12),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: showBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    )
                  : null,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(
              width: 48,
              child: actions.isEmpty ? null : Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps [CarePageHeader] so it can be used as a Scaffold appBar with the
/// status-bar inset included in its height.
PreferredSizeWidget carePageAppBar(BuildContext context, String title, {List<Widget> actions = const [], bool showBack = true, VoidCallback? onBack}) {
  final topInset = MediaQuery.of(context).padding.top;
  return PreferredSize(
    preferredSize: Size.fromHeight(64 + topInset),
    child: CarePageHeader(title: title, actions: actions, showBack: showBack, onBack: onBack),
  );
}

class CareAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final ImageProvider? image;
  final double radius;
  final bool ring;

  const CareAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.image,
    this.radius = 24,
    this.ring = false,
  });

  String get _initials {
    final parts = name.replaceFirst(RegExp(r'^Dr\.?\s+', caseSensitive: false), '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final provider = image ?? ((imageUrl ?? '').isNotEmpty ? NetworkImage(imageUrl!) : null);
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: kCareSoft,
      backgroundImage: provider,
      onBackgroundImageError: provider == null ? null : (_, __) {},
      child: provider == null
          ? Text(_initials, style: TextStyle(color: kCareDark, fontWeight: FontWeight.w700, fontSize: radius * 0.62))
          : null,
    );
    if (!ring) return avatar;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: avatar,
    );
  }
}

class CareCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  const CareCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            // Filled so the shadow doesn't show through the card body.
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: kCareBorder),
            boxShadow: kCareShadow,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class CareSectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CareSectionTitle({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: kInk))),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kCare)),
          ),
      ],
    );
  }
}

/// Teal icon square that leads every option row and info row.
class CareIconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool filled;

  const CareIconBox({super.key, required this.icon, this.size = 44, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? kCare : kCareSoft,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: filled ? Colors.white : kCareDark, size: size * 0.5),
    );
  }
}

class CareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const CareOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return CareCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      radius: 16,
      child: Row(
        children: [
          CareIconBox(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                ],
              ],
            ),
          ),
          trailing ?? const Icon(Icons.chevron_right_rounded, color: kCare),
        ],
      ),
    );
  }
}

class CareChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  const CareChip({super.key, required this.label, required this.bg, required this.fg, this.icon});

  /// Colours for every status string the patient endpoints return
  /// (appointments, prescriptions, lab orders, invoices).
  factory CareChip.status(String status) {
    final (Color bg, Color fg, String label) = switch (status) {
      'scheduled' => (kCareSoft, kCareDark, 'Scheduled'),
      'active' => (kCareSoft, kCareDark, 'Active'),
      'completed' => (kSuccessBg, kSuccessFg, 'Completed'),
      'paid' => (kSuccessBg, kSuccessFg, 'Paid'),
      'pending' => (kWarningBg, kWarningFg, 'Pending'),
      'partial' => (kWarningBg, kWarningFg, 'Partial'),
      'processing' => (kInfoBg, kInfoFg, 'Processing'),
      'unpaid' => (kCarePinkBg, kCarePinkFg, 'Unpaid'),
      'no_show' => (kCarePinkBg, kCarePinkFg, 'No-show'),
      'cancelled' => (const Color(0xFFF0F2F2), kMuted, 'Cancelled'),
      _ => (const Color(0xFFF0F2F2), kMuted, status.isEmpty ? '—' : status[0].toUpperCase() + status.substring(1)),
    };
    return CareChip(label: label, bg: bg, fg: fg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Full-width scrollable loading / error / empty state — scrollable so it
/// still works as the child of a RefreshIndicator.
class CareStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final bool loading;

  const CareStateView({super.key, required this.icon, required this.title, this.message}) : loading = false;

  const CareStateView.loading({super.key})
      : icon = Icons.hourglass_empty_rounded,
        title = '',
        message = null,
        loading = true;

  factory CareStateView.error(String message) =>
      CareStateView(icon: Icons.wifi_off_rounded, title: "Couldn't load", message: message);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 140),
          Center(child: CircularProgressIndicator(color: kCare)),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 90),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: kCareSoft, shape: BoxShape.circle),
            child: Icon(icon, color: kCare, size: 38),
          ),
        ),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 13.5, height: 1.4)),
        ],
      ],
    );
  }
}

class CarePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const CarePrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: kCare,
          disabledBackgroundColor: kCare.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
                  Text(label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}

InputDecoration careFieldDecoration(String label, {required String hint, required IconData icon}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(color: kInk, fontSize: 13, fontWeight: FontWeight.w600),
    floatingLabelStyle: const TextStyle(color: kCareDark, fontSize: 13, fontWeight: FontWeight.w700),
    hintStyle: const TextStyle(color: Color(0xFFAEB8B6), fontSize: 14.5),
    prefixIcon: Icon(icon, color: kCare, size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(kCareBorder),
    enabledBorder: border(kCareBorder),
    focusedBorder: border(kCare, 1.6),
    errorBorder: border(const Color(0xFFB3261E), 1.2),
    focusedErrorBorder: border(const Color(0xFFB3261E), 1.6),
    errorStyle: const TextStyle(fontSize: 12),
  );
}

/// Selectable pill used for time slots, visit types and gender.
class CareChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const CareChoicePill({super.key, required this.label, required this.selected, this.enabled = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kCare : (enabled ? Colors.white : const Color(0xFFF1F3F3)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? kCare : (enabled ? kCareBorder : Colors.transparent)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : (enabled ? kInk : const Color(0xFFBFC5C3)),
            decoration: enabled ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}

class CareNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const CareNavItem({required this.icon, required this.activeIcon, required this.label});
}

/// White bottom bar with a raised teal action button in the middle.
class CareBottomNav extends StatelessWidget {
  final List<CareNavItem> items; // exactly 4 — two either side of the center button
  final int? selectedIndex; // index into [items], or null when none is active
  final ValueChanged<int> onSelected;
  final IconData centerIcon;
  final VoidCallback onCenterTap;

  const CareBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.centerIcon,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget item(int i) {
      final active = selectedIndex == i;
      final it = items[i];
      return Expanded(
        child: InkWell(
          onTap: () => onSelected(i),
          borderRadius: BorderRadius.circular(16),
          // Full bar height so taps on the label (not just the icon) count.
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(active ? it.activeIcon : it.icon, color: active ? kCare : const Color(0xFF9AA6A4), size: 24),
                const SizedBox(height: 3),
                Text(
                  it.label,
                  style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? kCare : const Color(0xFF9AA6A4)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              item(0),
              item(1),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: onCenterTap,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: kCareGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: kCareSoft, width: 4),
                        boxShadow: const [BoxShadow(color: Color(0x551FA99A), blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: Icon(centerIcon, color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),
              item(2),
              item(3),
            ],
          ),
        ),
      ),
    );
  }
}
