import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';

const _kMaritalStatuses = ['single', 'married', 'divorced', 'widowed'];

/// Create/edit patient form. Pass [existing] to edit; omit to create.
class PatientFormScreen extends StatefulWidget {
  final ReceptionPatientDetail? existing;
  const PatientFormScreen({super.key, this.existing});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ReceptionistApiService();
  final _authStorage = AuthStorage();

  late final _nameController = TextEditingController(text: widget.existing?.name);
  late final _emailController = TextEditingController(text: widget.existing?.email);
  late final _phoneController = TextEditingController(text: widget.existing?.phone);
  late final _bloodGroupController = TextEditingController(text: widget.existing?.bloodGroup);
  late final _addressController = TextEditingController(text: widget.existing?.address);
  late final _emergencyContactController = TextEditingController(text: widget.existing?.emergencyContact);
  late final _emergencyContactNameController = TextEditingController(text: widget.existing?.emergencyContactName);
  late final _nationalityController = TextEditingController(text: widget.existing?.nationality);
  late final _occupationController = TextEditingController(text: widget.existing?.occupation);

  DateTime? _dob;
  String? _gender;
  String _patientType = 'op';
  String _status = 'active';
  String? _maritalStatus;
  Uint8List? _photoBytes;
  String? _photoName;

  bool _isSaving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _gender = e.gender;
      _patientType = e.patientType;
      _status = e.status;
      _maritalStatus = e.maritalStatus;
      if (e.dob != null && e.dob!.isNotEmpty) {
        _dob = DateTime.tryParse(e.dob!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bloodGroupController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _emergencyContactNameController.dispose();
    _nationalityController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    _photoBytes = await picked.readAsBytes();
    _photoName = picked.name;
    setState(() {});
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isEdit && (_gender == null || _gender!.isEmpty)) {
      setState(() => _error = 'Select a gender.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final fields = <String, String>{
      'name': _nameController.text.trim(),
      'patient_type': _patientType,
      if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim(),
      if (_phoneController.text.trim().isNotEmpty) 'phone': _phoneController.text.trim(),
      if (_dob != null) 'dob': _fmtDate(_dob!),
      if (_gender != null) 'gender': _gender!,
      if (_bloodGroupController.text.trim().isNotEmpty) 'blood_group': _bloodGroupController.text.trim(),
      if (_addressController.text.trim().isNotEmpty) 'address': _addressController.text.trim(),
      if (_emergencyContactController.text.trim().isNotEmpty) 'emergency_contact': _emergencyContactController.text.trim(),
      if (_emergencyContactNameController.text.trim().isNotEmpty) 'emergency_contact_name': _emergencyContactNameController.text.trim(),
      if (_nationalityController.text.trim().isNotEmpty) 'nationality': _nationalityController.text.trim(),
      if (_maritalStatus != null) 'marital_status': _maritalStatus!,
      if (_occupationController.text.trim().isNotEmpty) 'occupation': _occupationController.text.trim(),
      'status': _status,
    };

    try {
      final token = await _authStorage.readToken();
      if (_isEdit) {
        await guardNetworkErrors(() => _api.patientUpdate(token!, widget.existing!.id, fields, photoBytes: _photoBytes, photoFilename: _photoName));
      } else {
        await guardNetworkErrors(() => _api.patientStore(token!, fields, photoBytes: _photoBytes, photoFilename: _photoName));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: Text(_isEdit ? 'Edit Patient' : 'Add Patient', style: const TextStyle(fontWeight: FontWeight.w700))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: kMint,
                    backgroundImage: _photoBytes != null
                        ? MemoryImage(_photoBytes!)
                        : (widget.existing?.photoUrl != null ? NetworkImage(widget.existing!.photoUrl!) : null) as ImageProvider?,
                    child: (_photoBytes == null && widget.existing?.photoUrl == null) ? const Icon(Icons.person, color: kTealDark, size: 32) : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: _pickPhoto,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: kTealDark, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: authFieldDecoration('Full name', hint: 'Patient name', icon: Icons.person_outline),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: authFieldDecoration('Email (optional)', hint: 'you@example.com', icon: Icons.email_outlined)),
            const SizedBox(height: 12),
            TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: authFieldDecoration('Phone (optional)', hint: 'Phone number', icon: Icons.phone_outlined)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDob,
              child: InputDecorator(
                decoration: authFieldDecoration('Date of birth (optional)', hint: '', icon: Icons.calendar_today_outlined),
                child: Text(_dob != null ? _fmtDate(_dob!) : '—'),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: authFieldDecoration(_isEdit ? 'Gender' : 'Gender (optional)', hint: 'Select gender', icon: Icons.wc_outlined),
              items: const [DropdownMenuItem(value: 'male', child: Text('Male')), DropdownMenuItem(value: 'female', child: Text('Female')), DropdownMenuItem(value: 'other', child: Text('Other'))],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _bloodGroupController, decoration: authFieldDecoration('Blood group (optional)', hint: 'e.g. O+', icon: Icons.bloodtype_outlined)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _patientType,
              decoration: authFieldDecoration('Patient type', hint: '', icon: Icons.badge_outlined),
              items: const [DropdownMenuItem(value: 'op', child: Text('Outpatient (OP)')), DropdownMenuItem(value: 'ip', child: Text('Inpatient (IP)'))],
              onChanged: (v) => setState(() => _patientType = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: authFieldDecoration('Status', hint: '', icon: Icons.info_outline),
              items: const [DropdownMenuItem(value: 'active', child: Text('Active')), DropdownMenuItem(value: 'discharged', child: Text('Discharged')), DropdownMenuItem(value: 'deceased', child: Text('Deceased'))],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _addressController, maxLines: 2, decoration: authFieldDecoration('Address (optional)', hint: 'Home address', icon: Icons.home_outlined)),
            const SizedBox(height: 12),
            TextFormField(controller: _emergencyContactNameController, decoration: authFieldDecoration('Emergency contact name (optional)', hint: '', icon: Icons.contact_emergency_outlined)),
            const SizedBox(height: 12),
            TextFormField(controller: _emergencyContactController, keyboardType: TextInputType.phone, decoration: authFieldDecoration('Emergency contact phone (optional)', hint: '', icon: Icons.phone_in_talk_outlined)),
            const SizedBox(height: 12),
            TextFormField(controller: _nationalityController, decoration: authFieldDecoration('Nationality (optional)', hint: '', icon: Icons.flag_outlined)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _maritalStatus,
              decoration: authFieldDecoration('Marital status (optional)', hint: 'Select', icon: Icons.favorite_border),
              items: _kMaritalStatuses.map((m) => DropdownMenuItem(value: m, child: Text(m[0].toUpperCase() + m.substring(1)))).toList(),
              onChanged: (v) => setState(() => _maritalStatus = v),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _occupationController, decoration: authFieldDecoration('Occupation (optional)', hint: '', icon: Icons.work_outline)),
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
                    : Text(_isEdit ? 'Save changes' : 'Add patient', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
