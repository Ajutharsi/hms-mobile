import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/nurse/models/nurse_patient.dart';

/// A tappable form field that opens a searchable bottom sheet of patients
/// (backed by `NurseApiService.patients(token, q:)`) and reports back the
/// chosen [NursePatient]. Used by every "new record for a patient" form
/// across the nurse app (eMAR, vitals, notes, admissions, ...).
class PatientPickerField extends StatelessWidget {
  final String label;
  final NursePatient? value;
  final ValueChanged<NursePatient> onChanged;
  final String? errorText;

  const PatientPickerField({
    super.key,
    this.label = 'Patient',
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<NursePatient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _PatientPickerSheet(),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: kFieldFill,
              borderRadius: BorderRadius.circular(12),
              border: errorText != null ? Border.all(color: const Color(0xFFB3261E), width: 1.2) : null,
            ),
            child: Row(
              children: [
                const Icon(Icons.person_search_outlined, size: 18, color: kMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value == null ? 'Search a patient' : '${value!.name} (${value!.mrn})',
                    style: TextStyle(color: value == null ? const Color(0xFFAEB8B6) : kInk, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(errorText!, style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12)),
        ],
      ],
    );
  }
}

class _PatientPickerSheet extends StatefulWidget {
  const _PatientPickerSheet();

  @override
  State<_PatientPickerSheet> createState() => _PatientPickerSheetState();
}

class _PatientPickerSheetState extends State<_PatientPickerSheet> {
  final _api = NurseApiService();
  final _authStorage = AuthStorage();
  final _controller = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<NursePatient> _results = [];

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _authStorage.readToken();
      final results = await _api.patients(token!, q: query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load patients.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
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
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kTeal))
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: kMuted)))
                      : _results.isEmpty
                          ? const Center(child: Text('No patients found.', style: TextStyle(color: kMuted)))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                              itemCount: _results.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: kFieldFill),
                              itemBuilder: (context, index) {
                                final p = _results[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: kMint,
                                    backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
                                    child: p.photoUrl == null
                                        ? Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?', style: const TextStyle(color: kTealDark, fontWeight: FontWeight.w700))
                                        : null,
                                  ),
                                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: Text(
                                    [p.mrn, if (p.wardName != null) '${p.wardName} · ${p.bedNo ?? ''}'].join('  ·  '),
                                    style: const TextStyle(fontSize: 12, color: kMuted),
                                  ),
                                  onTap: () => Navigator.of(context).pop(p),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
