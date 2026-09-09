import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hms_mobile/core/theme/app_style.dart';

/// The app's one primary call-to-action shape: a full-width gradient pill
/// with a soft tinted shadow. Used for every "main action" button (submit
/// a form, book, save) so those all read as the same control wherever they
/// appear, instead of each screen picking its own button radius/color.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: disabled
              ? null
              : const LinearGradient(colors: [kTeal, kTealDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          color: disabled ? kFieldFill : null,
          boxShadow: disabled
              ? null
              : [BoxShadow(color: kTealDark.withValues(alpha: 0.32), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 8)],
                        Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: disabled ? kMuted : Colors.white,
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
