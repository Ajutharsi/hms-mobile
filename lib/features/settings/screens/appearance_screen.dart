import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_palette.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/core/theme/theme_controller.dart';

/// The app's colour customizer — the counterpart of the web template
/// customizer's colour control. Pick a preset or mix your own; the choice
/// applies immediately and is remembered on this device.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final controller = context.watch<CareThemeController>();

    return CareTheme(
      child: Scaffold(
        appBar: carePageAppBar(context, 'Appearance'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            const _Preview(),
            const SizedBox(height: 22),
            const CareSectionTitle(title: 'Theme colour'),
            const SizedBox(height: 12),
            _Presets(
              selected: controller.seed,
              onPick: controller.setSeed,
            ),
            const SizedBox(height: 22),
            const CareSectionTitle(title: 'Custom colour'),
            const SizedBox(height: 4),
            const Text(
              'Slide to mix your own shade. Text colour adjusts itself so it stays readable.',
              style: TextStyle(fontSize: 12.5, color: kMuted),
            ),
            const SizedBox(height: 12),
            _CustomPicker(seed: controller.seed, onChanged: controller.setSeed),
            const SizedBox(height: 22),
            if (!controller.isDefault)
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: controller.resetToDefault,
                  icon: const Icon(Icons.restart_alt_rounded, size: 19),
                  label: const Text('Reset to default colour', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A miniature of the app's own furniture, so the choice can be judged
/// before leaving the screen.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return CareCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: CareHeaderBackground(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Row(
                children: [
                  const CareAvatar(name: 'Preview', radius: 20, ring: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello 👋', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                        const Text('Your app', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    const CareIconBox(icon: Icons.favorite_rounded, size: 38),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sample card', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
                          Text('How lists will look', style: TextStyle(fontSize: 12, color: kMuted)),
                        ],
                      ),
                    ),
                    CareChip(label: 'Scheduled', bg: kCareSoft, fg: kCareDark),
                  ],
                ),
                const SizedBox(height: 14),
                CarePrimaryButton(label: 'Primary button', onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Presets extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onPick;

  const _Presets({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final preset in CarePalette.presets)
          _Swatch(
            color: preset.color,
            label: preset.name,
            selected: preset.color.toARGB32() == selected.toARGB32(),
            onTap: () => onPick(preset.color),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({required this.color, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? kInk : Colors.white, width: selected ? 2.5 : 2),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: CarePalette.fromSeed(color).onPrimary, size: 24)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: selected ? kInk : kMuted, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hue + depth sliders — enough control to match a brand colour without
/// letting anyone build an unreadable one.
class _CustomPicker extends StatelessWidget {
  final Color seed;
  final ValueChanged<Color> onChanged;

  const _CustomPicker({required this.seed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final hsl = HSLColor.fromColor(seed);

    return CareCard(
      child: Column(
        children: [
          _SliderRow(
            label: 'Hue',
            value: hsl.hue,
            max: 360,
            gradient: const LinearGradient(colors: [
              Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
              Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000),
            ]),
            onChanged: (v) => onChanged(hsl.withHue(v).toColor()),
          ),
          const SizedBox(height: 10),
          _SliderRow(
            label: 'Depth',
            value: hsl.lightness.clamp(0.20, 0.65),
            min: 0.20,
            max: 0.65,
            gradient: LinearGradient(colors: [
              hsl.withLightness(0.20).toColor(),
              hsl.withLightness(0.65).toColor(),
            ]),
            onChanged: (v) => onChanged(hsl.withLightness(v).toColor()),
          ),
          const SizedBox(height: 10),
          _SliderRow(
            label: 'Strength',
            value: hsl.saturation.clamp(0.15, 1.0),
            min: 0.15,
            gradient: LinearGradient(colors: [
              hsl.withSaturation(0.15).toColor(),
              hsl.withSaturation(1).toColor(),
            ]),
            onChanged: (v) => onChanged(hsl.withSaturation(v).toColor()),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final Gradient gradient;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.gradient,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
  });

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(label, style: const TextStyle(fontSize: 12.5, color: kMuted, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(6)),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 10,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: Colors.white,
                  overlayColor: kCare.withValues(alpha: 0.15),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
                ),
                child: Slider(value: value, min: min, max: max, onChanged: onChanged),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
