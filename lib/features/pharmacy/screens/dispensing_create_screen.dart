import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/pharmacy/models/drug.dart';
import 'package:hms_mobile/features/pharmacy/viewmodels/dispensing_create_view_model.dart';

class DispensingCreateScreen extends StatelessWidget {
  const DispensingCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DispensingCreateViewModel(),
      child: const _DispensingCreateView(),
    );
  }
}

class _DispensingCreateView extends StatefulWidget {
  const _DispensingCreateView();

  @override
  State<_DispensingCreateView> createState() => _DispensingCreateViewState();
}

class _DispensingCreateViewState extends State<_DispensingCreateView> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(DispensingCreateViewModel viewModel) async {
    final (id, error) = await viewModel.submit(notes: _notesController.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(id);
  }

  Future<void> _pickDrug(BuildContext context, DispensingCreateViewModel viewModel) async {
    final remaining = viewModel.availableDrugs.where((d) => !viewModel.lines.any((l) => l.drug.id == d.id)).toList();
    final picked = await showModalBottomSheet<Drug>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(16), child: Text('Select a drug', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk))),
              Expanded(
                child: remaining.isEmpty
                    ? const Center(child: Text('No more drugs available', style: TextStyle(color: kMuted)))
                    : ListView.builder(
                        itemCount: remaining.length,
                        itemBuilder: (context, index) {
                          final d = remaining[index];
                          return ListTile(
                            title: Text(d.drugName),
                            subtitle: Text('${d.category} · Stock: ${d.currentStock} · ₹${d.unitPrice.toStringAsFixed(2)}'),
                            onTap: () => Navigator.of(context).pop(d),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) viewModel.addLine(picked);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DispensingCreateViewModel>();

    final total = viewModel.lines.fold<double>(0, (sum, l) => sum + (l.drug.unitPrice * l.quantity));

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('New Dispensing', style: TextStyle(fontWeight: FontWeight.w700))),
      body: viewModel.isLoadingDrugs
          ? const Center(child: CircularProgressIndicator(color: kTeal))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const Text('Patient', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
                const SizedBox(height: 8),
                if (viewModel.selectedPatient != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kMint, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(viewModel.selectedPatient!.name, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                              Text(viewModel.selectedPatient!.mrn, style: const TextStyle(fontSize: 12, color: kMuted)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: viewModel.clearPatient, icon: const Icon(Icons.close, size: 18)),
                      ],
                    ),
                  )
                else ...[
                  TextField(
                    controller: _searchController,
                    decoration: authFieldDecoration('Search patient', hint: 'Name or MRN', icon: Icons.search),
                    onChanged: viewModel.searchPatients,
                  ),
                  if (viewModel.patientResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(12)),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: viewModel.patientResults.length,
                        itemBuilder: (context, index) {
                          final p = viewModel.patientResults[index];
                          return ListTile(
                            dense: true,
                            title: Text(p.name),
                            subtitle: Text(p.mrn),
                            onTap: () {
                              viewModel.selectPatient(p);
                              _searchController.clear();
                            },
                          );
                        },
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Drugs', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _pickDrug(context, viewModel),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add drug'),
                    ),
                  ],
                ),
                if (viewModel.lines.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No drugs added yet.', style: TextStyle(color: kMuted, fontSize: 13)))
                else
                  for (final line in viewModel.lines) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kFieldFill)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(line.drug.drugName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: kInk)),
                                Text('Available: ${line.drug.currentStock} · ₹${line.drug.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11.5, color: kMuted)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20, color: kMuted),
                            onPressed: () => viewModel.setQuantity(line.drug.id, line.quantity - 1),
                          ),
                          Text('${line.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20, color: kMuted),
                            onPressed: () => viewModel.setQuantity(line.drug.id, line.quantity + 1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: kMuted),
                            onPressed: () => viewModel.removeLine(line.drug.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                if (viewModel.lines.isNotEmpty) ...[
                  const Divider(color: kFieldFill),
                  Row(
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                      const Spacer(),
                      Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kTealDark)),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                TextField(controller: _notesController, decoration: authFieldDecoration('Notes', hint: 'Optional', icon: Icons.notes_outlined), maxLines: 3),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  authErrorBanner(_error!),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: viewModel.isSaving ? null : () => _submit(viewModel),
                    style: ElevatedButton.styleFrom(backgroundColor: kTealDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: viewModel.isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Complete dispensing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    );
  }
}
