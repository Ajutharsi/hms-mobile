import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/doctor/models/doctor_models.dart';
import 'package:hms_mobile/features/doctor/screens/prescription_form_screen.dart';
import 'package:hms_mobile/features/doctor/viewmodels/doctor_view_models.dart';

/// Writing up a visit: complaint, diagnosis (with the ICD-10 lookup),
/// plan and the vitals taken in the room. Saving also completes the
/// appointment, exactly as the web consultation form does.
class ConsultationFormScreen extends StatelessWidget {
  final int appointmentId;
  final String patientName;
  final VitalsSnapshot? prefillVitals;

  const ConsultationFormScreen({
    super.key,
    required this.appointmentId,
    required this.patientName,
    this.prefillVitals,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConsultationFormViewModel(appointmentId: appointmentId, prefillVitals: prefillVitals),
      child: CareTheme(child: _ConsultationFormView(patientName: patientName)),
    );
  }
}

class _ConsultationFormView extends StatelessWidget {
  final String patientName;
  const _ConsultationFormView({required this.patientName});

  Future<void> _submit(BuildContext context, ConsultationFormViewModel viewModel) async {
    final consultation = await viewModel.submit();
    if (consultation == null || !context.mounted) return;

    // Straight on to the prescription — that's the next thing a doctor
    // does, and the visit is otherwise finished.
    final wantsPrescription = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Consultation saved'),
        content: const Text('Write the prescription for this visit now?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Later')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Write prescription', style: TextStyle(color: kCareDark, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (!context.mounted) return;

    if (wantsPrescription == true) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PrescriptionFormScreen(consultationId: consultation.id, patientName: patientName),
      ));
    }
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<ConsultationFormViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, 'Consultation'),
      body: Form(
        key: viewModel.formKey,
        child: ListView(
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
                        const Text('Writing up this visit', style: TextStyle(fontSize: 12.5, color: kMuted)),
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
            TextFormField(
              controller: viewModel.chiefComplaintController,
              maxLines: 3,
              style: const TextStyle(color: kInk, fontSize: 14.5),
              decoration: careFieldDecoration('Chief complaint', hint: 'What the patient came in with', icon: Icons.record_voice_over_rounded),
              validator: viewModel.validateChiefComplaint,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: viewModel.diagnosisController,
              maxLines: 2,
              onChanged: viewModel.searchIcd10,
              style: const TextStyle(color: kInk, fontSize: 14.5),
              decoration: careFieldDecoration('Diagnosis', hint: 'Type to search ICD-10 codes', icon: Icons.medical_information_rounded).copyWith(
                suffixIcon: viewModel.searchingCodes
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kCare)),
                      )
                    : null,
              ),
            ),
            if (viewModel.icd10Code != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    CareChip(label: 'ICD-10 ${viewModel.icd10Code}', bg: kCareSoft, fg: kCareDark, icon: Icons.tag_rounded),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: viewModel.clearCode,
                      child: const Text('Clear', style: TextStyle(fontSize: 12.5, color: kMuted, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            if (viewModel.suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CareCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final suggestion in viewModel.suggestions)
                        ListTile(
                          dense: true,
                          title: Text(suggestion.code, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk)),
                          subtitle: Text(suggestion.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: kMuted)),
                          onTap: () => viewModel.pickCode(suggestion),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: viewModel.treatmentController,
              maxLines: 3,
              style: const TextStyle(color: kInk, fontSize: 14.5),
              decoration: careFieldDecoration('Treatment plan', hint: 'What you advised', icon: Icons.assignment_turned_in_rounded),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: viewModel.notesController,
              maxLines: 2,
              style: const TextStyle(color: kInk, fontSize: 14.5),
              decoration: careFieldDecoration('Notes (optional)', hint: 'Anything else worth recording', icon: Icons.notes_rounded),
            ),
            const SizedBox(height: 22),
            const CareSectionTitle(title: 'Vitals'),
            const SizedBox(height: 4),
            const Text(
              "Pre-filled from nursing's latest reading — change them if you took your own.",
              style: TextStyle(fontSize: 12.5, color: kMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: viewModel.bloodPressureController,
                    style: const TextStyle(color: kInk, fontSize: 14.5),
                    decoration: careFieldDecoration('BP', hint: '120/80', icon: Icons.monitor_heart_rounded),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: viewModel.temperatureController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: kInk, fontSize: 14.5),
                    decoration: careFieldDecoration('Temp °C', hint: '37.0', icon: Icons.thermostat_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: viewModel.pulseController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kInk, fontSize: 14.5),
                    decoration: careFieldDecoration('Pulse', hint: '78', icon: Icons.favorite_rounded),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: viewModel.spo2Controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kInk, fontSize: 14.5),
                    decoration: careFieldDecoration('SpO₂ %', hint: '98', icon: Icons.air_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: viewModel.weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: kInk, fontSize: 14.5),
                    decoration: careFieldDecoration('Weight kg', hint: '70', icon: Icons.monitor_weight_rounded),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: viewModel.heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: kInk, fontSize: 14.5),
                    decoration: careFieldDecoration('Height cm', hint: '170', icon: Icons.height_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: CarePrimaryButton(
            label: 'Save consultation',
            icon: Icons.check_circle_outline_rounded,
            loading: viewModel.isSaving,
            onPressed: () => _submit(context, viewModel),
          ),
        ),
      ),
    );
  }
}
