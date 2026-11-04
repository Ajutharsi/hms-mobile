import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/ward.dart';
import 'package:hms_mobile/features/nurse/viewmodels/admit_patient_view_model.dart';
import 'package:hms_mobile/features/patient/models/doctor.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

class AdmitPatientScreen extends StatelessWidget {
  const AdmitPatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => AdmitPatientViewModel(),
      child: const _AdmitPatientView(),
    );
  }
}

class _AdmitPatientView extends StatefulWidget {
  const _AdmitPatientView();

  @override
  State<_AdmitPatientView> createState() => _AdmitPatientViewState();
}

class _AdmitPatientViewState extends State<_AdmitPatientView> {
  final _patientSearchController = TextEditingController();

  @override
  void dispose() {
    _patientSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(AdmitPatientViewModel viewModel) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.admissionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) viewModel.selectAdmissionDate(picked);
  }

  Future<void> _submit(AdmitPatientViewModel viewModel) async {
    final success = await viewModel.submit();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdmitPatientViewModel>();

    return CareTheme(child: Scaffold(
      appBar: carePageAppBar(context, 'Admit Patient'),
      body: viewModel.isLoadingMeta
          ? Center(child: CircularProgressIndicator(color: kCare))
          : viewModel.metaError != null
              ? Center(child: Text(viewModel.metaError!, style: CareText.muted))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    const Text('Patient', style: CareText.titleSm),
                    const SizedBox(height: 8),
                    if (viewModel.selectedPatient != null)
                      _SelectedChip(
                        label: '${viewModel.selectedPatient!.name} · ${viewModel.selectedPatient!.mrn}',
                        onClear: () {
                          viewModel.clearPatient();
                          _patientSearchController.clear();
                        },
                      )
                    else ...[
                      TextField(
                        controller: _patientSearchController,
                        decoration: careFieldDecoration('Search patient', hint: 'Name or MRN', icon: Icons.search),
                        onChanged: viewModel.searchPatients,
                      ),
                      if (viewModel.isSearchingPatients) Padding(padding: const EdgeInsets.only(top: 8), child: LinearProgressIndicator(color: kCare)),
                      if (viewModel.patientResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(CareRadius.control)),
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: viewModel.patientResults.length,
                            itemBuilder: (context, i) {
                              final p = viewModel.patientResults[i];
                              return ListTile(
                                dense: true,
                                title: Text(p.name, style: const TextStyle(fontSize: CareText.md, fontWeight: CareText.medium)),
                                subtitle: Text(p.mrn, style: const TextStyle(fontSize: CareText.sm)),
                                onTap: () => viewModel.selectPatient(p),
                              );
                            },
                          ),
                        ),
                    ],
                    const SizedBox(height: 20),
                    const Text('Ward', style: CareText.titleSm),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Ward>(
                  isExpanded: true,
                      initialValue: viewModel.selectedWard,
                      decoration: careFieldDecoration('Ward', hint: 'Select ward', icon: Icons.holiday_village_outlined),
                      items: viewModel.wards.map((w) => DropdownMenuItem(value: w, child: Text('${w.name} (${w.availableBeds} free)', overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: viewModel.selectWard,
                    ),
                    const SizedBox(height: 16),
                    const Text('Bed', style: CareText.titleSm),
                    const SizedBox(height: 8),
                    if (viewModel.isLoadingBeds)
                      LinearProgressIndicator(color: kCare)
                    else
                      DropdownButtonFormField<Bed>(
                  isExpanded: true,
                        initialValue: viewModel.selectedBed,
                        decoration: careFieldDecoration('Bed', hint: 'Select bed', icon: Icons.bed_outlined),
                        items: viewModel.availableBeds.map((b) => DropdownMenuItem(value: b, child: Text(b.bedNo, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: viewModel.selectedWard == null ? null : viewModel.selectBed,
                      ),
                    const SizedBox(height: 16),
                    const Text('Doctor', style: CareText.titleSm),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Doctor>(
                  isExpanded: true,
                      initialValue: viewModel.selectedDoctor,
                      decoration: careFieldDecoration('Doctor', hint: 'Select doctor', icon: Icons.medical_information_outlined),
                      items: viewModel.doctors.map((d) => DropdownMenuItem(value: d, child: Text(d.label, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: viewModel.selectDoctor,
                    ),
                    const SizedBox(height: 16),
                    const Text('Admission date', style: CareText.titleSm),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickDate(viewModel),
                      child: InputDecorator(
                        decoration: careFieldDecoration('Admission date', hint: '', icon: Icons.calendar_today_outlined),
                        child: Text(
                          '${viewModel.admissionDate.year}-${viewModel.admissionDate.month.toString().padLeft(2, '0')}-${viewModel.admissionDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: viewModel.reasonController,
                      maxLines: 3,
                      decoration: careFieldDecoration('Admission reason (optional)', hint: 'Reason for admission', icon: Icons.notes_outlined),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: viewModel.canSubmit && !viewModel.isSubmitting ? () => _submit(viewModel) : null,
                        style: ElevatedButton.styleFrom(backgroundColor: kCareDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CareRadius.control))),
                        child: viewModel.isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Admit patient', style: CareText.onCareBold),
                      ),
                    ),
                  ],
                ),
    ));
  }
}

class _SelectedChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  const _SelectedChip({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: kCareSoft, borderRadius: BorderRadius.circular(CareRadius.control)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: CareText.md, fontWeight: CareText.medium, color: kCareDark))),
          InkWell(onTap: onClear, child: Icon(Icons.close, size: 18, color: kCareDark)),
        ],
      ),
    );
  }
}
