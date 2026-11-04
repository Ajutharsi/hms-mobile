import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';
import 'package:hms_mobile/features/nurse/screens/nurse_patient_detail_screen.dart';
import 'package:hms_mobile/features/nurse/viewmodels/nurse_patients_view_model.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => NursePatientsViewModel(),
      child: const _PatientsView(),
    );
  }
}

class _PatientsView extends StatelessWidget {
  const _PatientsView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<NursePatientsViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Patients'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              onChanged: viewModel.search,
              decoration: InputDecoration(
                hintText: 'Search by name or MRN',
                prefixIcon: const Icon(Icons.search, color: kMuted, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(CareRadius.control), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(label: 'All', selected: viewModel.typeFilter == null, onTap: () => viewModel.setTypeFilter(null)),
                const SizedBox(width: 8),
                _FilterChip(label: 'In-patient', selected: viewModel.typeFilter == 'ip', onTap: () => viewModel.setTypeFilter('ip')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Out-patient', selected: viewModel.typeFilter == 'op', onTap: () => viewModel.setTypeFilter('op')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              color: kCare,
              onRefresh: viewModel.load,
              child: _buildBody(context, viewModel),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildBody(BuildContext context, NursePatientsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.patients.isEmpty) {
      return const CareStateView.loading();
    }
    if (viewModel.loadError != null && viewModel.patients.isEmpty) {
      return CareStateView.error(viewModel.loadError!);
    }
    if (viewModel.patients.isEmpty) {
      return const CareStateView(icon: Icons.people_outline, title: 'No patients found');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: viewModel.patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = viewModel.patients[index];
        return _PatientCard(
          patient: p,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NursePatientDetailScreen(patientId: p.id))),
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
    watchCarePalette(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CareRadius.panel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: selected ? kCareDark : kCareBg, borderRadius: BorderRadius.circular(CareRadius.panel)),
        child: Text(label, style: CareText.tag(selected ? Colors.white : kMuted, size: CareText.sm)),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final NursePatient patient;
  final VoidCallback onTap;
  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CareRadius.card),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(CareRadius.card), border: Border.all(color: kCareBorder)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: kCareSoft,
              backgroundImage: patient.photoUrl != null ? NetworkImage(patient.photoUrl!) : null,
              child: patient.photoUrl == null
                  ? Text(patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?', style: CareText.brandBold)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.name, style: CareText.titleLg),
                  const SizedBox(height: 2),
                  Text(
                    [patient.mrn, if ((patient.gender ?? '').isNotEmpty) patient.gender!].join(' · '),
                    style: CareText.mutedXs,
                  ),
                ],
              ),
            ),
            if (patient.isAdmitted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: kInfoBg, borderRadius: BorderRadius.circular(CareRadius.chip)),
                child: Text(
                  '${patient.wardName}${patient.bedNo != null ? ' · ${patient.bedNo}' : ''}',
                  style: const TextStyle(color: kInfoFg, fontSize: CareText.xxs, fontWeight: CareText.bold),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(CareRadius.chip)),
                child: Text(patient.patientType.toUpperCase(), style: const TextStyle(color: kMuted, fontSize: CareText.xxs, fontWeight: CareText.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
