import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/medication_order.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';
import 'package:hms_mobile/features/nurse/viewmodels/emar_view_model.dart';
import 'package:hms_mobile/features/nurse/widgets/patient_picker.dart';

class EmarScreen extends StatelessWidget {
  const EmarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => EmarViewModel(),
      child: const _EmarView(),
    );
  }
}

class _EmarView extends StatelessWidget {
  const _EmarView();

  Future<void> _newOrder(BuildContext context, EmarViewModel viewModel) async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const _NewOrderScreen()));
    if (created == true) viewModel.load();
  }

  Future<void> _administer(BuildContext context, EmarViewModel viewModel, MedicationOrder order) async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => _AdministerDialog(order: order),
    );
    if (result == null || !context.mounted) return;

    final error = await viewModel.administer(order.id, status: result['status']!, notes: result['notes']);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Medication status updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<EmarViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'eMAR'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newOrder(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New order', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    ));
  }

  Widget _buildBody(BuildContext context, EmarViewModel viewModel) {
    if (viewModel.isLoading && viewModel.orders.isEmpty) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }
    if (viewModel.loadError != null && viewModel.orders.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.orders.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.medication_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No medication orders yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: viewModel.orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = viewModel.orders[index];
        return _OrderCard(order: order, onAdminister: () => _administer(context, viewModel, order));
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final MedicationOrder order;
  final VoidCallback onAdminister;
  const _OrderCard({required this.order, required this.onAdminister});

  static const _statusColors = {
    'scheduled': (kInfoFg, kInfoBg),
    'administered': (kSuccessFg, kSuccessBg),
    'missed': (kDangerFg, kDangerBg),
    'refused': (kDangerFg, kDangerBg),
    'held': (kWarningFg, kWarningBg),
  };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final (fg, bg) = _statusColors[order.status] ?? (kMuted, kCareBg);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kCareBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.patientName ?? 'Patient', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMuted)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Text(order.status.toUpperCase(), style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('${order.drugName} — ${order.dosage}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: kInk)),
              ),
              if (order.isPrn) const _MiniBadge(label: 'PRN', color: kWarningFg, bg: kWarningBg),
              if (order.isControlled) ...[
                const SizedBox(width: 6),
                const _MiniBadge(label: 'Controlled', color: kDangerFg, bg: kDangerBg),
              ],
            ],
          ),
          if ((order.route ?? '').isNotEmpty || (order.frequency ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text([order.route, order.frequency].where((e) => (e ?? '').isNotEmpty).join(' · '), style: const TextStyle(fontSize: 12.5, color: kMuted)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: kMuted),
              const SizedBox(width: 6),
              Text(order.scheduledTime ?? '—', style: const TextStyle(fontSize: 13, color: kMuted)),
              if (order.nurseName != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.person_outline, size: 14, color: kMuted),
                const SizedBox(width: 6),
                Text(order.nurseName!, style: const TextStyle(fontSize: 13, color: kMuted)),
              ],
            ],
          ),
          if ((order.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(order.notes!, style: const TextStyle(fontSize: 12.5, color: kMuted, fontStyle: FontStyle.italic)),
          ],
          if (order.isScheduled) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onAdminister,
                icon: const Icon(Icons.medication_liquid_outlined, size: 16),
                label: const Text('Administer'),
                style: FilledButton.styleFrom(backgroundColor: kCareDark, minimumSize: const Size(0, 34), textStyle: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _MiniBadge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _AdministerDialog extends StatefulWidget {
  final MedicationOrder order;
  const _AdministerDialog({required this.order});

  @override
  State<_AdministerDialog> createState() => _AdministerDialogState();
}

class _AdministerDialogState extends State<_AdministerDialog> {
  String _status = 'administered';
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return AlertDialog(
      title: Text('${widget.order.drugName} — ${widget.order.dosage}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in ['administered', 'missed', 'refused', 'held'])
                ChoiceChip(
                  label: Text(s),
                  selected: _status == s,
                  selectedColor: kCareSoft,
                  onSelected: (_) => setState(() => _status = s),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Notes (optional)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kCareDark),
          onPressed: () => Navigator.of(context).pop({'status': _status, 'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim()}),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _NewOrderScreen extends StatefulWidget {
  const _NewOrderScreen();

  @override
  State<_NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<_NewOrderScreen> {
  final _drugController = TextEditingController();
  final _dosageController = TextEditingController();
  final _routeController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _notesController = TextEditingController();

  NursePatient? _patient;
  TimeOfDay? _scheduledTime;
  bool _isPrn = false;
  bool _isControlled = false;
  bool _saving = false;
  String? _error;
  String? _patientError;

  @override
  void dispose() {
    _drugController.dispose();
    _dosageController.dispose();
    _routeController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<void> _submit() async {
    setState(() => _patientError = _patient == null ? 'Choose a patient' : null);
    if (_patient == null || _drugController.text.trim().isEmpty || _dosageController.text.trim().isEmpty) {
      setState(() => _error = 'Fill in the patient, drug name, and dosage.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final viewModel = context.read<EmarViewModel>();
    final scheduled = _scheduledTime == null
        ? null
        : '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}';

    final error = await viewModel.createOrder(
      patientId: _patient!.id,
      drugName: _drugController.text.trim(),
      dosage: _dosageController.text.trim(),
      route: _routeController.text.trim().isEmpty ? null : _routeController.text.trim(),
      frequency: _frequencyController.text.trim().isEmpty ? null : _frequencyController.text.trim(),
      scheduledTime: scheduled,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isPrn: _isPrn,
      isControlled: _isControlled,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'New medication order'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[authErrorBanner(_error!), const SizedBox(height: 16)],
              PatientPickerField(value: _patient, errorText: _patientError, onChanged: (p) => setState(() => _patient = p)),
              const SizedBox(height: 16),
              TextField(controller: _drugController, decoration: careFieldDecoration('Drug name', hint: 'e.g. Paracetamol', icon: Icons.medication_outlined)),
              const SizedBox(height: 14),
              TextField(controller: _dosageController, decoration: careFieldDecoration('Dosage', hint: 'e.g. 500mg', icon: Icons.scale_outlined)),
              const SizedBox(height: 14),
              TextField(controller: _routeController, decoration: careFieldDecoration('Route (optional)', hint: 'e.g. Oral, IV', icon: Icons.route_outlined)),
              const SizedBox(height: 14),
              TextField(controller: _frequencyController, decoration: careFieldDecoration('Frequency (optional)', hint: 'e.g. Twice daily', icon: Icons.repeat_rounded)),
              const SizedBox(height: 14),
              const Text('Scheduled time (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.access_time_rounded, size: 18, color: kMuted),
                    const SizedBox(width: 10),
                    Text(_scheduledTime == null ? 'Choose a time' : _scheduledTime!.format(context), style: TextStyle(color: _scheduledTime == null ? const Color(0xFFAEB8B6) : kInk, fontSize: 15)),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              TextField(controller: _notesController, maxLines: 3, decoration: careFieldDecoration('Notes (optional)', hint: '', icon: Icons.notes_outlined)),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _isPrn,
                onChanged: (v) => setState(() => _isPrn = v ?? false),
                title: const Text('PRN (as needed)', style: TextStyle(fontSize: 14)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _isControlled,
                onChanged: (v) => setState(() => _isControlled = v ?? false),
                title: const Text('Controlled substance', style: TextStyle(fontSize: 14)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: kCareDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : const Text('Add order', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
