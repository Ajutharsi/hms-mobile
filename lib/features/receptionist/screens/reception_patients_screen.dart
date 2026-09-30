import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';
import 'package:hms_mobile/features/receptionist/screens/patient_form_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/reception_patient_detail_screen.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/reception_patients_view_model.dart';

class ReceptionPatientsScreen extends StatelessWidget {
  const ReceptionPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => ReceptionPatientsViewModel(),
      child: const _ReceptionPatientsView(),
    );
  }
}

class _ReceptionPatientsView extends StatefulWidget {
  const _ReceptionPatientsView();

  @override
  State<_ReceptionPatientsView> createState() => _ReceptionPatientsViewState();
}

class _ReceptionPatientsViewState extends State<_ReceptionPatientsView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addPatient(BuildContext context, ReceptionPatientsViewModel viewModel) async {
    final added = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const PatientFormScreen()));
    if (added == true) viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<ReceptionPatientsViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Patients'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPatient(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add patient', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchController,
              decoration: careFieldDecoration('Search patients', hint: 'Name or MRN', icon: Icons.search),
              onSubmitted: viewModel.search,
              onChanged: (v) {
                if (v.isEmpty) viewModel.search('');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _FilterChip(label: 'All', selected: viewModel.typeFilter == null, onTap: () => viewModel.setTypeFilter(null)),
                const SizedBox(width: 8),
                _FilterChip(label: 'OP', selected: viewModel.typeFilter == 'op', onTap: () => viewModel.setTypeFilter('op')),
                const SizedBox(width: 8),
                _FilterChip(label: 'IP', selected: viewModel.typeFilter == 'ip', onTap: () => viewModel.setTypeFilter('ip')),
              ],
            ),
          ),
          Expanded(child: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel))),
        ],
      ),
    ));
  }

  Widget _buildBody(BuildContext context, ReceptionPatientsViewModel viewModel) {
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
        Icon(Icons.people_outline, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No patients found', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: viewModel.patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = viewModel.patients[index];
        return _PatientCard(
          patient: p,
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReceptionPatientDetailScreen(patientId: p.id)));
            viewModel.load();
          },
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: selected ? kCareDark : kCareBg, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : kMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final ReceptionPatient patient;
  final VoidCallback onTap;
  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final active = patient.status == 'active';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kCareBorder)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kCareSoft,
              backgroundImage: patient.photoUrl != null ? NetworkImage(patient.photoUrl!) : null,
              child: patient.photoUrl == null ? Text(patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?', style: TextStyle(color: kCareDark, fontWeight: FontWeight.w700)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk)),
                  const SizedBox(height: 2),
                  Text('${patient.mrn} · ${patient.gender ?? '—'}', style: const TextStyle(fontSize: 12, color: kMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: patient.patientType == 'ip' ? kWarningBg : kInfoBg, borderRadius: BorderRadius.circular(7)),
                  child: Text(patient.patientType.toUpperCase(), style: TextStyle(color: patient.patientType == 'ip' ? kWarningFg : kInfoFg, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: active ? kSuccessBg : kCareBg, borderRadius: BorderRadius.circular(7)),
                  child: Text(patient.status, style: TextStyle(color: active ? kSuccessFg : kMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
