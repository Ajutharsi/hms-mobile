import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/models/ipd_deposit.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';
import 'package:hms_mobile/features/receptionist/screens/insurance_claims_screen.dart' show ReceptionPatientPickerField;
import 'package:hms_mobile/features/receptionist/viewmodels/ipd_deposits_view_model.dart';

const _kPaymentMethods = ['cash', 'card', 'upi', 'bank_transfer', 'cheque'];

String _titleCase(String s) => s.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

class IpdDepositsScreen extends StatelessWidget {
  const IpdDepositsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IpdDepositsViewModel(),
      child: const _IpdDepositsView(),
    );
  }
}

class _IpdDepositsView extends StatelessWidget {
  const _IpdDepositsView();

  Future<void> _collect(BuildContext context, IpdDepositsViewModel viewModel) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => const _CollectDialog());
    if (result == null || !context.mounted) return;

    final error = await viewModel.store(
      patientId: result['patient_id'] as int,
      amount: result['amount'] as double,
      paymentMethod: result['payment_method'] as String,
      referenceNo: result['reference_no'] as String?,
      notes: result['notes'] as String?,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Deposit recorded successfully!')));
  }

  Future<void> _refund(BuildContext context, IpdDepositsViewModel viewModel, IpdDeposit deposit) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _RefundDialog(deposit: deposit));
    if (result == null || !context.mounted) return;

    final error = await viewModel.refund(deposit.id, amount: result['amount'] as double, paymentMethod: result['payment_method'] as String, notes: result['notes'] as String?);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Refund recorded.')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<IpdDepositsViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, foregroundColor: kInk, elevation: 0, title: const Text('IPD Deposits', style: TextStyle(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _collect(context, viewModel),
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Collect deposit', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(color: kTeal, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    );
  }

  Widget _buildBody(BuildContext context, IpdDepositsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.deposits.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.deposits.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }

    final stats = viewModel.stats;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        if (stats != null)
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Collected', value: '₹${stats.totalCollected.toStringAsFixed(0)}', color: kSuccessFg, bg: kSuccessBg)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(label: 'Refunded', value: '₹${stats.totalRefunded.toStringAsFixed(0)}', color: kWarningFg, bg: kWarningBg)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(label: 'Today', value: '₹${stats.todayCollection.toStringAsFixed(0)}', color: kTealDark, bg: kMint)),
            ],
          ),
        const SizedBox(height: 20),
        if (viewModel.deposits.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('No deposits recorded yet', style: TextStyle(color: kMuted))))
        else
          for (final deposit in viewModel.deposits) ...[
            _DepositCard(deposit: deposit, onRefund: deposit.type == 'advance' ? () => _refund(context, viewModel, deposit) : null),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _StatTile({required this.label, required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DepositCard extends StatelessWidget {
  final IpdDeposit deposit;
  final VoidCallback? onRefund;
  const _DepositCard({required this.deposit, this.onRefund});

  @override
  Widget build(BuildContext context) {
    final isAdvance = deposit.type == 'advance';
    final amountColor = isAdvance ? kSuccessFg : kWarningFg;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(deposit.patientName ?? 'Patient', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: isAdvance ? kSuccessBg : kWarningBg, borderRadius: BorderRadius.circular(8)),
                child: Text(_titleCase(deposit.type), style: TextStyle(color: amountColor, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Text(deposit.patientMrn ?? '', style: const TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${isAdvance ? '+' : '-'}₹${deposit.amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: amountColor)),
              const SizedBox(width: 10),
              Text(_titleCase(deposit.paymentMethod), style: const TextStyle(fontSize: 12, color: kMuted)),
              const Spacer(),
              Text('Balance: ₹${deposit.balance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
            ],
          ),
          if (onRefund != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(onPressed: onRefund, icon: const Icon(Icons.undo, size: 15), label: const Text('Refund'), style: TextButton.styleFrom(foregroundColor: kTealDark)),
            ),
          ],
        ],
      ),
    );
  }
}

class _CollectDialog extends StatefulWidget {
  const _CollectDialog();

  @override
  State<_CollectDialog> createState() => _CollectDialogState();
}

class _CollectDialogState extends State<_CollectDialog> {
  ReceptionPatient? _patient;
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = _kPaymentMethods.first;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Collect deposit'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReceptionPatientPickerField(value: _patient, errorText: _error, onChanged: (p) => setState(() { _patient = p; _error = null; })),
              const SizedBox(height: 10),
              TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment method'),
                items: _kPaymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(_titleCase(m)))).toList(),
                onChanged: (v) => setState(() => _paymentMethod = v ?? _paymentMethod),
              ),
              const SizedBox(height: 10),
              TextField(controller: _referenceController, decoration: const InputDecoration(labelText: 'Reference no (optional)')),
              const SizedBox(height: 10),
              TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text);
            if (_patient == null) {
              setState(() => _error = 'Pick a patient');
              return;
            }
            if (amount == null || amount <= 0) return;
            Navigator.of(context).pop({
              'patient_id': _patient!.id,
              'amount': amount,
              'payment_method': _paymentMethod,
              'reference_no': _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
              'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            });
          },
          style: FilledButton.styleFrom(backgroundColor: kTealDark),
          child: const Text('Collect'),
        ),
      ],
    );
  }
}

class _RefundDialog extends StatefulWidget {
  final IpdDeposit deposit;
  const _RefundDialog({required this.deposit});

  @override
  State<_RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<_RefundDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = _kPaymentMethods.first;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Refund ${widget.deposit.patientName ?? ''}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available balance: ₹${widget.deposit.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: kMuted)),
            const SizedBox(height: 10),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Refund amount')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items: _kPaymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(_titleCase(m)))).toList(),
              onChanged: (v) => setState(() => _paymentMethod = v ?? _paymentMethod),
            ),
            const SizedBox(height: 10),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text);
            if (amount == null || amount <= 0 || amount > widget.deposit.balance) return;
            Navigator.of(context).pop({'amount': amount, 'payment_method': _paymentMethod, 'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim()});
          },
          style: FilledButton.styleFrom(backgroundColor: kTealDark),
          child: const Text('Refund'),
        ),
      ],
    );
  }
}
