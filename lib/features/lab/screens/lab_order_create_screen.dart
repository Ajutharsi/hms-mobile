import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/lab/viewmodels/lab_order_create_view_model.dart';

class LabOrderCreateScreen extends StatelessWidget {
  const LabOrderCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => LabOrderCreateViewModel(),
      child: const _LabOrderCreateView(),
    );
  }
}

class _LabOrderCreateView extends StatefulWidget {
  const _LabOrderCreateView();

  @override
  State<_LabOrderCreateView> createState() => _LabOrderCreateViewState();
}

class _LabOrderCreateViewState extends State<_LabOrderCreateView> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(LabOrderCreateViewModel viewModel) async {
    final (id, error) = await viewModel.submit(notes: _notesController.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<LabOrderCreateViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'New Lab Order'),
      body: viewModel.isLoadingMeta
          ? Center(child: CircularProgressIndicator(color: kCare))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const Text('Patient', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
                const SizedBox(height: 8),
                if (viewModel.selectedPatient != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kCareSoft, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(viewModel.selectedPatient!.name, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                              Text(viewModel.selectedPatient!.mrn, style: const TextStyle(fontSize: 12, color: kMuted)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: viewModel.clearPatient,
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  )
                else ...[
                  TextField(
                    controller: _searchController,
                    decoration: careFieldDecoration('Search patient', hint: 'Name or MRN', icon: Icons.search),
                    onChanged: viewModel.searchPatients,
                  ),
                  if (viewModel.patientResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(12)),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: viewModel.patientResults.length,
                        itemBuilder: (context, index) {
                          final p = viewModel.patientResults[index];
                          return ListTile(
                            dense: true,
                            title: Text(p.name),
                            subtitle: Text(p.mrn),
                            onTap: () {
                              viewModel.selectPatient(p);
                              _searchController.clear();
                            },
                          );
                        },
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                const Text('Doctor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
                const SizedBox(height: 8),
                DropdownButtonFormField(
                  initialValue: viewModel.selectedDoctor,
                  decoration: careFieldDecoration('Doctor', hint: 'Select doctor', icon: Icons.medical_services_outlined),
                  items: viewModel.doctors.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
                  onChanged: viewModel.selectDoctor,
                ),
                const SizedBox(height: 20),
                const Text('Tests', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
                const SizedBox(height: 8),
                if (viewModel.availableTests.isEmpty)
                  const Text('No active tests in the catalog.', style: TextStyle(color: kMuted, fontSize: 13))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in viewModel.availableTests)
                        FilterChip(
                          label: Text(t.testName),
                          selected: viewModel.selectedTestIds.contains(t.id),
                          onSelected: (_) => viewModel.toggleTest(t.id),
                          selectedColor: kCareSoft,
                          checkmarkColor: kCareDark,
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                TextField(
                  controller: _notesController,
                  decoration: careFieldDecoration('Notes', hint: 'Optional', icon: Icons.notes_outlined),
                  maxLines: 3,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  authErrorBanner(_error!),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: viewModel.isSaving ? null : () => _submit(viewModel),
                    style: ElevatedButton.styleFrom(backgroundColor: kCareDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: viewModel.isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Create order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    ));
  }
}
