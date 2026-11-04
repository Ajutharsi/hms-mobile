import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/receptionist/models/invoice.dart';
import 'package:hms_mobile/features/receptionist/screens/invoice_create_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/invoice_detail_screen.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/invoices_view_model.dart';

const _kStatusFilters = [null, 'draft', 'sent', 'paid', 'partial', 'overdue', 'cancelled'];

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => InvoicesViewModel(),
      child: const _InvoicesView(),
    );
  }
}

class _InvoicesView extends StatefulWidget {
  const _InvoicesView();

  @override
  State<_InvoicesView> createState() => _InvoicesViewState();
}

class _InvoicesViewState extends State<_InvoicesView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _create(BuildContext context, InvoicesViewModel viewModel) async {
    final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvoiceCreateScreen()));
    if (created == true) viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<InvoicesViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Invoices'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New invoice', style: CareText.onCare),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchController,
              decoration: careFieldDecoration('Search invoices', hint: 'Patient name or MRN', icon: Icons.search),
              onSubmitted: viewModel.search,
              onChanged: (v) {
                if (v.isEmpty) viewModel.search('');
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final status in _kStatusFilters) ...[
                  ChoiceChip(
                    label: Text(status == null ? 'All' : status[0].toUpperCase() + status.substring(1)),
                    selected: viewModel.statusFilter == status,
                    onSelected: (_) => viewModel.setFilter(status),
                    selectedColor: kCareSoft,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel))),
        ],
      ),
    ));
  }

  Widget _buildBody(BuildContext context, InvoicesViewModel viewModel) {
    if (viewModel.isLoading && viewModel.invoices.isEmpty) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }
    if (viewModel.loadError != null && viewModel.invoices.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: CareText.muted),
      ]);
    }

    final stats = viewModel.stats;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        if (stats != null) ...[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _StatTile(label: 'Total Invoices', value: '${stats.totalInvoices}', color: kCareDark, bg: kCareSoft),
              _StatTile(label: 'Overdue', value: '${stats.overdue}', color: kDangerFg, bg: kDangerBg),
              _StatTile(label: 'Paid', value: '₹${stats.paid.toStringAsFixed(0)}', color: kSuccessFg, bg: kSuccessBg),
              _StatTile(label: 'Outstanding', value: '₹${stats.outstanding.toStringAsFixed(0)}', color: kWarningFg, bg: kWarningBg),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (viewModel.invoices.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('No invoices found', style: CareText.muted)))
        else
          for (final invoice in viewModel.invoices) ...[
            _InvoiceCard(
              invoice: invoice,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id)));
                viewModel.load();
              },
            ),
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
    watchCarePalette(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: CareText.xl, fontWeight: CareText.heavy, color: color)),
          Text(label, style: CareText.tag(color)),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  const _InvoiceCard({required this.invoice, required this.onTap});

  static Map<String, (Color, Color)> get _statusColors => {
    'draft': (kMuted, kCareBg),
    'sent': (kInfoFg, kInfoBg),
    'paid': (kSuccessFg, kSuccessBg),
    'partial': (kWarningFg, kWarningBg),
    'overdue': (kDangerFg, kDangerBg),
    'cancelled': (kMuted, kCareBg),
  };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final (fg, bg) = _statusColors[invoice.status] ?? (kMuted, kCareBg);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kCareBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(invoice.patientName ?? 'Patient', style: CareText.titleLg)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Text(invoice.status, style: CareText.chip(fg)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text('${invoice.invoiceNo ?? ''} · ${invoice.patientMrn ?? ''}', style: CareText.mutedXs),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Total ₹${invoice.total.toStringAsFixed(2)}', style: CareText.titleSmMedium),
                const Spacer(),
                Text(
                  'Balance ₹${invoice.balance.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: CareText.sm, fontWeight: CareText.bold, color: invoice.balance > 0 ? kDangerText : kSuccessFg),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
