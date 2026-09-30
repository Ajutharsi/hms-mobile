import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/doctor/screens/doctor_patient_detail_screen.dart';
import 'package:hms_mobile/features/doctor/viewmodels/doctor_view_models.dart';

/// Patient lookup by name or MRN — the same search the web's patient list
/// offers, so a doctor can pull up a record outside a booked visit.
class DoctorPatientsScreen extends StatelessWidget {
  const DoctorPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorPatientsViewModel(),
      child: const CareTheme(child: _PatientsView()),
    );
  }
}

class _PatientsView extends StatelessWidget {
  const _PatientsView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DoctorPatientsViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, 'Patients'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: viewModel.searchController,
              onChanged: viewModel.onSearchChanged,
              style: const TextStyle(color: kInk, fontSize: 14.5),
              decoration: careFieldDecoration('Search', hint: 'Name or MRN', icon: Icons.search_rounded),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kCare,
              onRefresh: viewModel.load,
              child: _buildList(context, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, DoctorPatientsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.patients.isEmpty) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.patients.isEmpty) return CareStateView.error(viewModel.loadError!);
    if (viewModel.patients.isEmpty) {
      return const CareStateView(
        icon: Icons.people_rounded,
        title: 'No patients found',
        message: 'Try a different name or MRN.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: viewModel.patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final patient = viewModel.patients[index];
        return CareCard(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DoctorPatientDetailScreen(patientId: patient.id, name: patient.name),
          )),
          child: Row(
            children: [
              CareAvatar(name: patient.name, imageUrl: patient.photoUrl, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        patient.mrn,
                        if ((patient.gender ?? '').isNotEmpty) patient.gender!,
                        if (patient.age != null) '${patient.age} yrs',
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12.5, color: kMuted),
                    ),
                  ],
                ),
              ),
              if ((patient.bloodGroup ?? '').isNotEmpty)
                CareChip(label: patient.bloodGroup!, bg: kCarePinkBg, fg: kCarePinkFg),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB5C2C0)),
            ],
          ),
        );
      },
    );
  }
}
