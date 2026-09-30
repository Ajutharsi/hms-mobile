import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/lab/models/lab_order.dart';
import 'package:hms_mobile/features/lab/screens/lab_order_create_screen.dart';
import 'package:hms_mobile/features/lab/screens/lab_order_detail_screen.dart';
import 'package:hms_mobile/features/lab/viewmodels/lab_orders_view_model.dart';

const _kStatusFilters = [null, 'pending', 'processing', 'completed', 'cancelled'];

class LabOrdersScreen extends StatelessWidget {
  const LabOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => LabOrdersViewModel(),
      child: const _LabOrdersView(),
    );
  }
}

class _LabOrdersView extends StatelessWidget {
  const _LabOrdersView();

  Future<void> _create(BuildContext context, LabOrdersViewModel viewModel) async {
    final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabOrderCreateScreen()));
    if (created != null) viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<LabOrdersViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Lab Orders'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New order', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
          Expanded(child: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel))),
        ],
      ),
    ));
  }

  Widget _buildBody(BuildContext context, LabOrdersViewModel viewModel) {
    if (viewModel.isLoading && viewModel.orders.isEmpty) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }
    if (viewModel.loadError != null && viewModel.orders.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.orders.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.assignment_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No lab orders found', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: viewModel.orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = viewModel.orders[index];
        return _OrderCard(
          order: order,
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LabOrderDetailScreen(orderId: order.id)));
            viewModel.load();
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final LabOrder order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  static const _statusColors = {
    'pending': (kWarningFg, kWarningBg),
    'processing': (kInfoFg, kInfoBg),
    'completed': (kSuccessFg, kSuccessBg),
    'cancelled': (kDangerFg, kDangerBg),
  };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final (fg, bg) = _statusColors[order.status] ?? (kMuted, kCareBg);

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
                Expanded(child: Text(order.patientName ?? 'Patient', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Text(order.status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(order.patientMrn ?? '', style: const TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(order.orderNo ?? '', style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.science_outlined, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Text('${order.testsCount} tests', style: const TextStyle(fontSize: 12, color: kMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
