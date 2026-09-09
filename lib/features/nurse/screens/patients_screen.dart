import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';
import 'package:hms_mobile/features/nurse/screens/nurse_patient_detail_screen.dart';
import 'package:hms_mobile/features/nurse/viewmodels/nurse_patients_view_model.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
    final viewModel = context.watch<NursePatientsViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('Patients', style: TextStyle(fontWeight: FontWeight.w700))),
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
                fillColor: kFieldFill,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
              color: kTeal,
              onRefresh: viewModel.load,
              child: _buildBody(context, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, NursePatientsViewModel viewModel) {
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
        Icon(Icons.people_outline, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No patients found', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
      ]);
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

class _PatientCard extends StatelessWidget {
  final NursePatient patient;
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: kMint,
              backgroundImage: patient.photoUrl != null ? NetworkImage(patient.photoUrl!) : null,
              child: patient.photoUrl == null
                  ? Text(patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?', style: const TextStyle(color: kTealDark, fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk)),
                  const SizedBox(height: 2),
                  Text(
                    [patient.mrn, if ((patient.gender ?? '').isNotEmpty) patient.gender!].join(' · '),
                    style: const TextStyle(fontSize: 12, color: kMuted),
                  ),
                ],
              ),
            ),
            if (patient.isAdmitted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: kInfoBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${patient.wardName}${patient.bedNo != null ? ' · ${patient.bedNo}' : ''}',
                  style: const TextStyle(color: kInfoFg, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(8)),
                child: Text(patient.patientType.toUpperCase(), style: const TextStyle(color: kMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
