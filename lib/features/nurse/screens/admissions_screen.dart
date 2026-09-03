import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/api_service.dart' show ApiException, guardNetworkErrors;
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/features/nurse/models/admission.dart';
import 'package:hms_mobile/features/nurse/models/ward.dart';
import 'package:hms_mobile/features/nurse/screens/admit_patient_screen.dart';
import 'package:hms_mobile/features/nurse/viewmodels/admissions_view_model.dart';

class AdmissionsScreen extends StatelessWidget {
  const AdmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdmissionsViewModel(),
      child: const _AdmissionsView(),
    );
  }
}

class _AdmissionsView extends StatelessWidget {
  const _AdmissionsView();

  Future<void> _admitPatient(BuildContext context, AdmissionsViewModel viewModel) async {
    final admitted = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AdmitPatientScreen()));
    if (admitted == true) viewModel.load();
  }

  Future<void> _discharge(BuildContext context, AdmissionsViewModel viewModel, Admission admission) async {
    final result = await showDialog<Map<String, String>>(context: context, builder: (_) => _DischargeDialog(admission: admission));
    if (result == null || !context.mounted) return;

    final error = await viewModel.discharge(
      admission.id,
      dischargeDate: result['discharge_date']!,
      notes: result['discharge_notes']?.isEmpty == true ? null : result['discharge_notes'],
      totalCharges: double.tryParse(result['total_charges'] ?? '') ?? 0,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Patient discharged.')));
  }

  Future<void> _transfer(BuildContext context, AdmissionsViewModel viewModel, Admission admission) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _TransferDialog(admission: admission));
    if (result == null || !context.mounted) return;

    final error = await viewModel.transfer(
      admission.id,
      newWardId: result['ward_id'] as int,
      newBedId: result['bed_id'] as int,
      reason: (result['reason'] as String?)?.isEmpty == true ? null : result['reason'] as String?,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Patient transferred.')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdmissionsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Admissions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _admitPatient(context, viewModel),
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Admit patient', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                _FilterChip(label: 'All', selected: viewModel.statusFilter == null, onTap: () => viewModel.setFilter(null)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Admitted', selected: viewModel.statusFilter == 'admitted', onTap: () => viewModel.setFilter('admitted')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Discharged', selected: viewModel.statusFilter == 'discharged', onTap: () => viewModel.setFilter('discharged')),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kTeal,
              onRefresh: viewModel.load,
              child: _buildBody(context, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdmissionsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.admissions.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.admissions.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.admissions.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.bed_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No admissions found', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: viewModel.admissions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final admission = viewModel.admissions[index];
        return _AdmissionCard(
          admission: admission,
          onDischarge: () => _discharge(context, viewModel, admission),
          onTransfer: () => _transfer(context, viewModel, admission),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: selected ? kTealDark : kFieldFill, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : kMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _AdmissionCard extends StatelessWidget {
  final Admission admission;
  final VoidCallback onDischarge;
  final VoidCallback onTransfer;
  const _AdmissionCard({required this.admission, required this.onDischarge, required this.onTransfer});

  @override
  Widget build(BuildContext context) {
    final admitted = admission.isAdmitted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kMint,
                backgroundImage: admission.patientPhotoUrl != null ? NetworkImage(admission.patientPhotoUrl!) : null,
                child: admission.patientPhotoUrl == null
                    ? Text((admission.patientName ?? '?').isNotEmpty ? admission.patientName![0].toUpperCase() : '?', style: const TextStyle(color: kTealDark, fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admission.patientName ?? 'Patient', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk)),
                    Text(admission.patientMrn ?? '', style: const TextStyle(fontSize: 12, color: kMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: admitted ? kSuccessBg : kFieldFill, borderRadius: BorderRadius.circular(8)),
                child: Text(admission.status, style: TextStyle(color: admitted ? kSuccessFg : kMuted, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _InfoBit(icon: Icons.holiday_village_outlined, text: admission.wardName ?? '—'),
              _InfoBit(icon: Icons.bed_outlined, text: admission.bedNo ?? '—'),
              _InfoBit(icon: Icons.medical_information_outlined, text: admission.doctorName ?? '—'),
              _InfoBit(icon: Icons.calendar_today_outlined, text: admission.admissionDate ?? '—'),
            ],
          ),
          if (admitted) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onTransfer, child: const Text('Transfer', style: TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.w600))),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: onDischarge,
                  style: FilledButton.styleFrom(backgroundColor: kTealDark, minimumSize: const Size(0, 34), textStyle: const TextStyle(fontSize: 13)),
                  child: const Text('Discharge'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBit extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: kMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: kMuted)),
      ],
    );
  }
}

class _DischargeDialog extends StatefulWidget {
  final Admission admission;
  const _DischargeDialog({required this.admission});

  @override
  State<_DischargeDialog> createState() => _DischargeDialogState();
}

class _DischargeDialogState extends State<_DischargeDialog> {
  DateTime _date = DateTime.now();
  final _notesController = TextEditingController();
  final _chargesController = TextEditingController(text: '0');

  @override
  void dispose() {
    _notesController.dispose();
    _chargesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Discharge patient'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.admission.patientName ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 1)));
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Discharge date', border: OutlineInputBorder()),
                child: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _chargesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total charges', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Discharge notes (optional)', border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kTealDark),
          onPressed: () => Navigator.of(context).pop({
            'discharge_date': '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
            'discharge_notes': _notesController.text.trim(),
            'total_charges': _chargesController.text.trim(),
          }),
          child: const Text('Discharge'),
        ),
      ],
    );
  }
}

class _TransferDialog extends StatefulWidget {
  final Admission admission;
  const _TransferDialog({required this.admission});

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final _authStorage = AuthStorage();
  final _api = NurseApiService();

  bool _isLoadingWards = true;
  bool _isLoadingBeds = false;
  List<Ward> _wards = [];
  List<Bed> _beds = [];
  Ward? _selectedWard;
  Bed? _selectedBed;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWards();
  }

  Future<void> _loadWards() async {
    try {
      final token = await _authStorage.readToken();
      _wards = await guardNetworkErrors(() => _api.wards(token!));
    } on ApiException {
      _wards = [];
    } finally {
      if (mounted) setState(() => _isLoadingWards = false);
    }
  }

  Future<void> _selectWard(Ward? ward) async {
    setState(() {
      _selectedWard = ward;
      _selectedBed = null;
      _beds = [];
      _isLoadingBeds = ward != null;
    });
    if (ward == null) return;
    try {
      final token = await _authStorage.readToken();
      _beds = await guardNetworkErrors(() => _api.availableBeds(token!, ward.id));
    } on ApiException {
      _beds = [];
    } finally {
      if (mounted) setState(() => _isLoadingBeds = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transfer patient'),
      content: _isLoadingWards
          ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: kTeal)))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.admission.patientName ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Ward>(
                    initialValue: _selectedWard,
                    decoration: const InputDecoration(labelText: 'New ward', border: OutlineInputBorder()),
                    items: _wards.map((w) => DropdownMenuItem(value: w, child: Text(w.name))).toList(),
                    onChanged: _selectWard,
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingBeds)
                    const LinearProgressIndicator(color: kTeal)
                  else
                    DropdownButtonFormField<Bed>(
                      initialValue: _selectedBed,
                      decoration: const InputDecoration(labelText: 'New bed', border: OutlineInputBorder()),
                      items: _beds.map((b) => DropdownMenuItem(value: b, child: Text(b.bedNo))).toList(),
                      onChanged: _selectedWard == null ? null : (b) => setState(() => _selectedBed = b),
                    ),
                  const SizedBox(height: 12),
                  TextField(controller: _reasonController, maxLines: 2, decoration: const InputDecoration(labelText: 'Reason (optional)', border: OutlineInputBorder())),
                ],
              ),
            ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kTealDark),
          onPressed: _selectedWard == null || _selectedBed == null
              ? null
              : () => Navigator.of(context).pop({'ward_id': _selectedWard!.id, 'bed_id': _selectedBed!.id, 'reason': _reasonController.text.trim()}),
          child: const Text('Transfer'),
        ),
      ],
    );
  }
}
