import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/features/patient/models/invoice.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/patient/viewmodels/invoices_view_model.dart';

/// The Invoices tab body — embedded inside [HomeScreen]'s bottom-nav shell.
/// There's no payment gateway wired up anywhere in this app, so this is
/// read-only billing information plus a "request help" button that lets a
/// patient ask the billing team to follow up — it deliberately does not
/// pretend to be a "Pay now" button.
class InvoicesTabBody extends StatelessWidget {
  const InvoicesTabBody({super.key});

  Future<void> _confirmRequestHelp(BuildContext context, InvoicesViewModel viewModel, Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request billing help?'),
        content: Text(
          'This sends invoice ${invoice.invoiceNo} to our billing team, who will contact you about the ₹${invoice.balance.toStringAsFixed(2)} balance. '
          "This doesn't process a payment — there's no online payment option yet.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send request', style: TextStyle(color: kTealDark, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await viewModel.requestHelp(invoice.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? kTealDark : null,
        content: Text(error ?? 'Request sent — our billing team will contact you shortly.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InvoicesViewModel>();

    return RefreshIndicator(
      color: kTeal,
      onRefresh: viewModel.loadInvoices,
      child: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, InvoicesViewModel viewModel) {
    if (viewModel.isLoading && viewModel.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }

    if (viewModel.errorMessage != null && viewModel.invoices.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
          const SizedBox(height: 12),
          Text(viewModel.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
        ],
      );
    }

    if (viewModel.invoices.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.receipt_long_outlined, color: kMuted, size: 40),
          SizedBox(height: 12),
          Text(
            'No invoices yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk),
          ),
          SizedBox(height: 6),
          Text(
            'Your billing history will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 13.5),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: viewModel.invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final invoice = viewModel.invoices[index];
        return _InvoiceCard(
          invoice: invoice,
          isRequestingHelp: viewModel.requestingHelpFor.contains(invoice.id),
          onRequestHelp: () => _confirmRequestHelp(context, viewModel, invoice),
        );
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final bool isRequestingHelp;
  final VoidCallback onRequestHelp;

  const _InvoiceCard({required this.invoice, required this.isRequestingHelp, required this.onRequestHelp});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          iconColor: kTeal,
          collapsedIconColor: kMuted,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  invoice.invoiceNo,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: kInk),
                ),
              ),
              _StatusChip(status: invoice.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: kMuted),
                const SizedBox(width: 5),
                Text(invoice.date, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                const Spacer(),
                Text(
                  invoice.hasBalance ? 'Balance ₹${invoice.balance.toStringAsFixed(2)}' : 'Fully paid',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: invoice.hasBalance ? const Color(0xFFB3261E) : const Color(0xFF2F7D5B),
                  ),
                ),
              ],
            ),
          ),
          children: [
            _AmountRow(label: 'Total', value: invoice.total),
            _AmountRow(label: 'Paid', value: invoice.paidAmount),
            _AmountRow(label: 'Balance', value: invoice.balance, emphasize: true),
            const SizedBox(height: 10),
            ...invoice.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.itemName}${item.quantity > 1 ? ' × ${item.quantity}' : ''}',
                          style: const TextStyle(fontSize: 13, color: kInk),
                        ),
                      ),
                      Text('₹${item.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: kMuted)),
                    ],
                  ),
                )),
            if (invoice.hasBalance) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  onPressed: isRequestingHelp ? null : onRequestHelp,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kTeal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isRequestingHelp
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: kTeal),
                        )
                      : const Text(
                          'Request payment help',
                          style: TextStyle(color: kTealDark, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasize;
  const _AmountRow({required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: kMuted)),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: kInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      'paid' => (const Color(0xFFE6F4E6), const Color(0xFF2F7D5B), 'Paid'),
      'partial' => (const Color(0xFFFBF1DE), const Color(0xFF8A5A00), 'Partial'),
      'unpaid' => (const Color(0xFFFBEAE8), const Color(0xFFB3261E), 'Unpaid'),
      _ => (kFieldFill, kMuted, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}
