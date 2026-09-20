import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, guardNetworkErrors;
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';

class NursePatientDetailScreen extends StatefulWidget {
  final int patientId;
  const NursePatientDetailScreen({super.key, required this.patientId});

  @override
  State<NursePatientDetailScreen> createState() => _NursePatientDetailScreenState();
}

class _NursePatientDetailScreenState extends State<NursePatientDetailScreen> {
  final _api = NurseApiService();
  final _authStorage = AuthStorage();

  bool _isLoading = true;
  String? _error;
  NursePatientDetail? _patient;

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
      final patient = await guardNetworkErrors(() => _api.patientDetail(token!, widget.patientId));
      if (!mounted) return;
      setState(() => _patient = patient);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Patient'),
      body: RefreshIndicator(color: kCare, onRefresh: _load, child: _buildBody()),
    ));
  }

  Widget _buildBody() {
    if (_isLoading && _patient == null) {
      return Center(child: CircularProgressIndicator(color: kCare));
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: kCareSoft,
                backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
                child: p.photoUrl == null
                    ? Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kCareDark))
                    : null,
              ),
              const SizedBox(height: 12),
              Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(8)),
                child: Text('MRN: ${p.mrn}', style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (p.admission != null) ...[
          _SectionCard(title: 'Admission', children: [
            _InfoRow(label: 'Admission No.', value: p.admission!.admissionNo),
            _InfoRow(label: 'Ward', value: p.admission!.wardName),
            _InfoRow(label: 'Bed', value: p.admission!.bedNo),
            _InfoRow(label: 'Doctor', value: p.admission!.doctorName),
            _InfoRow(label: 'Admitted on', value: p.admission!.admissionDate, showDivider: false),
          ]),
          const SizedBox(height: 16),
        ],
        _SectionCard(title: 'Details', children: [
          _InfoRow(label: 'Phone', value: p.phone),
          _InfoRow(label: 'Email', value: p.email),
          _InfoRow(label: 'Gender', value: p.gender),
          _InfoRow(label: 'Date of birth', value: p.dob),
          _InfoRow(label: 'Blood group', value: p.bloodGroup),
          _InfoRow(label: 'Type', value: p.patientType.toUpperCase()),
          _InfoRow(label: 'Status', value: p.status),
          _InfoRow(label: 'Address', value: p.address),
          _InfoRow(label: 'Emergency contact', value: p.emergencyContactName),
          _InfoRow(label: 'Emergency phone', value: p.emergencyContact, showDivider: false),
        ]),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: kCareBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool showDivider;
  const _InfoRow({required this.label, this.value, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12.5, color: kMuted)),
            const Spacer(),
            Flexible(
              child: Text(
                (value == null || value!.isEmpty) ? '—' : value!,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk),
              ),
            ),
          ],
        ),
        if (showDivider) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kCareBorder)),
      ],
    );
  }
}
