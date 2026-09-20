import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/core/services/api_service.dart' show ApiException, guardNetworkErrors;
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/consent_form.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';
import 'package:hms_mobile/features/nurse/viewmodels/consent_forms_view_model.dart';
import 'package:hms_mobile/features/nurse/widgets/patient_picker.dart';
import 'package:hms_mobile/features/nurse/widgets/signature_pad.dart';

const _kConsentTypes = ['general', 'surgery', 'anesthesia', 'blood_transfusion', 'procedure', 'other'];

String _titleCase(String s) => s.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

class ConsentFormsScreen extends StatelessWidget {
  const ConsentFormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => ConsentFormsViewModel(),
      child: const _ConsentFormsView(),
    );
  }
}

class _ConsentFormsView extends StatelessWidget {
  const _ConsentFormsView();

  Future<void> _newForm(BuildContext context, ConsentFormsViewModel viewModel) async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const _NewConsentFormScreen()));
    if (created == true) viewModel.load();
  }

  Future<void> _sign(BuildContext context, ConsentFormsViewModel viewModel, ConsentForm form) async {
    final result = await showDialog<String>(context: context, builder: (_) => _SignDialog(form: form));
    if (result == null || !context.mounted) return;

    final error = await viewModel.sign(form.id, patientSignature: result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Consent form signed.')));
  }

  Future<void> _decline(BuildContext context, ConsentFormsViewModel viewModel, ConsentForm form) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline this consent?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Decline', style: TextStyle(color: Color(0xFFB3261E)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await viewModel.updateStatus(form.id, 'declined');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Marked declined.')));
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<ConsentFormsViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Consent Forms'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newForm(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New form', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    ));
  }

  Widget _buildBody(BuildContext context, ConsentFormsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.forms.isEmpty) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }
    if (viewModel.loadError != null && viewModel.forms.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.forms.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.assignment_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No consent forms yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: viewModel.forms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final form = viewModel.forms[index];
        return _ConsentCard(
          form: form,
          onSign: form.status == 'pending' ? () => _sign(context, viewModel, form) : null,
          onDecline: form.status == 'pending' ? () => _decline(context, viewModel, form) : null,
        );
      },
    );
  }
}

class _ConsentCard extends StatelessWidget {
  final ConsentForm form;
  final VoidCallback? onSign;
  final VoidCallback? onDecline;
  const _ConsentCard({required this.form, this.onSign, this.onDecline});

  static const _statusColors = {
    'pending': (kWarningFg, kWarningBg),
    'signed': (kSuccessFg, kSuccessBg),
    'declined': (kDangerFg, kDangerBg),
  };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final (fg, bg) = _statusColors[form.status] ?? (kMuted, kCareBg);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kCareBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(form.patientName ?? 'Patient', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                    if (form.patientMrn != null) Text(form.patientMrn!, style: const TextStyle(fontSize: 11.5, color: kMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Text(form.status.toUpperCase(), style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [_titleCase(form.consentType), if ((form.procedureName ?? '').isNotEmpty) form.procedureName!].join(' · '),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: kInk),
          ),
          const SizedBox(height: 4),
          Text(form.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: kMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (form.consentNo != null) ...[
                const Icon(Icons.tag, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Text(form.consentNo!, style: const TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(width: 14),
              ],
              const Icon(Icons.event_outlined, size: 13, color: kMuted),
              const SizedBox(width: 4),
              Text(form.consentDate ?? '', style: const TextStyle(fontSize: 12, color: kMuted)),
            ],
          ),
          if (onSign != null || onDecline != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onDecline != null)
                  TextButton(onPressed: onDecline, child: const Text('Decline', style: TextStyle(color: Color(0xFFB3261E)))),
                if (onSign != null)
                  FilledButton.icon(
                    onPressed: onSign,
                    icon: const Icon(Icons.draw_outlined, size: 16),
                    label: const Text('Sign'),
                    style: FilledButton.styleFrom(backgroundColor: kCareDark, minimumSize: const Size(0, 34), textStyle: const TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SignDialog extends StatefulWidget {
  final ConsentForm form;
  const _SignDialog({required this.form});

  @override
  State<_SignDialog> createState() => _SignDialogState();
}

class _SignDialogState extends State<_SignDialog> {
  final _controller = SignaturePadController();
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final bytes = await _controller.toPngBytes();
    if (!mounted) return;
    setState(() => _submitting = false);

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please draw a signature first.')));
      return;
    }
    final dataUri = 'data:image/png;base64,${base64Encode(bytes)}';
    Navigator.of(context).pop(dataUri);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return AlertDialog(
      title: Text('Sign consent — ${widget.form.patientName ?? ''}'),
      content: SizedBox(
        width: 320,
        height: 220,
        child: Column(
          children: [
            const Text('Have the patient sign below', style: TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: kCareBorder), borderRadius: BorderRadius.circular(8)),
                child: SignaturePad(controller: _controller),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _controller.clear, child: const Text('Clear')),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: kCareDark),
          child: _submitting
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save signature'),
        ),
      ],
    );
  }
}

class _NewConsentFormScreen extends StatefulWidget {
  const _NewConsentFormScreen();

  @override
  State<_NewConsentFormScreen> createState() => _NewConsentFormScreenState();
}

class _NewConsentFormScreenState extends State<_NewConsentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = NurseApiService();
  final _authStorage = AuthStorage();

  NursePatient? _patient;
  String _consentType = _kConsentTypes.first;
  final _procedureController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _witnessController = TextEditingController();
  final _doctorController = TextEditingController();
  DateTime _consentDate = DateTime.now();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _procedureController.dispose();
    _descriptionController.dispose();
    _witnessController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _consentDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _consentDate = picked);
  }

  Future<void> _submit() async {
    if (_patient == null) {
      setState(() => _error = 'Please select a patient.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => _api.consentFormStore(
            token!,
            patientId: _patient!.id,
            consentType: _consentType,
            procedureName: _procedureController.text.trim().isEmpty ? null : _procedureController.text.trim(),
            description: _descriptionController.text.trim(),
            witnessName: _witnessController.text.trim().isEmpty ? null : _witnessController.text.trim(),
            doctorName: _doctorController.text.trim().isEmpty ? null : _doctorController.text.trim(),
            consentDate: _consentDate.toIso8601String().split('T').first,
          ));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'New Consent Form'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PatientPickerField(value: _patient, onChanged: (p) => setState(() => _patient = p)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _consentType,
                decoration: careFieldDecoration('Consent type', hint: '', icon: Icons.assignment_outlined),
                items: _kConsentTypes.map((t) => DropdownMenuItem(value: t, child: Text(_titleCase(t)))).toList(),
                onChanged: (v) => setState(() => _consentType = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _procedureController,
                decoration: careFieldDecoration('Procedure name', hint: 'Optional', icon: Icons.medical_information_outlined),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: careFieldDecoration('Description', hint: 'Consent details', icon: Icons.description_outlined),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _witnessController,
                decoration: careFieldDecoration('Witness name', hint: 'Optional', icon: Icons.person_outline),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _doctorController,
                decoration: careFieldDecoration('Doctor name', hint: 'Optional', icon: Icons.badge_outlined),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: careFieldDecoration('Consent date', hint: '', icon: Icons.event_outlined),
                  child: Text('${_consentDate.year}-${_consentDate.month.toString().padLeft(2, '0')}-${_consentDate.day.toString().padLeft(2, '0')}'),
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[authErrorBanner(_error!), const SizedBox(height: 14)],
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: kCareDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create form', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
