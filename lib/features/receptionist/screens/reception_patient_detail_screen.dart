import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';
import 'package:hms_mobile/features/receptionist/screens/patient_form_screen.dart';

class ReceptionPatientDetailScreen extends StatefulWidget {
  final int patientId;
  const ReceptionPatientDetailScreen({super.key, required this.patientId});

  @override
  State<ReceptionPatientDetailScreen> createState() => _ReceptionPatientDetailScreenState();
}

class _ReceptionPatientDetailScreenState extends State<ReceptionPatientDetailScreen> {
  final _api = ReceptionistApiService();
  final _authStorage = AuthStorage();

  bool _isLoading = true;
  String? _error;
  ReceptionPatientDetail? _patient;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await _authStorage.readToken();
      _patient = await guardNetworkErrors(() => _api.patientDetail(token!, widget.patientId));
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => PatientFormScreen(existing: _patient)));
    if (updated == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kInk,
        elevation: 0,
        title: const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [if (_patient != null) IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined))],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _patient == null) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (_error != null && _patient == null) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }

    final p = _patient!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: kMint,
                backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
                child: p.photoUrl == null ? Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 28, color: kTealDark, fontWeight: FontWeight.w700)) : null,
              ),
              const SizedBox(height: 12),
              Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(8)),
                child: Text('MRN: ${p.mrn}', style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
          child: Column(
            children: [
              _Row('Status', p.status),
              _Row('Type', p.patientType.toUpperCase()),
              _Row('Email', p.email ?? '—'),
              _Row('Phone', p.phone ?? '—'),
              _Row('Gender', p.gender ?? '—'),
              _Row('DOB', p.dob ?? '—'),
              _Row('Blood group', p.bloodGroup ?? '—'),
              _Row('Address', p.address ?? '—'),
              _Row('Emergency contact', p.emergencyContactName ?? '—'),
              _Row('Emergency phone', p.emergencyContact ?? '—'),
              _Row('Nationality', p.nationality ?? '—'),
              _Row('Marital status', p.maritalStatus ?? '—'),
              _Row('Occupation', p.occupation ?? '—', showDivider: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;
  const _Row(this.label, this.value, {this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: kMuted))),
            Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk))),
          ],
        ),
        if (showDivider) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kFieldFill)),
      ],
    );
  }
}
