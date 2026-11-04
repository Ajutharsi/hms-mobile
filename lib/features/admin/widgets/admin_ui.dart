import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

/// The pieces every admin section is built from.
///
/// All twelve look the same on purpose: a titled header, a row of totals,
/// a filter, a list of cards, and a form in a sheet. Writing that once
/// means a new section is a list of fields rather than another 300 lines
/// of scaffolding — and it is what kept the nurse and front-desk screens
/// from drifting apart once they shared CareStateView.

/// A number above a word — the strip under an admin screen's header.
class AdminStat extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  const AdminStat({super.key, required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Expanded(
      child: Column(
        children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: CareText.h3, fontWeight: CareText.heavy, color: color ?? kInk)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: CareText.mutedXs),
        ],
      ),
    );
  }
}

class AdminStatRow extends StatelessWidget {
  final List<AdminStat> stats;
  const AdminStatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: CareCard(child: Row(children: stats)),
    );
  }
}

/// A row of single-choice chips. An empty [value] means "all".
class AdminFilterChips extends StatelessWidget {
  final List<({String value, String label})> options;
  final String value;
  final ValueChanged<String> onChanged;
  const AdminFilterChips({super.key, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final option = options[i];
          final selected = option.value == value;
          return ChoiceChip(
            label: Text(option.label,
                style: TextStyle(
                  fontSize: CareText.sm,
                  fontWeight: CareText.medium,
                  color: selected ? kCareOn : kInk,
                )),
            selected: selected,
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: kCare,
            side: BorderSide(color: selected ? kCare : kCareBorder),
            onSelected: (_) => onChanged(option.value),
          );
        },
      ),
    );
  }
}

/// A list row: a title, a couple of grey lines under it, a trailing chip,
/// and an optional overflow menu.
class AdminCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? detail;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeBg;
  final VoidCallback? onTap;
  final List<({String label, IconData icon, VoidCallback onTap, bool destructive})> actions;

  const AdminCard({
    super.key,
    required this.title,
    this.subtitle,
    this.detail,
    this.badge,
    this.badgeColor,
    this.badgeBg,
    this.onTap,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: CareCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: CareText.titleMd),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.mutedSm),
                  ],
                  if (detail != null) ...[
                    const SizedBox(height: 6),
                    Text(detail!, maxLines: 2, overflow: TextOverflow.ellipsis, style: CareText.mutedXs),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: badgeBg ?? kCareSoft, borderRadius: BorderRadius.circular(CareRadius.pill)),
                child: Text(badge!, style: CareText.chip(badgeColor ?? kCareDark, size: CareText.xs)),
              ),
            ],
            if (actions.isNotEmpty)
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: kCareChevron),
                onSelected: (i) => actions[i].onTap(),
                itemBuilder: (context) => [
                  for (var i = 0; i < actions.length; i++)
                    PopupMenuItem(
                      value: i,
                      child: Row(
                        children: [
                          Icon(actions[i].icon, size: 18, color: actions[i].destructive ? kDangerText : kInk),
                          const SizedBox(width: 10),
                          Text(actions[i].label,
                              style: TextStyle(
                                fontSize: CareText.md,
                                color: actions[i].destructive ? kDangerText : kInk,
                              )),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The whole screen: header, totals, filter, list, and a create button.
class AdminSectionScaffold extends StatelessWidget {
  final String title;
  final bool isLoading;
  final String? error;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Future<void> Function() onRefresh;
  final Widget? header;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptyMessage;
  final String? createLabel;
  final VoidCallback? onCreate;

  const AdminSectionScaffold({
    super.key,
    required this.title,
    required this.isLoading,
    required this.error,
    required this.itemCount,
    required this.itemBuilder,
    required this.onRefresh,
    this.header,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptyMessage,
    this.createLabel,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, title),
      floatingActionButton: onCreate == null
          ? null
          : FloatingActionButton.extended(
              onPressed: onCreate,
              backgroundColor: kCareDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(createLabel ?? 'Add'),
            ),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: onRefresh,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (isLoading && itemCount == 0 && header == null) return const CareStateView.loading();
    if (error != null && itemCount == 0) return CareStateView.error(error!);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        if (header != null) header!,
        if (itemCount == 0)
          CareStateView.inline(icon: emptyIcon, title: emptyTitle, message: emptyMessage)
        else
          for (var i = 0; i < itemCount; i++) Builder(builder: (context) => itemBuilder(context, i)),
      ],
    );
  }
}

// ----------------------------------------------------------------- forms

/// One field in an [adminFormSheet].
class AdminField {
  final String key;
  final String label;
  final String? initial;
  final bool required;
  final TextInputType keyboard;
  final int maxLines;

  /// When set, the field is a dropdown over these values instead of a box.
  final List<String>? options;

  /// Shown inside the field, the way every other form in the app does it.
  final IconData icon;

  const AdminField(
    this.key,
    this.label, {
    this.initial,
    this.required = false,
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
    this.options,
    this.icon = Icons.edit_outlined,
  });
}

/// A form in a bottom sheet. Returns the filled values, or null if the
/// user backed out. Empty optional fields are dropped rather than sent as
/// "", which Laravel would otherwise store over a real value.
Future<Map<String, dynamic>?> adminFormSheet(
  BuildContext context, {
  required String title,
  required List<AdminField> fields,
  String submitLabel = 'Save',
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AdminFormSheet(title: title, fields: fields, submitLabel: submitLabel),
  );
}

class _AdminFormSheet extends StatefulWidget {
  final String title;
  final List<AdminField> fields;
  final String submitLabel;
  const _AdminFormSheet({required this.title, required this.fields, required this.submitLabel});

  @override
  State<_AdminFormSheet> createState() => _AdminFormSheetState();
}

class _AdminFormSheetState extends State<_AdminFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.fields.where((f) => f.options == null)) f.key: TextEditingController(text: f.initial),
  };
  late final Map<String, String?> _choices = {
    for (final f in widget.fields.where((f) => f.options != null)) f.key: f.initial ?? f.options!.firstOrNull,
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final values = <String, dynamic>{};
    for (final field in widget.fields) {
      final value = field.options != null ? _choices[field.key] : _controllers[field.key]?.text.trim();
      if (value == null || value.isEmpty) continue;
      values[field.key] = value;
    }
    Navigator.of(context).pop(values);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(CareRadius.sheet)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38, height: 4,
                      decoration: BoxDecoration(color: kCareBorder, borderRadius: BorderRadius.circular(CareRadius.pill)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(widget.title, style: CareText.titleXl),
                  const SizedBox(height: 16),
                  for (final field in widget.fields) ...[
                    _field(field),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 4),
                  CarePrimaryButton(label: widget.submitLabel, onPressed: _submit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(AdminField field) {
    if (field.options != null) {
      return DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _choices[field.key],
        decoration: careFieldDecoration(field.label, hint: '', icon: field.icon),
        items: field.options!
            .map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: (v) => setState(() => _choices[field.key] = v),
        validator: (v) => field.required && (v == null || v.isEmpty) ? '${field.label} is required' : null,
      );
    }

    return TextFormField(
      controller: _controllers[field.key],
      keyboardType: field.keyboard,
      maxLines: field.maxLines,
      inputFormatters: field.keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      decoration: careFieldDecoration(field.label, hint: '', icon: field.icon),
      validator: (v) =>
          field.required && (v == null || v.trim().isEmpty) ? '${field.label} is required' : null,
    );
  }
}

/// Yes/no before something destructive. Returns true only on a real yes.
Future<bool> adminConfirm(BuildContext context, {required String title, required String message, String confirmLabel = 'Delete'}) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: CareText.titleLg),
      content: Text(message, style: CareText.bodyMdMuted),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: CareText.mutedSmMedium)),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel, style: const TextStyle(color: kDangerText, fontWeight: CareText.bold, fontSize: CareText.md)),
        ),
      ],
    ),
  );
  return answer ?? false;
}

/// The result of a write, in a floating bar.
///
/// Every screen in the app spells this out itself; the admin sections say
/// it once instead. Worth lifting into care_ui.dart for the rest of the
/// app at some point, which is a bigger change than this one.
void adminSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError ? kDangerText : kCareDark,
      content: Text(message, style: const TextStyle(color: Colors.white)),
    ),
  );
}
