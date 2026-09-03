import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/reception_appointment.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';

const _kTypes = ['op', 'emergency', 'consult', 'followup'];
const _kStatuses = ['scheduled', 'completed', 'cancelled', 'no_show'];

/// Create/edit appointment form. Pass [existing] to edit; omit to create.
class AppointmentFormScreen extends StatefulWidget {
  final ReceptionAppointment? existing;
  const AppointmentFormScreen({super.key, this.existing});

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _api = ReceptionistApiService();
  final _authStorage = AuthStorage();
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoadingDoctors = true;
  bool _isSearchingPatients = false;
  bool _isLoadingSlots = false;
  bool _isSaving = false;
  String? _error;

  List<ReceptionDoctor> _doctors = [];
  List<ReceptionPatient> _patientResults = [];
  List<AppointmentSlot> _slots = [];

  ReceptionPatient? _selectedPatient;
  ReceptionDoctor? _selectedDoctor;
  DateTime _date = DateTime.now();
  String? _selectedTime;
  TimeOfDay? _manualTime;
  String _type = 'consult';
  String _status = 'scheduled';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.type;
      _status = e.status;
      _notesController.text = e.notes ?? '';
      final parsedDate = DateTime.tryParse(e.date);
      if (parsedDate != null) _date = parsedDate;
      final parts = e.time.split(':');
      if (parts.length >= 2) {
        _manualTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
      }
    }
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    try {
      final token = await _authStorage.readToken();
      _doctors = await guardNetworkErrors(() => _api.doctors(token!));
      if (_isEdit) {
        for (final d in _doctors) {
          if (d.id == widget.existing!.doctorId) _selectedDoctor = d;
        }
      }
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
    setState(() => _isSearchingPatients = true);
    try {
      final token = await _authStorage.readToken();
      _patientResults = await guardNetworkErrors(() => _api.patients(token!, q: query));
    } catch (_) {
      _patientResults = [];
    } finally {
      if (mounted) setState(() => _isSearchingPatients = false);
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedDoctor == null || _isEdit) return;
    setState(() {
      _isLoadingSlots = true;
      _slots = [];
      _selectedTime = null;
    });
    try {
      final token = await _authStorage.readToken();
      _slots = await guardNetworkErrors(() => _api.appointmentSlots(token!, doctorId: _selectedDoctor!.id, date: _fmtDate(_date)));
    } catch (_) {
      _slots = [];
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _isEdit ? DateTime.now().subtract(const Duration(days: 365)) : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _loadSlots();
    }
  }

  Future<void> _pickManualTime() async {
    final picked = await showTimePicker(context: context, initialTime: _manualTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _manualTime = picked);
  }

  String? get _timeString {
    if (_isEdit) {
      return _manualTime == null ? null : '${_manualTime!.hour.toString().padLeft(2, '0')}:${_manualTime!.minute.toString().padLeft(2, '0')}';
    }
    return _selectedTime;
  }

  bool get _canSubmit => (_isEdit ? widget.existing!.patientId > 0 : _selectedPatient != null) && _selectedDoctor != null && _timeString != null;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final fields = <String, dynamic>{
      'patient_id': _isEdit ? widget.existing!.patientId : _selectedPatient!.id,
      'doctor_id': _selectedDoctor!.id,
      'appointment_date': _fmtDate(_date),
      'appointment_time': _timeString,
      'type': _type,
      'status': _isEdit ? _status : 'scheduled',
      if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
    };

    try {
      final token = await _authStorage.readToken();
      if (_isEdit) {
        await guardNetworkErrors(() => _api.appointmentUpdate(token!, widget.existing!.id, fields));
      } else {
        await guardNetworkErrors(() => _api.appointmentStore(token!, fields));
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
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: kInk, elevation: 0, title: Text(_isEdit ? 'Edit Appointment' : 'Book Appointment', style: const TextStyle(fontWeight: FontWeight.w700))),
      body: _isLoadingDoctors
          ? const Center(child: CircularProgressIndicator(color: kTeal))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                const Text('Patient', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
                const SizedBox(height: 8),
                if (_isEdit)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(12)),
                    child: Text('${widget.existing!.patientName ?? ''} · ${widget.existing!.patientMrn ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  )
                else if (_selectedPatient != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kMint, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(child: Text('${_selectedPatient!.name} · ${_selectedPatient!.mrn}', style: const TextStyle(fontWeight: FontWeight.w600, color: kTealDark, fontSize: 13.5))),
                        InkWell(onTap: () => setState(() => _selectedPatient = null), child: const Icon(Icons.close, size: 18, color: kTealDark)),
                      ],
                    ),
                  )
                else ...[
                  TextField(controller: _searchController, decoration: authFieldDecoration('Search patient', hint: 'Name or MRN', icon: Icons.search), onChanged: _searchPatients),
                  if (_isSearchingPatients) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(color: kTeal)),
                  if (_patientResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(12)),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _patientResults.length,
                        itemBuilder: (context, i) {
                          final p = _patientResults[i];
                          return ListTile(
                            dense: true,
                            title: Text(p.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            subtitle: Text(p.mrn, style: const TextStyle(fontSize: 12)),
                            onTap: () => setState(() {
                              _selectedPatient = p;
                              _patientResults = [];
                            }),
                          );
                        },
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                const Text('Doctor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
                const SizedBox(height: 8),
                DropdownButtonFormField<ReceptionDoctor>(
                  initialValue: _selectedDoctor,
                  decoration: authFieldDecoration('Doctor', hint: 'Select doctor', icon: Icons.medical_services_outlined),
                  items: _doctors.map((d) => DropdownMenuItem(value: d, child: Text(d.specialization != null ? '${d.name} (${d.specialization})' : d.name))).toList(),
                  onChanged: (v) {
                    setState(() => _selectedDoctor = v);
                    _loadSlots();
                  },
                ),
                const SizedBox(height: 16),
                const Text('Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(decoration: authFieldDecoration('Date', hint: '', icon: Icons.calendar_today_outlined), child: Text(_fmtDate(_date))),
                ),
                const SizedBox(height: 16),
                const Text('Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
                const SizedBox(height: 8),
                if (_isEdit)
                  InkWell(
                    onTap: _pickManualTime,
                    child: InputDecorator(
                      decoration: authFieldDecoration('Time', hint: '', icon: Icons.access_time_rounded),
                      child: Text(_manualTime != null ? '${_manualTime!.hour.toString().padLeft(2, '0')}:${_manualTime!.minute.toString().padLeft(2, '0')}' : 'Select time'),
                    ),
                  )
                else if (_isLoadingSlots)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator(color: kTeal))
                else if (_selectedDoctor == null)
                  const Text('Pick a doctor to see available slots.', style: TextStyle(color: kMuted, fontSize: 12.5))
                else if (_slots.isEmpty)
                  const Text('No slots available for this date.', style: TextStyle(color: kMuted, fontSize: 12.5))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _slots)
                        ChoiceChip(
                          label: Text(s.time),
                          selected: _selectedTime == s.time,
                          onSelected: s.available ? (_) => setState(() => _selectedTime = s.time) : null,
                          selectedColor: kMint,
                          disabledColor: kFieldFill,
                          labelStyle: TextStyle(color: s.available ? kInk : kMuted, decoration: s.available ? null : TextDecoration.lineThrough),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: authFieldDecoration('Type', hint: '', icon: Icons.category_outlined),
                  items: _kTypes.map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 16),
                  const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: authFieldDecoration('Status', hint: '', icon: Icons.info_outline),
                    items: _kStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ')))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(controller: _notesController, maxLines: 3, decoration: authFieldDecoration('Notes (optional)', hint: '', icon: Icons.notes_outlined)),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  authErrorBanner(_error!),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_canSubmit && !_isSaving) ? _submit : null,
                    style: ElevatedButton.styleFrom(backgroundColor: kTealDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Save changes' : 'Book appointment', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    );
  }
}
