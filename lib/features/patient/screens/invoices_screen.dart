import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/patient/models/invoice.dart';
import 'package:hms_mobile/features/patient/viewmodels/invoices_view_model.dart';

/// The bills list body — shown on the "Bills & Payments" page the home
/// shell pushes. There's no payment gateway wired up anywhere in this app,
/// so this is read-only billing information plus a "request help" button
/// that lets a patient ask the billing team to follow up — it deliberately
/// does not pretend to be a "Pay now" button.
class InvoicesTabBody extends StatelessWidget {
  const InvoicesTabBody({super.key});

  Future<void> _confirmRequestHelp(BuildContext context, InvoicesViewModel viewModel, Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Request billing help?'),
        content: Text(
          'This sends invoice ${invoice.invoiceNo} to our billing team, who will contact you about the ₹${invoice.balance.toStringAsFixed(2)} balance. '
          "This doesn't process a payment — there's no online payment option yet.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Send request', style: TextStyle(color: kCareDark, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await viewModel.requestHelp(invoice.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? kCareDark : null,
        content: Text(error ?? 'Request sent — our billing team will contact you shortly.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<InvoicesViewModel>();

    return RefreshIndicator(
      color: kCare,
      onRefresh: viewModel.loadInvoices,
      child: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, InvoicesViewModel viewModel) {
    if (viewModel.isLoading && viewModel.invoices.isEmpty) return const CareStateView.loading();
    if (viewModel.errorMessage != null && viewModel.invoices.isEmpty) return CareStateView.error(viewModel.errorMessage!);
    if (viewModel.invoices.isEmpty) {
      return const CareStateView(
        icon: Icons.receipt_long_rounded,
        title: 'No invoices yet',
        message: 'Your billing history will show up here.',
      );
    }

    final outstanding = viewModel.invoices.fold<double>(0, (sum, invoice) => sum + invoice.balance);
    final unpaidCount = viewModel.invoices.where((invoice) => invoice.hasBalance).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        _BalanceSummary(outstanding: outstanding, unpaidCount: unpaidCount, total: viewModel.invoices.length),
        const SizedBox(height: 18),
        const CareSectionTitle(title: 'All Invoices'),
        const SizedBox(height: 12),
        for (final invoice in viewModel.invoices) ...[
          _InvoiceCard(
            invoice: invoice,
            isRequestingHelp: viewModel.requestingHelpFor.contains(invoice.id),
            onRequestHelp: () => _confirmRequestHelp(context, viewModel, invoice),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  final double outstanding;
  final int unpaidCount;
  final int total;

  const _BalanceSummary({required this.outstanding, required this.unpaidCount, required this.total});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return CareHeaderBackground(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Outstanding balance', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '₹${outstanding.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  unpaidCount == 0 ? 'All $total invoices are paid' : '$unpaidCount of $total invoices pending',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
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
    watchCarePalette(context);
    return CareCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 12, 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          iconColor: kCare,
          collapsedIconColor: kMuted,
          leading: const CareIconBox(icon: Icons.receipt_long_rounded, size: 44),
          title: Row(
            children: [
              Expanded(
                child: Text(invoice.invoiceNo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
              ),
              CareChip.status(invoice.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(invoice.date, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                const Spacer(),
                Text(
                  invoice.hasBalance ? 'Due ₹${invoice.balance.toStringAsFixed(2)}' : 'Paid',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: invoice.hasBalance ? kCarePinkFg : kSuccessFg,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
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
                  Divider(height: 16, color: kCareBorder),
                  _AmountRow(label: 'Total', value: invoice.total),
                  _AmountRow(label: 'Paid', value: invoice.paidAmount),
                  _AmountRow(label: 'Balance', value: invoice.balance, emphasize: true),
                ],
              ),
            ),
            if (invoice.hasBalance) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: isRequestingHelp ? null : onRequestHelp,
                  icon: isRequestingHelp
                      ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kCare))
                      : const Icon(Icons.support_agent_rounded, size: 19),
                  label: const Text('Request payment help', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
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
    watchCarePalette(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: emphasize ? kInk : kMuted, fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400)),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(fontSize: emphasize ? 14 : 13, fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500, color: emphasize ? kCareDark : kInk),
          ),
        ],
      ),
    );
  }
}
