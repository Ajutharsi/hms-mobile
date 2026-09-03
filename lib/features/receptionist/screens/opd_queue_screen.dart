import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/opd_token.dart';
import 'package:hms_mobile/features/receptionist/models/reception_appointment.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';
import 'package:hms_mobile/features/receptionist/screens/insurance_claims_screen.dart' show ReceptionPatientPickerField, titleCase;
import 'package:hms_mobile/features/receptionist/viewmodels/opd_queue_view_model.dart';

(Color, Color) _tokenStatusColors(String s) => switch (s) {
      'in_consultation' => (kInfoFg, kInfoBg),
      'completed' => (kSuccessFg, kSuccessBg),
      'skipped' => (kMuted, kFieldFill),
      'cancelled' => (kDangerFg, kDangerBg),
      _ => (kWarningFg, kWarningBg),
    };

class OpdQueueScreen extends StatelessWidget {
  const OpdQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OpdQueueViewModel(),
      child: const _OpdQueueView(),
    );
  }
}

class _OpdQueueView extends StatelessWidget {
  const _OpdQueueView();

  Future<void> _issueToken(BuildContext context, OpdQueueViewModel viewModel) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => const _IssueTokenDialog());
    if (result == null || !context.mounted) return;

    final error = await viewModel.issueToken(patientId: result['patient_id'] as int, doctorId: result['doctor_id'] as int, notes: result['notes'] as String?);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Token issued successfully!')));
  }

  Future<void> _setStatus(BuildContext context, OpdQueueViewModel viewModel, OpdToken token, String status) async {
    final error = await viewModel.updateStatus(token.id, status);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Queue status updated.')));
  }

  Future<void> _callNext(BuildContext context, OpdQueueViewModel viewModel, int doctorId) async {
    final error = await viewModel.callNext(doctorId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Next patient called.')));
  }

  Future<void> _delete(BuildContext context, OpdQueueViewModel viewModel, OpdToken token) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this token?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove', style: TextStyle(color: Color(0xFFB3261E)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await viewModel.destroy(token.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Token removed.')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OpdQueueViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: kInk, elevation: 0, title: const Text('OPD Queue', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _issueToken(context, viewModel),
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Issue token', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    );
  }

  Widget _buildBody(BuildContext context, OpdQueueViewModel viewModel) {
    if (viewModel.isLoading && viewModel.tokens.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.tokens.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }

    final stats = viewModel.stats;
    final byDoctor = <int, List<OpdToken>>{};
    for (final t in viewModel.tokens) {
      byDoctor.putIfAbsent(t.doctorId, () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        if (stats != null)
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: [
              _StatTile(label: 'Total', value: '${stats.total}', color: kTealDark, bg: kMint),
              _StatTile(label: 'Waiting', value: '${stats.waiting}', color: kWarningFg, bg: kWarningBg),
              _StatTile(label: 'In Consult', value: '${stats.inConsult}', color: kInfoFg, bg: kInfoBg),
              _StatTile(label: 'Completed', value: '${stats.completed}', color: kSuccessFg, bg: kSuccessBg),
            ],
          ),
        const SizedBox(height: 16),
        if (viewModel.tokens.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('No tokens in today\'s queue', style: TextStyle(color: kMuted))))
        else
          for (final entry in byDoctor.entries) ...[
            Row(
              children: [
                Expanded(child: Text(entry.value.first.doctorName ?? 'Doctor', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk))),
                TextButton.icon(
                  onPressed: () => _callNext(context, viewModel, entry.key),
                  icon: const Icon(Icons.skip_next_rounded, size: 16, color: kTealDark),
                  label: const Text('Call Next', style: TextStyle(color: kTealDark, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            for (final token in entry.value) ...[
              _TokenCard(
                token: token,
                onCallIn: () => _setStatus(context, viewModel, token, 'in_consultation'),
                onSkip: () => _setStatus(context, viewModel, token, 'skipped'),
                onComplete: () => _setStatus(context, viewModel, token, 'completed'),
                onDelete: () => _delete(context, viewModel, token),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TokenCard extends StatelessWidget {
  final OpdToken token;
  final VoidCallback onCallIn;
  final VoidCallback onSkip;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  const _TokenCard({required this.token, required this.onCallIn, required this.onSkip, required this.onComplete, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _tokenStatusColors(token.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(7)),
                child: Text('#${token.queuePosition}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kInk)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(token.patientName ?? 'Patient', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Text(titleCase(token.status), style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(token.patientMrn ?? '', style: const TextStyle(fontSize: 12, color: kMuted)),
          if ((token.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(token.notes!, style: const TextStyle(fontSize: 12, color: kMuted)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (token.status == 'waiting') ...[
                TextButton(onPressed: onSkip, child: const Text('Skip', style: TextStyle(color: kMuted, fontSize: 12.5, fontWeight: FontWeight.w600))),
                TextButton(onPressed: onCallIn, child: const Text('Call In', style: TextStyle(color: kTealDark, fontSize: 12.5, fontWeight: FontWeight.w600))),
              ],
              if (token.status == 'in_consultation')
                TextButton(onPressed: onComplete, child: const Text('Complete', style: TextStyle(color: kTealDark, fontSize: 12.5, fontWeight: FontWeight.w600))),
              TextButton(onPressed: onDelete, child: const Text('Remove', style: TextStyle(color: Color(0xFFB3261E), fontSize: 12.5, fontWeight: FontWeight.w600))),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueTokenDialog extends StatefulWidget {
  const _IssueTokenDialog();

  @override
  State<_IssueTokenDialog> createState() => _IssueTokenDialogState();
}

class _IssueTokenDialogState extends State<_IssueTokenDialog> {
  final _api = ReceptionistApiService();
  final _authStorage = AuthStorage();
  final _notesController = TextEditingController();

  bool _isLoadingDoctors = true;
  List<ReceptionDoctor> _doctors = [];
  ReceptionPatient? _patient;
  ReceptionDoctor? _doctor;
  String? _patientError;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    try {
      final token = await _authStorage.readToken();
      _doctors = await guardNetworkErrors(() => _api.doctors(token!));
    } catch (_) {
      _doctors = [];
    } finally {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Issue OPD token'),
      content: SizedBox(
        width: 360,
        child: _isLoadingDoctors
            ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: kTeal)))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReceptionPatientPickerField(value: _patient, errorText: _patientError, onChanged: (p) => setState(() { _patient = p; _patientError = null; })),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ReceptionDoctor>(
                      initialValue: _doctor,
                      decoration: const InputDecoration(labelText: 'Doctor', border: OutlineInputBorder()),
                      items: _doctors.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
                      onChanged: (v) => setState(() => _doctor = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder())),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kTealDark),
          onPressed: (_patient == null || _doctor == null)
              ? null
              : () => Navigator.of(context).pop({'patient_id': _patient!.id, 'doctor_id': _doctor!.id, 'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim()}),
          child: const Text('Issue token'),
        ),
      ],
    );
  }
}
