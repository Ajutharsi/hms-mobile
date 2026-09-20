import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/blood_bank.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';
import 'package:hms_mobile/features/nurse/viewmodels/blood_bank_view_model.dart';
import 'package:hms_mobile/features/nurse/widgets/patient_picker.dart';

const _kBloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const _kComponents = ['whole_blood', 'packed_rbc', 'ffp', 'platelets', 'cryoprecipitate'];
const _kStatuses = ['available', 'reserved', 'transfused', 'expired', 'discarded'];

String _titleCase(String s) => s.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

class BloodBankScreen extends StatelessWidget {
  const BloodBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => BloodBankViewModel(),
      child: const _BloodBankView(),
    );
  }
}

class _BloodBankView extends StatelessWidget {
  const _BloodBankView();

  Future<void> _addUnit(BuildContext context, BloodBankViewModel viewModel) async {
    final added = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const _AddUnitScreen()));
    if (added == true) viewModel.load();
  }

  Future<void> _transfuse(BuildContext context, BloodBankViewModel viewModel, BloodUnit unit) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _TransfuseDialog(unit: unit));
    if (result == null || !context.mounted) return;

    final error = await viewModel.transfuse(unit.id, patientId: result['patient_id'] as int, indication: result['indication'] as String?);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Transfusion started.')));
  }

  Future<void> _updateStatus(BuildContext context, BloodBankViewModel viewModel, BloodUnit unit) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _UpdateStatusDialog(unit: unit));
    if (result == null || !context.mounted) return;

    final error = await viewModel.updateStatus(unit.id, status: result['status'] as String, reservedFor: result['reserved_for'] as int?);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Status updated.')));
  }

  Future<void> _delete(BuildContext context, BloodBankViewModel viewModel, BloodUnit unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this unit?'),
        content: Text('Delete blood unit ${unit.unitNo ?? '#${unit.id}'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Color(0xFFB3261E)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await viewModel.destroy(unit.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Unit deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<BloodBankViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Blood Bank'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addUnit(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add unit', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    ));
  }

  Widget _buildBody(BuildContext context, BloodBankViewModel viewModel) {
    if (viewModel.isLoading && viewModel.units.isEmpty) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }
    if (viewModel.loadError != null && viewModel.units.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            Expanded(child: _StatTile(label: 'Total units', value: '${viewModel.totalUnits}', color: kCareDark, bg: kCareSoft)),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'Near expiry',
                value: '${viewModel.nearExpiryCount}',
                color: viewModel.nearExpiryCount > 0 ? kDangerFg : kSuccessFg,
                bg: viewModel.nearExpiryCount > 0 ? kDangerBg : kSuccessBg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in _kBloodGroups)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(10)),
                child: Text('$g: ${viewModel.byGroup[g] ?? 0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kInk)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (viewModel.units.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: Text('No blood units in inventory', style: TextStyle(color: kMuted))),
          )
        else
          for (final unit in viewModel.units) ...[
            _UnitCard(
              unit: unit,
              onTransfuse: () => _transfuse(context, viewModel, unit),
              onUpdateStatus: () => _updateStatus(context, viewModel, unit),
              onDelete: () => _delete(context, viewModel, unit),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _StatTile({required this.label, required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final BloodUnit unit;
  final VoidCallback onTransfuse;
  final VoidCallback onUpdateStatus;
  final VoidCallback onDelete;
  const _UnitCard({required this.unit, required this.onTransfuse, required this.onUpdateStatus, required this.onDelete});

  static Map<String, (Color, Color)> get _statusColors => {
    'available': (kSuccessFg, kSuccessBg),
    'reserved': (kWarningFg, kWarningBg),
    'transfused': (kInfoFg, kInfoBg),
    'expired': (kDangerFg, kDangerBg),
    'discarded': (kMuted, kCareBg),
  };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final (fg, bg) = _statusColors[unit.status] ?? (kMuted, kCareBg);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kCareBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kCareSoft, borderRadius: BorderRadius.circular(8)),
                child: Text(unit.bloodGroup, style: TextStyle(color: kCareDark, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(_titleCase(unit.component), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Text(unit.status.toUpperCase(), style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if ((unit.unitNo ?? '').isNotEmpty) Text(unit.unitNo!, style: const TextStyle(fontSize: 12, color: kMuted)),
          if ((unit.donorName ?? '').isNotEmpty) Text('Donor: ${unit.donorName}', style: const TextStyle(fontSize: 12, color: kMuted)),
          Text(
            'Collected ${unit.collectionDate ?? '—'} · Expires ${unit.expiryDate ?? '—'}',
            style: TextStyle(fontSize: 12, color: unit.isNearExpiry ? const Color(0xFFB3261E) : kMuted, fontWeight: unit.isNearExpiry ? FontWeight.w700 : FontWeight.w400),
          ),
          if (unit.reservedForName != null) Text('Reserved for ${unit.reservedForName}', style: const TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onDelete, child: const Text('Delete', style: TextStyle(color: Color(0xFFB3261E)))),
              TextButton(onPressed: onUpdateStatus, child: Text('Update status', style: TextStyle(color: kCareDark))),
              if (unit.isAvailable)
                FilledButton.icon(
                  onPressed: onTransfuse,
                  icon: const Icon(Icons.water_drop_outlined, size: 15),
                  label: const Text('Transfuse'),
                  style: FilledButton.styleFrom(backgroundColor: kCareDark, minimumSize: const Size(0, 34), textStyle: const TextStyle(fontSize: 12.5)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransfuseDialog extends StatefulWidget {
  final BloodUnit unit;
  const _TransfuseDialog({required this.unit});

  @override
  State<_TransfuseDialog> createState() => _TransfuseDialogState();
}

class _TransfuseDialogState extends State<_TransfuseDialog> {
  NursePatient? _patient;
  final _indication = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _indication.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return AlertDialog(
      title: Text('Transfuse ${widget.unit.bloodGroup} unit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PatientPickerField(value: _patient, errorText: _error, onChanged: (p) => setState(() { _patient = p; _error = null; })),
            const SizedBox(height: 12),
            TextField(controller: _indication, decoration: careFieldDecoration('Indication', hint: 'Optional', icon: Icons.notes_outlined)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_patient == null) {
              setState(() => _error = 'Pick a patient');
              return;
            }
            Navigator.of(context).pop({'patient_id': _patient!.id, 'indication': _indication.text.trim().isEmpty ? null : _indication.text.trim()});
          },
          style: FilledButton.styleFrom(backgroundColor: kCareDark),
          child: const Text('Start transfusion'),
        ),
      ],
    );
  }
}

class _UpdateStatusDialog extends StatefulWidget {
  final BloodUnit unit;
  const _UpdateStatusDialog({required this.unit});

  @override
  State<_UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<_UpdateStatusDialog> {
  late String _status = widget.unit.status;
  NursePatient? _reservedFor;

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return AlertDialog(
      title: const Text('Update status'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: careFieldDecoration('Status', hint: '', icon: Icons.flag_outlined),
              items: _kStatuses.map((s) => DropdownMenuItem(value: s, child: Text(_titleCase(s)))).toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            if (_status == 'reserved') ...[
              const SizedBox(height: 12),
              PatientPickerField(label: 'Reserve for', value: _reservedFor, onChanged: (p) => setState(() => _reservedFor = p)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({'status': _status, 'reserved_for': _reservedFor?.id}),
          style: FilledButton.styleFrom(backgroundColor: kCareDark),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class _AddUnitScreen extends StatefulWidget {
  const _AddUnitScreen();

  @override
  State<_AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends State<_AddUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _donorController = TextEditingController();
  final _notesController = TextEditingController();

  String _bloodGroup = _kBloodGroups.first;
  String _component = _kComponents.first;
  DateTime? _collectionDate;
  DateTime? _expiryDate;
  bool _submitting = false;

  @override
  void dispose() {
    _donorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(bool isCollection) async {
    final initial = (isCollection ? _collectionDate : _expiryDate) ?? DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365 * 3)));
    if (picked == null) return;
    setState(() {
      if (isCollection) {
        _collectionDate = picked;
      } else {
        _expiryDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _collectionDate == null || _expiryDate == null) {
      if (_collectionDate == null || _expiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick both collection and expiry dates.')));
      }
      return;
    }
    if (!_expiryDate!.isAfter(_collectionDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expiry date must be after collection date.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = await AuthStorage().readToken();
      await guardNetworkErrors(() => NurseApiService().bloodBankStore(
            token!,
            bloodGroup: _bloodGroup,
            component: _component,
            donorName: _donorController.text.trim().isEmpty ? null : _donorController.text.trim(),
            collectionDate: _fmtDate(_collectionDate!),
            expiryDate: _fmtDate(_expiryDate!),
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          ));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Add Blood Unit'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _bloodGroup,
              decoration: careFieldDecoration('Blood group', hint: '', icon: Icons.bloodtype_outlined),
              items: _kBloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _bloodGroup = v ?? _bloodGroup),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _component,
              decoration: careFieldDecoration('Component', hint: '', icon: Icons.science_outlined),
              items: _kComponents.map((c) => DropdownMenuItem(value: c, child: Text(_titleCase(c)))).toList(),
              onChanged: (v) => setState(() => _component = v ?? _component),
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _donorController, decoration: careFieldDecoration('Donor name', hint: 'Optional', icon: Icons.person_outline)),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _pickDate(true),
              child: InputDecorator(
                decoration: careFieldDecoration('Collection date', hint: 'Tap to pick', icon: Icons.event_outlined),
                child: Text(_collectionDate != null ? _fmtDate(_collectionDate!) : 'Tap to pick', style: TextStyle(color: _collectionDate != null ? kInk : kMuted)),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _pickDate(false),
              child: InputDecorator(
                decoration: careFieldDecoration('Expiry date', hint: 'Tap to pick', icon: Icons.event_busy_outlined),
                child: Text(_expiryDate != null ? _fmtDate(_expiryDate!) : 'Tap to pick', style: TextStyle(color: _expiryDate != null ? kInk : kMuted)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _notesController, maxLines: 3, decoration: careFieldDecoration('Notes', hint: 'Optional', icon: Icons.notes_outlined)),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: kCareDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add unit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
