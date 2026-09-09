import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/receptionist_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/invoice.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';

class _InvoiceLineDraft {
  BillingServiceItem? service;
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final discountController = TextEditingController();

  double get total {
    final price = service != null ? service!.price : (double.tryParse(priceController.text) ?? 0);
    final qty = int.tryParse(qtyController.text) ?? 0;
    final discount = double.tryParse(discountController.text) ?? 0;
    return (price * qty) - discount;
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    qtyController.dispose();
    discountController.dispose();
  }
}

class InvoiceCreateScreen extends StatefulWidget {
  const InvoiceCreateScreen({super.key});

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  final _api = ReceptionistApiService();
  final _authStorage = AuthStorage();

  final _patientSearchController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController();
  final _taxController = TextEditingController();

  List<ReceptionPatient> _patientResults = [];
  ReceptionPatient? _selectedPatient;
  List<BillingServiceItem> _services = [];
  final List<_InvoiceLineDraft> _lines = [_InvoiceLineDraft()];
  DateTime? _dueDate;

  bool _isLoadingServices = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final token = await _authStorage.readToken();
      _services = await _api.invoiceServices(token!);
    } catch (_) {
      _services = [];
    } finally {
      if (mounted) setState(() => _isLoadingServices = false);
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

  double get _subtotal => _lines.fold(0.0, (sum, l) => sum + l.total);

  Future<void> _submit() async {
    if (_selectedPatient == null) {
      setState(() => _error = 'Pick a patient.');
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final line in _lines) {
      final qty = int.tryParse(line.qtyController.text) ?? 0;
      if (qty <= 0) continue;
      if (line.service != null) {
        items.add({
          'billing_service_id': line.service!.id,
          'quantity': qty,
          if (line.discountController.text.isNotEmpty) 'discount': double.tryParse(line.discountController.text) ?? 0,
        });
      } else if (line.nameController.text.trim().isNotEmpty) {
        items.add({
          'item_name': line.nameController.text.trim(),
          'unit_price': double.tryParse(line.priceController.text) ?? 0,
          'quantity': qty,
          if (line.discountController.text.isNotEmpty) 'discount': double.tryParse(line.discountController.text) ?? 0,
        });
      }
    }
    if (items.isEmpty) {
      setState(() => _error = 'Add at least one item.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final token = await _authStorage.readToken();
      await _api.invoiceStore(token!, {
        'patient_id': _selectedPatient!.id,
        if (_dueDate != null) 'due_date': _dueDate!.toIso8601String().substring(0, 10),
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
        if (_discountController.text.isNotEmpty) 'discount': double.tryParse(_discountController.text) ?? 0,
        if (_taxController.text.isNotEmpty) 'tax': double.tryParse(_taxController.text) ?? 0,
        'items': items,
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
    _notesController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('New Invoice', style: TextStyle(fontWeight: FontWeight.w700))),
      body: _isLoadingServices
          ? const Center(child: CircularProgressIndicator(color: kTeal))
          : ListView(
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
                Row(
                  children: [
                    const Text('Items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(() => _lines.add(_InvoiceLineDraft())),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add line'),
                    ),
                  ],
                ),
                for (int i = 0; i < _lines.length; i++) _LineEditor(line: _lines[i], services: _services, onRemove: _lines.length > 1 ? () => setState(() => _lines.removeAt(i)) : null),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Subtotal: ₹${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kTealDark)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _discountController, decoration: authFieldDecoration('Discount', hint: '0', icon: Icons.percent), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _taxController, decoration: authFieldDecoration('Tax', hint: '0', icon: Icons.add_chart), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (date != null) setState(() => _dueDate = date);
                  },
                  child: InputDecorator(
                    decoration: authFieldDecoration('Due date', hint: 'Optional', icon: Icons.event_outlined),
                    child: Text(_dueDate == null ? 'Not set' : '${_dueDate!.toLocal()}'.substring(0, 10), style: TextStyle(color: _dueDate == null ? kMuted : kInk)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(controller: _notesController, decoration: authFieldDecoration('Notes', hint: 'Optional', icon: Icons.notes_outlined), maxLines: 2),
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
                        : const Text('Create invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LineEditor extends StatefulWidget {
  final _InvoiceLineDraft line;
  final List<BillingServiceItem> services;
  final VoidCallback? onRemove;
  const _LineEditor({required this.line, required this.services, this.onRemove});

  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<BillingServiceItem?>(
                  initialValue: widget.line.service,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Service (or manual below)', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Manual item')),
                    ...widget.services.map((s) => DropdownMenuItem(value: s, child: Text('${s.serviceName} (₹${s.price.toStringAsFixed(0)})'))),
                  ],
                  onChanged: (v) => setState(() => widget.line.service = v),
                ),
              ),
              if (widget.onRemove != null) IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.close, size: 18, color: kMuted)),
            ],
          ),
          if (widget.line.service == null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 2, child: TextField(controller: widget.line.nameController, decoration: const InputDecoration(labelText: 'Item name', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: widget.line.priceController, decoration: const InputDecoration(labelText: 'Price', isDense: true), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: widget.line.qtyController, decoration: const InputDecoration(labelText: 'Qty', isDense: true), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: widget.line.discountController, decoration: const InputDecoration(labelText: 'Discount', isDense: true), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
            ],
          ),
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight, child: Text('₹${widget.line.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kTealDark))),
        ],
      ),
    );
  }
}
