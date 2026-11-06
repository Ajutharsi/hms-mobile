import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_palette.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/theme_controller.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

/// "Care" design kit — the teal, curved-header look (modelled on the
/// PatientCare Flutter UI kit) used by the patient app and the auth screens.
/// Other roles still use the blue tokens in app_style.dart; they can move
/// over to this kit one role at a time.
// The colour tokens now read from the palette the user picked in
// Appearance (see CareThemeController), so changing the colour repaints
// every screen. They stay top-level names so call sites read the same.
Color get kCare => CareColors.primary;
Color get kCareDark => CareColors.dark;
Color get kCareDeep => CareColors.deep;
Color get kCareSoft => CareColors.soft;
Color get kCareBg => CareColors.background;
Color get kCareBorder => CareColors.border;
Color get kCareOn => CareColors.onPrimary;
Color get kCarePinkBg => CareColors.alertBg;
Color get kCarePinkFg => CareColors.alertFg;

/// Decorative background shapes — the blobs behind the auth illustration.
/// They were fixed pale blues, so they stayed blue once the user picked
/// another colour in Appearance; as tints of the brand they follow it.
Color get kCareBlob => kCare.withValues(alpha: 0.12);
Color get kCareBlobSoft => kCare.withValues(alpha: 0.08);

List<BoxShadow> get kCareShadow => CareColors.shadow;

/// The same shadow at another depth, for a card or sheet that should lift
/// further off the page. Follows the brand colour like [kCareShadow].
List<BoxShadow> careShadow({double blur = 18, double dy = 6, double alpha = 0.06}) =>
    CareColors.shadowOf(blur: blur, dy: dy, alpha: alpha);

LinearGradient get kCareGradient => CareColors.gradient;

/// Hands the current palette down the tree. Widgets read it through
/// [CarePaletteScope.of], which registers them as dependents — so even a
/// cached `const` widget repaints when the colour changes.
class CarePaletteScope extends InheritedWidget {
  final CarePalette palette;

  const CarePaletteScope({super.key, required this.palette, required super.child});

  static CarePalette of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<CarePaletteScope>()?.palette ?? CareColors.current;

  @override
  bool updateShouldNotify(CarePaletteScope oldWidget) => oldWidget.palette.seed != palette.seed;
}

/// Theme for a subtree, in the colour the user picked. Pushed routes sit
/// above whatever Theme wraps the home shell, so every page wraps itself
/// in this; it also watches the controller, so a colour change repaints
/// whatever is on screen.
class CareTheme extends StatelessWidget {
  final Widget child;
  const CareTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<CareThemeController>().palette;
    final base = Theme.of(context);

    return CarePaletteScope(
      palette: palette,
      child: Theme(
        data: base.copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: palette.primary, primary: palette.primary),
          scaffoldBackgroundColor: palette.background,
          progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.primary),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.field)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.field)),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.dark,
              side: BorderSide(color: palette.primary, width: 1.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.field)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: palette.dark)),
          snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
          dividerColor: palette.border,
        ),
        child: child,
      ),
    );
  }
}

/// Registers the caller as a dependent of [CarePaletteScope] so it
/// repaints when the user picks another colour. The kCare* getters read a
/// global palette and carry no context of their own, so anything painting
/// with them — kit widgets and screens alike — must call this in build().
void watchCarePalette(BuildContext context) => CarePaletteScope.of(context);

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
    watchCarePalette(context);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      child: Container(
        decoration: BoxDecoration(gradient: kCareGradient),
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
  /// Nullable so a screen can pass `condition ? null : [...]` directly.
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;

  const CarePageHeader({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
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
              child: (actions == null || actions!.isEmpty) ? null : Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps [CarePageHeader] so it can be used as a Scaffold appBar with the
/// status-bar inset included in its height.
PreferredSizeWidget carePageAppBar(BuildContext context, String title, {List<Widget>? actions, bool showBack = true, VoidCallback? onBack}) {
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
    watchCarePalette(context);
    final provider = image ?? ((imageUrl ?? '').isNotEmpty ? NetworkImage(imageUrl!) : null);
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: kCareSoft,
      backgroundImage: provider,
      onBackgroundImageError: provider == null ? null : (_, __) {},
      child: provider == null ? Text(_initials, style: TextStyle(color: kCareDark, fontWeight: FontWeight.w700, fontSize: radius * 0.62)) : null,
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
    watchCarePalette(context);
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
    watchCarePalette(context);
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: kInk))),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kCare)),
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
    watchCarePalette(context);
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

/// One row in a role's navigation drawer.
///
/// Every role used to hand-roll this as a bare [ListTile], which gave the
/// menu no sense of touch: no pressed state, no idea which section you are
/// on, just the stock grey splash. Here the row answers the finger -- the
/// icon box fills, the row tints, an accent bar slides in on the left and
/// the chevron nudges -- and [selected] keeps that look for the section
/// actually open.
class CareDrawerTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CareDrawerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  State<CareDrawerTile> createState() => _CareDrawerTileState();
}

class _CareDrawerTileState extends State<CareDrawerTile> {
  static const _motion = Duration(milliseconds: 160);
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final active = widget.selected || _pressed;

    return Semantics(
      selected: widget.selected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(CareRadius.field),
            splashColor: kCare.withValues(alpha: 0.10),
            highlightColor: Colors.transparent,
            onHighlightChanged: (down) => setState(() => _pressed = down),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: _motion,
              curve: Curves.easeOut,
              padding: const EdgeInsets.fromLTRB(6, 7, 10, 7),
              decoration: BoxDecoration(
                color: active ? kCareSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(CareRadius.field),
              ),
              child: Row(
                children: [
                  // The accent bar grows out of the left edge rather than
                  // appearing, so a quick tap still reads as movement.
                  AnimatedContainer(
                    duration: _motion,
                    curve: Curves.easeOut,
                    width: active ? 3 : 0,
                    height: 22,
                    margin: EdgeInsets.only(right: active ? 7 : 10),
                    decoration: BoxDecoration(
                      color: kCare,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  CareIconBox(icon: widget.icon, size: 34, filled: active),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: _motion,
                      style: CareText.titleMdMedium.copyWith(
                        color: active ? kCareDark : null,
                        fontWeight: widget.selected ? FontWeight.w700 : null,
                      ),
                      child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  AnimatedSlide(
                    duration: _motion,
                    curve: Curves.easeOut,
                    offset: active ? const Offset(0.18, 0) : Offset.zero,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: active ? kCare : kCareHintQuiet,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    watchCarePalette(context);
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
                Text(title, style: CareText.titleLg),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: CareText.mutedSm),
                ],
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right_rounded, color: kCare),
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
      'cancelled' => (kCareNeutralBg, kMuted, 'Cancelled'),
      _ => (kCareNeutralBg, kMuted, status.isEmpty ? '—' : status[0].toUpperCase() + status.substring(1)),
    };
    return CareChip(label: label, bg: bg, fg: fg);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(CareRadius.panel)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: CareText.chip(fg)),
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

  /// False when the view is already inside a scrollable — a list that has
  /// stat tiles above it still wants to show those, so the empty state has
  /// to sit in the list rather than replace it.
  final bool scrollable;

  const CareStateView({super.key, required this.icon, required this.title, this.message})
      : loading = false,
        scrollable = true;

  /// The same state, laid out to be dropped into an existing list.
  const CareStateView.inline({super.key, required this.icon, required this.title, this.message})
      : loading = false,
        scrollable = false;

  const CareStateView.loading({super.key})
      : icon = Icons.hourglass_empty_rounded,
        title = '',
        message = null,
        loading = true,
        scrollable = true;

  factory CareStateView.error(String message) => CareStateView(icon: Icons.wifi_off_rounded, title: "Couldn't load", message: message);

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    if (loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Center(child: CircularProgressIndicator(color: kCare)),
        ],
      );
    }

    final body = <Widget>[
      SizedBox(height: scrollable ? 90 : 40),
      Center(
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: kCareSoft, shape: BoxShape.circle),
          child: Icon(icon, color: kCare, size: 38),
        ),
      ),
      const SizedBox(height: 18),
      Text(title, textAlign: TextAlign.center, style: CareText.titleXxl),
      if (message != null) ...[
        const SizedBox(height: 6),
        Text(message!, textAlign: TextAlign.center, style: CareText.bodyMdMuted),
      ],
    ];

    if (!scrollable) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: body),
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: body,
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
    watchCarePalette(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: kCare,
          disabledBackgroundColor: kCare.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.field)),
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
        borderRadius: BorderRadius.circular(CareRadius.field),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(color: kInk, fontSize: 13, fontWeight: FontWeight.w600),
    floatingLabelStyle: TextStyle(color: kCareDark, fontSize: 13, fontWeight: FontWeight.w700),
    hintStyle: const TextStyle(color: kCareHint, fontSize: 14.5),
    prefixIcon: Icon(icon, color: kCare, size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(kCareBorder),
    enabledBorder: border(kCareBorder),
    focusedBorder: border(kCare, 1.6),
    errorBorder: border(kDangerText, 1.2),
    focusedErrorBorder: border(kDangerText, 1.6),
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
    watchCarePalette(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kCare : (enabled ? Colors.white : kCareDisabledBg),
          borderRadius: BorderRadius.circular(CareRadius.control),
          border: Border.all(color: selected ? kCare : (enabled ? kCareBorder : Colors.transparent)),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : (enabled ? kInk : kCareDisabledFg),
              decoration: enabled ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }
}

/// Counter shown inside a header — turns to the alert colour when its
/// number needs attention (overdue rounds, unpaid bills, pending orders).
class CareAlertPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool urgent;
  final VoidCallback onTap;

  const CareAlertPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.urgent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: urgent ? kCarePinkBg : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(CareRadius.field),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: urgent ? kCarePinkFg : Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: urgent ? kCarePinkFg : Colors.white),
              ),
            ),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: urgent ? kCarePinkFg : Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// One number on a dashboard: icon, value, label and a short caption.
class CareStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool alert;

  const CareStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return CareCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: alert ? kCarePinkBg : kCareSoft, borderRadius: BorderRadius.circular(CareRadius.chip)),
                child: Icon(icon, color: alert ? kCarePinkFg : kCareDark, size: 16),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  trend,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 9.5, color: alert ? kCarePinkFg : kMuted, fontWeight: alert ? FontWeight.w700 : FontWeight.w400),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kInk)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.mutedXxsMedium),
        ],
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
    watchCarePalette(context);
    Widget item(int i) {
      final active = selectedIndex == i;
      final it = items[i];
      return Expanded(
        child: InkWell(
          onTap: () => onSelected(i),
          borderRadius: BorderRadius.circular(CareRadius.card),
          // Full bar height so taps on the label (not just the icon) count.
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(active ? it.activeIcon : it.icon, color: active ? kCare : kCareHintQuiet, size: 24),
                const SizedBox(height: 3),
                Text(
                  it.label,
                  style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? kCare : kCareHintQuiet),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(CareRadius.sheet)),
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
                        boxShadow: [BoxShadow(color: kCare.withValues(alpha: 0.33), blurRadius: 12, offset: const Offset(0, 4))],
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
