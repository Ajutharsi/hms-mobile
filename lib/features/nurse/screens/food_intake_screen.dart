import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/nurse/models/food_intake.dart';
import 'package:hms_mobile/features/nurse/viewmodels/food_intake_view_model.dart';

const _kDietTypes = ['normal', 'diabetic', 'liquid', 'soft', 'low_salt', 'npo', 'other'];
const _kMealTypes = ['breakfast', 'lunch', 'snacks', 'dinner'];
const _kMealStatuses = ['pending', 'given', 'refused', 'partial'];
const _kQuantities = ['full', 'half', 'none'];

String _titleCase(String s) => s.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

class FoodIntakeScreen extends StatelessWidget {
  const FoodIntakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FoodIntakeViewModel(),
      child: const _FoodIntakeView(),
    );
  }
}

class _FoodIntakeView extends StatelessWidget {
  const _FoodIntakeView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FoodIntakeViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('Food Intake', style: TextStyle(fontWeight: FontWeight.w700))),
      body: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    );
  }

  Widget _buildBody(BuildContext context, FoodIntakeViewModel viewModel) {
    if (viewModel.isLoading && viewModel.patients.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
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
        Icon(Icons.restaurant_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No in-patients to feed right now', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
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
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => FoodIntakeDetailScreen(patientId: p.id, patientName: p.name)));
            viewModel.load();
          },
        );
      },
    );
  }
}

class _PatientCard extends StatelessWidget {
  final FoodIntakePatient patient;
  final VoidCallback onTap;
  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(patient.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: kMint, borderRadius: BorderRadius.circular(8)),
                  child: Text(_titleCase(patient.dietType), style: const TextStyle(color: kTealDark, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              [patient.mrn, if (patient.wardName != null) '${patient.wardName} · ${patient.bedNo ?? ''}'].join(' · '),
              style: const TextStyle(fontSize: 12, color: kMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.restaurant_menu_outlined, size: 14, color: kMuted),
                const SizedBox(width: 6),
                Text(
                  patient.lastMealType != null ? 'Last: ${_titleCase(patient.lastMealType!)} (${_titleCase(patient.lastMealStatus ?? '')})' : 'No meals logged',
                  style: const TextStyle(fontSize: 12.5, color: kMuted),
                ),
                const Spacer(),
                Text('${patient.mealsToday}/4 today', style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FoodIntakeDetailScreen extends StatelessWidget {
  final int patientId;
  final String patientName;
  const FoodIntakeDetailScreen({super.key, required this.patientId, required this.patientName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FoodIntakeDetailViewModel(patientId: patientId),
      child: _FoodIntakeDetailView(patientName: patientName),
    );
  }
}

class _FoodIntakeDetailView extends StatelessWidget {
  final String patientName;
  const _FoodIntakeDetailView({required this.patientName});

  Future<void> _updateDietPlan(BuildContext context, FoodIntakeDetailViewModel viewModel) async {
    final result = await showDialog<Map<String, String>>(context: context, builder: (_) => _DietPlanDialog(current: viewModel.dietPlan));
    if (result == null || !context.mounted) return;
    final error = await viewModel.updateDietPlan(
      dietType: result['diet_type']!,
      restrictions: result['restrictions']?.isEmpty == true ? null : result['restrictions'],
      notes: result['notes']?.isEmpty == true ? null : result['notes'],
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Diet plan updated.')));
  }

  Future<void> _logMeal(BuildContext context, FoodIntakeDetailViewModel viewModel) async {
    final result = await showDialog<Map<String, String>>(context: context, builder: (_) => const _LogMealDialog());
    if (result == null || !context.mounted) return;
    final error = await viewModel.logMeal(
      mealType: result['meal_type']!,
      status: result['status']!,
      quantity: (result['quantity']?.isEmpty ?? true) ? null : result['quantity'],
      notes: result['notes']?.isEmpty == true ? null : result['notes'],
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Meal logged.')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FoodIntakeDetailViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: Text(patientName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logMeal(context, viewModel),
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log a meal', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    );
  }

  Widget _buildBody(BuildContext context, FoodIntakeDetailViewModel viewModel) {
    if (viewModel.isLoading && viewModel.logs.isEmpty && viewModel.dietPlan == null) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Diet plan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk))),
                  TextButton(onPressed: () => _updateDietPlan(context, viewModel), child: const Text('Update')),
                ],
              ),
              if (viewModel.dietPlan != null) ...[
                Text(_titleCase(viewModel.dietPlan!.dietType), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTealDark)),
                if ((viewModel.dietPlan!.restrictions ?? '').isNotEmpty) Text('Restrictions: ${viewModel.dietPlan!.restrictions}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
                if ((viewModel.dietPlan!.notes ?? '').isNotEmpty) Text(viewModel.dietPlan!.notes!, style: const TextStyle(fontSize: 12.5, color: kMuted)),
              ] else
                const Text('No diet plan set.', style: TextStyle(fontSize: 13, color: kMuted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Meal log', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.3)),
        const SizedBox(height: 10),
        if (viewModel.logs.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: Text('No meals logged yet', style: TextStyle(color: kMuted))))
        else
          for (final log in viewModel.logs) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_titleCase(log.mealType)} · ${log.logDate}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
                        if ((log.notes ?? '').isNotEmpty) Text(log.notes!, style: const TextStyle(fontSize: 11.5, color: kMuted)),
                      ],
                    ),
                  ),
                  if (log.quantity != null) Padding(padding: const EdgeInsets.only(right: 8), child: Text(_titleCase(log.quantity!), style: const TextStyle(fontSize: 11.5, color: kMuted))),
                  Text(_titleCase(log.status), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTealDark)),
                ],
              ),
            ),
          ],
      ],
    );
  }
}

class _DietPlanDialog extends StatefulWidget {
  final DietPlan? current;
  const _DietPlanDialog({this.current});

  @override
  State<_DietPlanDialog> createState() => _DietPlanDialogState();
}

class _DietPlanDialogState extends State<_DietPlanDialog> {
  late String _dietType = widget.current?.dietType ?? _kDietTypes.first;
  late final _restrictions = TextEditingController(text: widget.current?.restrictions ?? '');
  late final _notes = TextEditingController(text: widget.current?.notes ?? '');

  @override
  void dispose() {
    _restrictions.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update diet plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _dietType,
              decoration: const InputDecoration(labelText: 'Diet type'),
              items: _kDietTypes.map((t) => DropdownMenuItem(value: t, child: Text(_titleCase(t)))).toList(),
              onChanged: (v) => setState(() => _dietType = v!),
            ),
            const SizedBox(height: 10),
            TextField(controller: _restrictions, decoration: const InputDecoration(labelText: 'Restrictions (optional)')),
            const SizedBox(height: 10),
            TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 2),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({'diet_type': _dietType, 'restrictions': _restrictions.text.trim(), 'notes': _notes.text.trim()}),
          style: FilledButton.styleFrom(backgroundColor: kTealDark),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _LogMealDialog extends StatefulWidget {
  const _LogMealDialog();

  @override
  State<_LogMealDialog> createState() => _LogMealDialogState();
}

class _LogMealDialogState extends State<_LogMealDialog> {
  String _mealType = _kMealTypes.first;
  String _status = _kMealStatuses.first;
  String? _quantity;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log a meal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _mealType,
              decoration: const InputDecoration(labelText: 'Meal'),
              items: _kMealTypes.map((t) => DropdownMenuItem(value: t, child: Text(_titleCase(t)))).toList(),
              onChanged: (v) => setState(() => _mealType = v!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _kMealStatuses.map((s) => DropdownMenuItem(value: s, child: Text(_titleCase(s)))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _quantity,
              decoration: const InputDecoration(labelText: 'Quantity (optional)'),
              items: _kQuantities.map((q) => DropdownMenuItem(value: q, child: Text(_titleCase(q)))).toList(),
              onChanged: (v) => setState(() => _quantity = v),
            ),
            const SizedBox(height: 10),
            TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({'meal_type': _mealType, 'status': _status, 'quantity': _quantity ?? '', 'notes': _notes.text.trim()}),
          style: FilledButton.styleFrom(backgroundColor: kTealDark),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
