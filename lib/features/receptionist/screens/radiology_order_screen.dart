import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/reception_appointment.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';

const _kModalities = ['X-Ray', 'CT', 'MRI', 'Ultrasound', 'Mammography', 'Fluoroscopy', 'Other'];
const _kPriorities = ['routine', 'urgent', 'emergency'];

class RadiologyOrderScreen extends StatefulWidget {
  const RadiologyOrderScreen({super.key});

  @override
  State<RadiologyOrderScreen> createState() => _RadiologyOrderScreenState();
}

class _RadiologyOrderScreenState extends State<RadiologyOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ReceptionistApiService();
  final _authStorage = AuthStorage();

  final _patientSearchController = TextEditingController();
  final _bodyPartController = TextEditingController();
  final _studyController = TextEditingController();
  final _indicationController = TextEditingController();

  List<ReceptionPatient> _patientResults = [];
  ReceptionPatient? _selectedPatient;
  List<ReceptionDoctor> _doctors = [];
  ReceptionDoctor? _selectedDoctor;
  String _modality = _kModalities.first;
  String _priority = 'routine';
  DateTime? _scheduledAt;

  bool _isLoadingDoctors = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final token = await _authStorage.readToken();
      _doctors = await _api.doctors(token!);
    } catch (_) {
      _doctors = [];
    } finally {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  Future<void> _searchPatients(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _patientResults = []);
      return;
    }
    try {
      final token = await _authStorage.readToken();
      final results = await _api.patients(token!, q: query);
      if (mounted) setState(() => _patientResults = results);
    } catch (_) {}
  }

  Future<void> _pickScheduledAt() async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatient == null) {
      setState(() => _error = 'Pick a patient.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final token = await _authStorage.readToken();
      await _api.radiologyStore(token!, {
        'patient_id': _selectedPatient!.id,
        if (_selectedDoctor != null) 'doctor_id': _selectedDoctor!.id,
        'modality': _modality,
        'body_part': _bodyPartController.text.trim(),
        'study_description': _studyController.text.trim(),
        if (_indicationController.text.trim().isNotEmpty) 'clinical_indication': _indicationController.text.trim(),
        'priority': _priority,
        if (_scheduledAt != null) 'scheduled_at': _scheduledAt!.toIso8601String(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _patientSearchController.dispose();
    _bodyPartController.dispose();
    _studyController.dispose();
    _indicationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: kInk, elevation: 0, title: const Text('New Radiology Order', style: TextStyle(fontWeight: FontWeight.w700))),
      body: _isLoadingDoctors
          ? const Center(child: CircularProgressIndicator(color: kTeal))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  const Text('Patient', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
                  const SizedBox(height: 8),
                  if (_selectedPatient != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: kMint, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedPatient!.name, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                                Text(_selectedPatient!.mrn, style: const TextStyle(fontSize: 12, color: kMuted)),
                              ],
                            ),
                          ),
                          IconButton(onPressed: () => setState(() => _selectedPatient = null), icon: const Icon(Icons.close, size: 18)),
                        ],
                      ),
                    )
                  else ...[
                    TextField(
                      controller: _patientSearchController,
                      decoration: authFieldDecoration('Search patient', hint: 'Name or MRN', icon: Icons.search),
                      onChanged: _searchPatients,
                    ),
                    if (_patientResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(12)),
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _patientResults.length,
                          itemBuilder: (context, index) {
                            final p = _patientResults[index];
                            return ListTile(
                              dense: true,
                              title: Text(p.name),
                              subtitle: Text(p.mrn),
                              onTap: () => setState(() {
                                _selectedPatient = p;
                                _patientResults = [];
                                _patientSearchController.clear();
                              }),
                            );
                          },
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  const Text('Referring doctor (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ReceptionDoctor>(
                    initialValue: _selectedDoctor,
                    decoration: authFieldDecoration('Doctor', hint: 'Optional', icon: Icons.medical_services_outlined),
                    items: _doctors.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
                    onChanged: (v) => setState(() => _selectedDoctor = v),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _modality,
                    decoration: authFieldDecoration('Modality', hint: 'Select modality', icon: Icons.camera_outlined),
                    items: _kModalities.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _modality = v!),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bodyPartController,
                    decoration: authFieldDecoration('Body part', hint: 'e.g. Chest', icon: Icons.accessibility_new_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _studyController,
                    decoration: authFieldDecoration('Study description', hint: 'e.g. Chest X-Ray PA view', icon: Icons.description_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _indicationController,
                    decoration: authFieldDecoration('Clinical indication', hint: 'Optional', icon: Icons.notes_outlined),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: authFieldDecoration('Priority', hint: 'Select priority', icon: Icons.flag_outlined),
                    items: _kPriorities.map((p) => DropdownMenuItem(value: p, child: Text(p[0].toUpperCase() + p.substring(1)))).toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickScheduledAt,
                    child: InputDecorator(
                      decoration: authFieldDecoration('Scheduled at', hint: 'Optional', icon: Icons.event_outlined),
                      child: Text(
                        _scheduledAt == null ? 'Not scheduled' : '${_scheduledAt!.toLocal()}'.substring(0, 16),
                        style: TextStyle(color: _scheduledAt == null ? kMuted : kInk),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    authErrorBanner(_error!),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: kTealDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
