import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/doctor/viewmodels/doctor_view_models.dart';

/// The prescription attached to a consultation — one card per medicine,
/// the same fields the web's prescription form posts.
class PrescriptionFormScreen extends StatelessWidget {
  final int consultationId;
  final String patientName;

  const PrescriptionFormScreen({super.key, required this.consultationId, required this.patientName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrescriptionFormViewModel(consultationId: consultationId),
      child: CareTheme(child: _PrescriptionFormView(patientName: patientName)),
    );
  }
}

class _PrescriptionFormView extends StatelessWidget {
  final String patientName;
  const _PrescriptionFormView({required this.patientName});

  static const _routes = ['oral', 'iv', 'im', 'topical', 'inhaled'];

  Future<void> _submit(BuildContext context, PrescriptionFormViewModel viewModel) async {
    final saved = await viewModel.submit();
    if (!context.mounted) return;
    if (!saved) return;

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: kCareDark, content: const Text('Prescription saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<PrescriptionFormViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, 'Prescription'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          CareCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CareAvatar(name: patientName, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patientName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                      const Text('Medicines for this visit', style: TextStyle(fontSize: 12.5, color: kMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (viewModel.errorMessage != null) ...[
            authErrorBanner(viewModel.errorMessage!),
            const SizedBox(height: 14),
          ],
          for (var i = 0; i < viewModel.medicines.length; i++) ...[
            _MedicineCard(
              index: i,
              draft: viewModel.medicines[i],
              routes: _routes,
              canRemove: viewModel.medicines.length > 1,
              onRemove: () => viewModel.removeMedicine(i),
              onRoute: (value) => viewModel.setRoute(i, value),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: viewModel.addMedicine,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Add another medicine', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: viewModel.notesController,
            maxLines: 2,
            style: const TextStyle(color: kInk, fontSize: 14.5),
            decoration: careFieldDecoration('Notes (optional)', hint: 'e.g. take after food', icon: Icons.notes_rounded),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: CarePrimaryButton(
            label: 'Save prescription',
            icon: Icons.check_circle_outline_rounded,
            loading: viewModel.isSaving,
            onPressed: () => _submit(context, viewModel),
          ),
        ),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final int index;
  final MedicineDraft draft;
  final List<String> routes;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<String> onRoute;

  const _MedicineCard({
    required this.index,
    required this.draft,
    required this.routes,
    required this.canRemove,
    required this.onRemove,
    required this.onRoute,
  });

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return CareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CareIconBox(icon: Icons.medication_rounded, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Medicine ${index + 1}', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk)),
              ),
              if (canRemove)
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  icon: Icon(Icons.delete_outline_rounded, color: kCarePinkFg, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.nameController,
            style: const TextStyle(color: kInk, fontSize: 14.5),
            decoration: careFieldDecoration('Medicine', hint: 'e.g. Paracetamol 500mg', icon: Icons.medication_liquid_rounded),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.dosageController,
                  style: const TextStyle(color: kInk, fontSize: 14.5),
                  decoration: careFieldDecoration('Dosage', hint: '1 tablet', icon: Icons.straighten_rounded),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: draft.frequencyController,
                  style: const TextStyle(color: kInk, fontSize: 14.5),
                  decoration: careFieldDecoration('Frequency', hint: 'BD / TDS', icon: Icons.repeat_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.durationController,
            style: const TextStyle(color: kInk, fontSize: 14.5),
            decoration: careFieldDecoration('Duration', hint: '5 days', icon: Icons.calendar_month_rounded),
          ),
          const SizedBox(height: 12),
          const Text('Route', style: TextStyle(fontSize: 12.5, color: kMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final route in routes)
                CareChoicePill(
                  label: route.toUpperCase(),
                  selected: draft.route == route,
                  onTap: () => onRoute(route),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.instructionsController,
            style: const TextStyle(color: kInk, fontSize: 14.5),
            decoration: careFieldDecoration('Instructions (optional)', hint: 'After food', icon: Icons.info_outline_rounded),
          ),
        ],
      ),
    );
  }
}
