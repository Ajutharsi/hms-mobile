import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/pharmacy/models/drug.dart';
import 'package:hms_mobile/features/pharmacy/viewmodels/drug_master_view_model.dart';

class DrugMasterScreen extends StatelessWidget {
  const DrugMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DrugMasterViewModel(),
      child: const _DrugMasterView(),
    );
  }
}

class _DrugMasterView extends StatefulWidget {
  const _DrugMasterView();

  @override
  State<_DrugMasterView> createState() => _DrugMasterViewState();
}

class _DrugMasterViewState extends State<_DrugMasterView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addOrEdit(BuildContext context, DrugMasterViewModel viewModel, [Drug? existing]) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _DrugDialog(existing: existing));
    if (result == null || !context.mounted) return;

    final error = await viewModel.save(id: existing?.id, fields: result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? (existing == null ? 'Drug added successfully!' : 'Drug updated!'))),
    );
  }

  Future<void> _addStock(BuildContext context, DrugMasterViewModel viewModel, Drug drug) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _AddStockDialog(drug: drug));
    if (result == null || !context.mounted) return;

    final error = await viewModel.addStock(drug.id, quantity: result['quantity'] as int, reason: result['reason'] as String, notes: result['notes'] as String?);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Stock added!')));
  }

  Future<void> _viewHistory(BuildContext context, DrugMasterViewModel viewModel, Drug drug) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _StockHistorySheet(drug: drug, viewModel: viewModel),
    );
  }

  Future<void> _delete(BuildContext context, DrugMasterViewModel viewModel, Drug drug) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this drug?'),
        content: Text('Delete "${drug.drugName}" from the catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Color(0xFFB3261E)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await viewModel.destroy(drug.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Drug deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DrugMasterViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('Drug Master', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(context, viewModel),
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add drug', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchController,
              decoration: authFieldDecoration('Search drugs', hint: 'Name or generic name', icon: Icons.search),
              onSubmitted: viewModel.search,
              onChanged: (v) {
                if (v.isEmpty) viewModel.search('');
              },
            ),
          ),
          Expanded(child: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _buildBody(context, viewModel))),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, DrugMasterViewModel viewModel) {
    if (viewModel.isLoading && viewModel.drugs.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.drugs.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.drugs.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.medication_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No drugs in the catalog yet', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: viewModel.drugs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final drug = viewModel.drugs[index];
        return _DrugCard(
          drug: drug,
          onEdit: () => _addOrEdit(context, viewModel, drug),
          onAddStock: () => _addStock(context, viewModel, drug),
          onHistory: () => _viewHistory(context, viewModel, drug),
          onDelete: () => _delete(context, viewModel, drug),
        );
      },
    );
  }
}

class _DrugCard extends StatelessWidget {
  final Drug drug;
  final VoidCallback onEdit;
  final VoidCallback onAddStock;
  final VoidCallback onHistory;
  final VoidCallback onDelete;
  const _DrugCard({required this.drug, required this.onEdit, required this.onAddStock, required this.onHistory, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final (stockBg, stockFg) = drug.isExpired || drug.isLowStock
        ? (kDangerBg, kDangerFg)
        : drug.isNearExpiry
            ? (kWarningBg, kWarningFg)
            : (kSuccessBg, kSuccessFg);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drug.drugName, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk)),
                    if ((drug.genericName ?? '').isNotEmpty) Text(drug.genericName!, style: const TextStyle(fontSize: 12, color: kMuted)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: kMuted),
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'stock':
                      onAddStock();
                      break;
                    case 'history':
                      onHistory();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'stock', child: Text('Add stock')),
                  PopupMenuItem(value: 'history', child: Text('Stock history')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Chip(bg: kFieldFill, fg: kMuted, label: drug.category),
              _Chip(bg: kFieldFill, fg: kMuted, label: drug.form),
              if ((drug.strength ?? '').isNotEmpty) _Chip(bg: kFieldFill, fg: kMuted, label: drug.strength!),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: stockBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  drug.isExpired ? 'Expired · ${drug.currentStock}' : 'Stock: ${drug.currentStock}',
                  style: TextStyle(color: stockFg, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text('₹${drug.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, color: kTealDark, fontWeight: FontWeight.w600)),
              const Spacer(),
              if ((drug.expiryDate ?? '').isNotEmpty)
                Text('Exp: ${drug.expiryDate}', style: TextStyle(fontSize: 11, color: drug.isNearExpiry || drug.isExpired ? kDangerFg : kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final Color bg;
  final Color fg;
  final String label;
  const _Chip({required this.bg, required this.fg, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w600)),
    );
  }
}

class _DrugDialog extends StatefulWidget {
  final Drug? existing;
  const _DrugDialog({this.existing});

  @override
  State<_DrugDialog> createState() => _DrugDialogState();
}

class _DrugDialogState extends State<_DrugDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.drugName);
  late final _genericController = TextEditingController(text: widget.existing?.genericName);
  late final _categoryController = TextEditingController(text: widget.existing?.category);
  late final _formController = TextEditingController(text: widget.existing?.form);
  late final _strengthController = TextEditingController(text: widget.existing?.strength);
  late final _manufacturerController = TextEditingController(text: widget.existing?.manufacturer);
  late final _priceController = TextEditingController(text: widget.existing?.unitPrice.toString());
  late final _stockController = TextEditingController();
  late final _minStockController = TextEditingController(text: widget.existing?.minStockLevel?.toString());
  DateTime? _expiryDate;
  late String _status = widget.existing?.status ?? 'active';

  @override
  void initState() {
    super.initState();
    final expiry = widget.existing?.expiryDate;
    if (expiry != null && expiry.isNotEmpty) {
      _expiryDate = DateTime.tryParse(expiry);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericController.dispose();
    _categoryController.dispose();
    _formController.dispose();
    _strengthController.dispose();
    _manufacturerController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit drug' : 'Add drug'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Drug name'), validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null),
                const SizedBox(height: 10),
                TextFormField(controller: _genericController, decoration: const InputDecoration(labelText: 'Generic name (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                const SizedBox(height: 10),
                TextFormField(controller: _formController, decoration: const InputDecoration(labelText: 'Form (e.g. tablet, syrup)'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                const SizedBox(height: 10),
                TextFormField(controller: _strengthController, decoration: const InputDecoration(labelText: 'Strength (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _manufacturerController, decoration: const InputDecoration(labelText: 'Manufacturer (optional)')),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Unit price'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (double.tryParse(v ?? '') == null) ? 'Enter a valid price' : null,
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 10),
                  TextFormField(controller: _stockController, decoration: const InputDecoration(labelText: 'Initial stock (optional)'), keyboardType: TextInputType.number),
                ],
                const SizedBox(height: 10),
                TextFormField(controller: _minStockController, decoration: const InputDecoration(labelText: 'Min stock level (optional)'), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _pickExpiry,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Expiry date (optional)'),
                    child: Text(_expiryDate == null ? 'Not set' : '${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}'),
                  ),
                ),
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
            final fields = <String, dynamic>{
              'drug_name': _nameController.text.trim(),
              'generic_name': _genericController.text.trim().isEmpty ? null : _genericController.text.trim(),
              'category': _categoryController.text.trim(),
              'form': _formController.text.trim(),
              'strength': _strengthController.text.trim().isEmpty ? null : _strengthController.text.trim(),
              'manufacturer': _manufacturerController.text.trim().isEmpty ? null : _manufacturerController.text.trim(),
              'unit_price': double.parse(_priceController.text),
              'min_stock_level': _minStockController.text.trim().isEmpty ? null : int.tryParse(_minStockController.text.trim()),
              'expiry_date': _expiryDate == null ? null : '${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}',
              'status': _status,
            };
            if (!isEdit && _stockController.text.trim().isNotEmpty) {
              fields['current_stock'] = int.tryParse(_stockController.text.trim());
            }
            Navigator.of(context).pop(fields);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AddStockDialog extends StatefulWidget {
  final Drug drug;
  const _AddStockDialog({required this.drug});

  @override
  State<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<_AddStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController(text: 'Restock');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add stock — ${widget.drug.drugName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current stock: ${widget.drug.currentStock}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              validator: (v) => (int.tryParse(v ?? '') == null || int.parse(v!) < 1) ? 'Enter a valid quantity' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _reasonController, decoration: const InputDecoration(labelText: 'Reason'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 10),
            TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop({
              'quantity': int.parse(_quantityController.text),
              'reason': _reasonController.text.trim(),
              'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _StockHistorySheet extends StatelessWidget {
  final Drug drug;
  final DrugMasterViewModel viewModel;
  const _StockHistorySheet({required this.drug, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock history — ${drug.drugName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: FutureBuilder<List<DrugStockEntry>>(
                future: viewModel.stockHistory(drug.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator(color: kTeal));
                  }
                  final history = snapshot.data ?? [];
                  if (history.isEmpty) {
                    return const Center(child: Text('No stock history yet.', style: TextStyle(color: kMuted)));
                  }
                  return ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: kFieldFill),
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      final isIn = entry.type == 'in';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Icon(isIn ? Icons.add_circle_outline : Icons.remove_circle_outline, color: isIn ? kSuccessFg : kDangerFg, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${isIn ? '+' : '-'}${entry.quantity} · Balance: ${entry.balance}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
                                  if ((entry.reason ?? '').isNotEmpty) Text(entry.reason!, style: const TextStyle(fontSize: 12, color: kMuted)),
                                  if (entry.performedByName != null) Text('by ${entry.performedByName}', style: const TextStyle(fontSize: 11, color: kMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
