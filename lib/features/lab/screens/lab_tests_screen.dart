import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/lab/models/lab_test.dart';
import 'package:hms_mobile/features/lab/viewmodels/lab_tests_view_model.dart';

const _kCategories = ['Biochemistry', 'Haematology', 'Microbiology', 'Serology', 'Immunology', 'Pathology', 'Radiology', 'Other'];

class LabTestsScreen extends StatelessWidget {
  const LabTestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LabTestsViewModel(),
      child: const _LabTestsView(),
    );
  }
}

class _LabTestsView extends StatelessWidget {
  const _LabTestsView();

  Future<void> _addOrEdit(BuildContext context, LabTestsViewModel viewModel, [LabTest? existing]) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _LabTestDialog(existing: existing));
    if (result == null || !context.mounted) return;

    final error = await viewModel.save(
      id: existing?.id,
      testName: result['test_name'] as String,
      category: result['category'] as String,
      sampleType: result['sample_type'] as String,
      price: result['price'] as double,
      unit: result['unit'] as String?,
      normalRangeMale: result['normal_range_male'] as String?,
      normalRangeFemale: result['normal_range_female'] as String?,
      description: result['description'] as String?,
      status: result['status'] as String,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? (existing == null ? 'Lab test added!' : 'Lab test updated!'))),
    );
  }

  Future<void> _delete(BuildContext context, LabTestsViewModel viewModel, LabTest test) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this test?'),
        content: Text('Delete "${test.testName}" from the catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Color(0xFFB3261E)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await viewModel.destroy(test.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Test deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LabTestsViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('Lab Tests', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(context, viewModel),
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add test', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    );
  }

  Widget _buildBody(BuildContext context, LabTestsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.tests.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.tests.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.tests.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.science_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No lab tests in the catalog yet', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: viewModel.tests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final test = viewModel.tests[index];
        return _TestCard(
          test: test,
          onEdit: () => _addOrEdit(context, viewModel, test),
          onDelete: () => _delete(context, viewModel, test),
        );
      },
    );
  }
}

class _TestCard extends StatelessWidget {
  final LabTest test;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TestCard({required this.test, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final active = test.status == 'active';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(test.testName, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: active ? kSuccessBg : kFieldFill, borderRadius: BorderRadius.circular(7)),
                      child: Text(test.status, style: TextStyle(color: active ? kSuccessFg : kMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${test.category} · ${test.sampleType}', style: const TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(height: 4),
                Text('₹${test.price.toStringAsFixed(0)}${test.unit != null ? ' · ${test.unit}' : ''}', style: const TextStyle(fontSize: 12.5, color: kTealDark, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 19, color: kMuted), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(height: 8),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 19, color: kMuted), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabTestDialog extends StatefulWidget {
  final LabTest? existing;
  const _LabTestDialog({this.existing});

  @override
  State<_LabTestDialog> createState() => _LabTestDialogState();
}

class _LabTestDialogState extends State<_LabTestDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.testName);
  late final _sampleController = TextEditingController(text: widget.existing?.sampleType);
  late final _priceController = TextEditingController(text: widget.existing?.price.toString());
  late final _unitController = TextEditingController(text: widget.existing?.unit);
  late final _rangeMaleController = TextEditingController(text: widget.existing?.normalRangeMale);
  late final _rangeFemaleController = TextEditingController(text: widget.existing?.normalRangeFemale);
  late final _descController = TextEditingController(text: widget.existing?.description);
  late String _category = widget.existing?.category ?? _kCategories.first;
  late String _status = widget.existing?.status ?? 'active';

  @override
  void dispose() {
    _nameController.dispose();
    _sampleController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _rangeMaleController.dispose();
    _rangeFemaleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add lab test' : 'Edit lab test'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Test name'), validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _kCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 10),
                TextFormField(controller: _sampleController, decoration: const InputDecoration(labelText: 'Sample type'), validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (double.tryParse(v ?? '') == null) ? 'Enter a valid price' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(controller: _unitController, decoration: const InputDecoration(labelText: 'Unit (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _rangeMaleController, decoration: const InputDecoration(labelText: 'Normal range — male (optional)', hintText: 'e.g. 70-110')),
                const SizedBox(height: 10),
                TextFormField(controller: _rangeFemaleController, decoration: const InputDecoration(labelText: 'Normal range — female (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Description (optional)'), maxLines: 2),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [DropdownMenuItem(value: 'active', child: Text('Active')), DropdownMenuItem(value: 'inactive', child: Text('Inactive'))],
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop({
              'test_name': _nameController.text.trim(),
              'category': _category,
              'sample_type': _sampleController.text.trim(),
              'price': double.parse(_priceController.text),
              'unit': _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
              'normal_range_male': _rangeMaleController.text.trim().isEmpty ? null : _rangeMaleController.text.trim(),
              'normal_range_female': _rangeFemaleController.text.trim().isEmpty ? null : _rangeFemaleController.text.trim(),
              'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
              'status': _status,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
