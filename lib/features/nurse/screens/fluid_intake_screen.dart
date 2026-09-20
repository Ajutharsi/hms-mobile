import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/fluid_intake.dart';
import 'package:hms_mobile/features/nurse/viewmodels/fluid_intake_view_model.dart';

const _kFlowTypes = ['intake', 'output'];
const _kCategories = ['oral', 'iv', 'tube_feed', 'urine', 'vomit', 'drain', 'stool', 'other'];

String _titleCase(String s) => s.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

class FluidIntakeScreen extends StatelessWidget {
  const FluidIntakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => FluidIntakeViewModel(),
      child: const _FluidIntakeView(),
    );
  }
}

class _FluidIntakeView extends StatelessWidget {
  const _FluidIntakeView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<FluidIntakeViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Fluid Intake'),
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    ));
  }

  Widget _buildBody(BuildContext context, FluidIntakeViewModel viewModel) {
    if (viewModel.isLoading && viewModel.patients.isEmpty) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }
    if (viewModel.loadError != null && viewModel.patients.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.patients.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.opacity_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No in-patients to track right now', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: viewModel.patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = viewModel.patients[index];
        return _PatientCard(
          patient: p,
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => FluidIntakeDetailScreen(patientId: p.id, patientName: p.name)));
            viewModel.load();
          },
        );
      },
    );
  }
}

class _PatientCard extends StatelessWidget {
  final FluidIntakePatient patient;
  final VoidCallback onTap;
  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final negative = patient.balance < 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kCareBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(patient.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 2),
            Text(
              [patient.mrn, if (patient.wardName != null) '${patient.wardName} · ${patient.bedNo ?? ''}'].join(' · '),
              style: const TextStyle(fontSize: 12, color: kMuted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Reading(label: 'Intake', value: '${patient.intake} ml', color: kInfoFg),
                const SizedBox(width: 16),
                _Reading(label: 'Output', value: '${patient.output} ml', color: kWarningFg),
                const SizedBox(width: 16),
                _Reading(label: 'Balance', value: '${patient.balance} ml', color: negative ? kDangerFg : kSuccessFg),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Reading({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: kMuted)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class FluidIntakeDetailScreen extends StatelessWidget {
  final int patientId;
  final String patientName;
  const FluidIntakeDetailScreen({super.key, required this.patientId, required this.patientName});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => FluidIntakeDetailViewModel(patientId: patientId),
      child: _FluidIntakeDetailView(patientName: patientName),
    );
  }
}

class _FluidIntakeDetailView extends StatelessWidget {
  final String patientName;
  const _FluidIntakeDetailView({required this.patientName});

  Future<void> _logFluid(BuildContext context, FluidIntakeDetailViewModel viewModel) async {
    final result = await showDialog<Map<String, String>>(context: context, builder: (_) => const _LogFluidDialog());
    if (result == null || !context.mounted) return;
    final error = await viewModel.logFluid(
      flowType: result['flow_type']!,
      category: result['category']!,
      amountMl: int.tryParse(result['amount_ml'] ?? '') ?? 0,
      logTime: result['log_time']!,
      notes: result['notes']?.isEmpty == true ? null : result['notes'],
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Fluid logged.')));
  }

  Future<void> _delete(BuildContext context, FluidIntakeDetailViewModel viewModel, FluidLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Color(0xFFB3261E)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await viewModel.deleteLog(log.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Entry deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<FluidIntakeDetailViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, patientName),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logFluid(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log fluid', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    ));
  }

  Widget _buildBody(BuildContext context, FluidIntakeDetailViewModel viewModel) {
    if (viewModel.isLoading && viewModel.logs.isEmpty) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }
    if (viewModel.loadError != null) {
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
            Expanded(child: _StatTile(label: "Today's intake", value: '${viewModel.todayIntake} ml', color: kInfoFg, bg: kInfoBg)),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(label: "Today's output", value: '${viewModel.todayOutput} ml', color: kWarningFg, bg: kWarningBg)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.3)),
        const SizedBox(height: 10),
        if (viewModel.logs.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: Text('No fluid entries yet', style: TextStyle(color: kMuted))))
        else
          for (final log in viewModel.logs) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: log.flowType == 'intake' ? kInfoBg : kWarningBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.flowType == 'intake' ? 'IN' : 'OUT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: log.flowType == 'intake' ? kInfoFg : kWarningFg),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_titleCase(log.category)} · ${log.amountMl} ml', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
                        Text('${log.logDate} ${log.logTime}', style: const TextStyle(fontSize: 11.5, color: kMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _delete(context, viewModel, log),
                    icon: const Icon(Icons.delete_outline, size: 18, color: kMuted),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
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
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LogFluidDialog extends StatefulWidget {
  const _LogFluidDialog();

  @override
  State<_LogFluidDialog> createState() => _LogFluidDialogState();
}

class _LogFluidDialogState extends State<_LogFluidDialog> {
  String _flowType = _kFlowTypes.first;
  String _category = _kCategories.first;
  final _amountController = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return AlertDialog(
      title: const Text('Log fluid'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _flowType,
              decoration: const InputDecoration(labelText: 'Flow type'),
              items: _kFlowTypes.map((t) => DropdownMenuItem(value: t, child: Text(_titleCase(t)))).toList(),
              onChanged: (v) => setState(() => _flowType = v!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _kCategories.map((c) => DropdownMenuItem(value: c, child: Text(_titleCase(c)))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 10),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (ml)')),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(decoration: const InputDecoration(labelText: 'Time'), child: Text(_time.format(context))),
            ),
            const SizedBox(height: 10),
            TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            'flow_type': _flowType,
            'category': _category,
            'amount_ml': _amountController.text.trim(),
            'log_time': '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
            'notes': _notes.text.trim(),
          }),
          style: FilledButton.styleFrom(backgroundColor: kCareDark),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
