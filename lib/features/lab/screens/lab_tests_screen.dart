import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/hospital_settings.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/lab/models/lab_test.dart';
import 'package:hms_mobile/features/lab/viewmodels/lab_tests_view_model.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

const _kCategories = ['Biochemistry', 'Haematology', 'Microbiology', 'Serology', 'Immunology', 'Pathology', 'Radiology', 'Other'];

class LabTestsScreen extends StatelessWidget {
  const LabTestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
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
      SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? (existing == null ? 'Lab test added!' : 'Lab test updated!'))),
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: CareText.danger)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await viewModel.destroy(test.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kCareDark : null, content: Text(error ?? 'Test deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<LabTestsViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Lab Tests'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add test', style: CareText.onCare),
      ),
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    ));
  }

  Widget _buildBody(BuildContext context, LabTestsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.tests.isEmpty) {
      return const CareStateView.loading();
    }
    if (viewModel.loadError != null && viewModel.tests.isEmpty) {
      return CareStateView.error(viewModel.loadError!);
    }
    if (viewModel.tests.isEmpty) {
      return const CareStateView(
        icon: Icons.biotech_outlined,
        title: 'No tests in the catalogue',
        message: 'Add the tests this lab offers and their prices.',
      );
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
    watchCarePalette(context);
    final active = test.status == 'active';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(CareRadius.card), border: Border.all(color: kCareBorder)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(test.testName, style: CareText.titleLg)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: active ? kSuccessBg : kCareBg, borderRadius: BorderRadius.circular(CareRadius.chip)),
                      child: Text(test.status, style: TextStyle(color: active ? kSuccessFg : kMuted, fontSize: CareText.xxs, fontWeight: CareText.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${test.category} · ${test.sampleType}', style: CareText.mutedXs),
                const SizedBox(height: 4),
                Text('${money(test.price)}${test.unit != null ? ' · ${test.unit}' : ''}', style: TextStyle(fontSize: CareText.sm, color: kCareDark, fontWeight: CareText.medium)),
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
    watchCarePalette(context);
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
                  isExpanded: true,
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _kCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
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
                  isExpanded: true,
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [DropdownMenuItem(value: 'active', child: Text('Active', overflow: TextOverflow.ellipsis)), DropdownMenuItem(value: 'inactive', child: Text('Inactive', overflow: TextOverflow.ellipsis))],
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
