import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/invoices_view_model.dart';

const _kPaymentMethods = ['cash', 'card', 'upi', 'bank_transfer', 'cheque'];

class InvoiceDetailScreen extends StatelessWidget {
  final int invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvoiceDetailViewModel(invoiceId: invoiceId),
      child: const _InvoiceDetailView(),
    );
  }
}

class _InvoiceDetailView extends StatelessWidget {
  const _InvoiceDetailView();

  Future<void> _addPayment(BuildContext context, InvoiceDetailViewModel viewModel) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _PaymentDialog(defaultAmount: viewModel.invoice!.balance),
    );
    if (result == null || !context.mounted) return;

    final error = await viewModel.addPayment(
      amount: double.tryParse(result['amount'] ?? '') ?? 0,
      paymentMethod: result['payment_method']!,
      referenceNo: result['reference_no'],
      notes: result['notes'],
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error == null ? kTealDark : null, content: Text(error ?? 'Payment recorded!')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InvoiceDetailViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: kInk, elevation: 0, title: Text(viewModel.invoice?.invoiceNo ?? 'Invoice')),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, InvoiceDetailViewModel viewModel) {
    if (viewModel.isLoading && viewModel.invoice == null) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (viewModel.loadError != null && viewModel.invoice == null) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }

    final invoice = viewModel.invoice!;
    final canPay = invoice.status != 'cancelled' && invoice.balance > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(invoice.patientName ?? 'Patient', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
              Text(invoice.patientMrn ?? '', style: const TextStyle(fontSize: 12.5, color: kMuted)),
              const SizedBox(height: 10),
              _amountRow('Subtotal', invoice.subtotal),
              _amountRow('Discount', -invoice.discount),
              _amountRow('Tax', invoice.tax),
              const Divider(height: 20, color: kFieldFill),
              _amountRow('Total', invoice.total, bold: true),
              _amountRow('Paid', invoice.paidAmount, color: kSuccessFg),
              _amountRow('Balance', invoice.balance, color: invoice.balance > 0 ? const Color(0xFFB3261E) : kSuccessFg, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
        const SizedBox(height: 10),
        for (final item in invoice.items) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kFieldFill)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.itemName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk)),
                      Text('${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: kMuted)),
                    ],
                  ),
                ),
                Text('₹${item.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTealDark)),
              ],
            ),
          ),
        ],
        if (invoice.payments.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Payment history', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 10),
          for (final p in invoice.payments) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: kSuccessBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.paymentMethod.toUpperCase(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kSuccessFg)),
                        if (p.paymentDate != null) Text(p.paymentDate!, style: const TextStyle(fontSize: 11.5, color: kMuted)),
                      ],
                    ),
                  ),
                  Text('₹${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kSuccessFg)),
                ],
              ),
            ),
          ],
        ],
        if (canPay) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _addPayment(context, viewModel),
              style: ElevatedButton.styleFrom(backgroundColor: kTealDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.payments_outlined, color: Colors.white),
              label: const Text('Add payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _amountRow(String label, double amount, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: kMuted)),
          const Spacer(),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: bold ? 14.5 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? kInk),
          ),
        ],
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final double defaultAmount;
  const _PaymentDialog({required this.defaultAmount});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final _amountController = TextEditingController(text: widget.defaultAmount.toStringAsFixed(2));
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  String _method = _kPaymentMethods.first;

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
      title: const Text('Add payment'),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Payment method'),
                items: _kPaymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m.replaceAll('_', ' ').toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _method = v!),
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
        TextButton(
          onPressed: () => Navigator.of(context).pop({
            'amount': _amountController.text.trim(),
            'payment_method': _method,
            'reference_no': _referenceController.text.trim(),
            'notes': _notesController.text.trim(),
          }),
          child: const Text('Record'),
        ),
      ],
    );
  }
}
