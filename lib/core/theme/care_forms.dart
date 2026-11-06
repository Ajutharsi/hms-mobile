import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';

/// A form in a sheet, a confirm dialog and a result bar.
///
/// These started in the admin kit, where twelve sections share one way of
/// adding and editing a row. The clinical screens need exactly the same
/// three things, and nothing in them was ever admin-specific, so they
/// live with the rest of the design kit instead.
/// One field in an [careFormSheet].
class CareFormField {
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

  const CareFormField(
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
Future<Map<String, dynamic>?> careFormSheet(
  BuildContext context, {
  required String title,
  required List<CareFormField> fields,
  String submitLabel = 'Save',
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CareFormSheet(title: title, fields: fields, submitLabel: submitLabel),
  );
}

class _CareFormSheet extends StatefulWidget {
  final String title;
  final List<CareFormField> fields;
  final String submitLabel;
  const _CareFormSheet({required this.title, required this.fields, required this.submitLabel});

  @override
  State<_CareFormSheet> createState() => _CareFormSheetState();
}

class _CareFormSheetState extends State<_CareFormSheet> {
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

  Widget _field(CareFormField field) {
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
Future<bool> careConfirm(BuildContext context, {required String title, required String message, String confirmLabel = 'Delete'}) async {
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
void careSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError ? kDangerText : kCareDark,
      content: Text(message, style: const TextStyle(color: Colors.white)),
    ),
  );
}
