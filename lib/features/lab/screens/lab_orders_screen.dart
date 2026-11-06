import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/lab/models/lab_order.dart';
import 'package:hms_mobile/features/lab/screens/lab_order_create_screen.dart';
import 'package:hms_mobile/features/lab/screens/lab_order_detail_screen.dart';
import 'package:hms_mobile/features/lab/viewmodels/lab_orders_view_model.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

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
        label: const Text('New order', style: CareText.onCare),
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
      return const CareStateView.loading();
    }
    if (viewModel.loadError != null && viewModel.orders.isEmpty) {
      return CareStateView.error(viewModel.loadError!);
    }
    if (viewModel.orders.isEmpty) {
      return const CareStateView(
        icon: Icons.assignment_outlined,
        title: 'No lab orders',
        message: 'Orders raised for tests appear here.',
      );
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
      borderRadius: BorderRadius.circular(CareRadius.card),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(CareRadius.card), border: Border.all(color: kCareBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(order.patientName ?? 'Patient', style: CareText.titleLg)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(CareRadius.chip)),
                  child: Text(order.status, style: CareText.chip(fg)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(order.patientMrn ?? '', style: CareText.mutedXs),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(order.orderNo ?? '', style: CareText.mutedXsMedium),
                const Spacer(),
                const Icon(Icons.science_outlined, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Text('${order.testsCount} tests', style: CareText.mutedXs),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
