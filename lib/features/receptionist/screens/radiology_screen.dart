import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/receptionist/models/radiology_order.dart';
import 'package:hms_mobile/features/receptionist/screens/radiology_detail_screen.dart';
import 'package:hms_mobile/features/receptionist/screens/radiology_order_screen.dart';
import 'package:hms_mobile/features/receptionist/viewmodels/radiology_view_model.dart';

class RadiologyScreen extends StatelessWidget {
  const RadiologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => RadiologyViewModel(),
      child: const _RadiologyView(),
    );
  }
}

class _RadiologyView extends StatelessWidget {
  const _RadiologyView();

  Future<void> _create(BuildContext context, RadiologyViewModel viewModel) async {
    final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RadiologyOrderScreen()));
    if (created == true) viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<RadiologyViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Radiology'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, viewModel),
        backgroundColor: kCareDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New order', style: CareText.onCare),
      ),
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    ));
  }

  Widget _buildBody(BuildContext context, RadiologyViewModel viewModel) {
    if (viewModel.isLoading && viewModel.orders.isEmpty) {
      return const CareStateView.loading();
    }
    if (viewModel.loadError != null && viewModel.orders.isEmpty) {
      return CareStateView.error(viewModel.loadError!);
    }

    final stats = viewModel.stats;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        if (stats != null)
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: [
              _StatTile(label: 'Total', value: '${stats.total}', color: kCareDark, bg: kCareSoft),
              _StatTile(label: 'Pending', value: '${stats.pending}', color: kWarningFg, bg: kWarningBg),
              _StatTile(label: 'Completed', value: '${stats.completed}', color: kSuccessFg, bg: kSuccessBg),
              _StatTile(label: 'Emergency', value: '${stats.emergency}', color: kDangerFg, bg: kDangerBg),
            ],
          ),
        const SizedBox(height: 16),
        if (viewModel.orders.isEmpty)
          const CareStateView.inline(icon: Icons.camera_outlined, title: "No radiology orders", message: "Imaging you order for a patient will be listed here.")
        else
          for (final order in viewModel.orders) ...[
            _OrderCard(
              order: order,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RadiologyDetailScreen(orderId: order.id)));
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: CareText.statValue(color)),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: CareText.xxs, color: color, fontWeight: CareText.medium)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final RadiologyOrder order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  static Map<String, (Color, Color)> get _priorityColors => {
    'routine': (kMuted, kCareBg),
    'urgent': (kWarningFg, kWarningBg),
    'emergency': (kDangerFg, kDangerBg),
  };

  static Map<String, (Color, Color)> get _statusColors => {
    'ordered': (kMuted, kCareBg),
    'scheduled': (kInfoFg, kInfoBg),
    'in_progress': (kInfoFg, kInfoBg),
    'completed': (kSuccessFg, kSuccessBg),
    'cancelled': (kDangerFg, kDangerBg),
  };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final (pFg, pBg) = _priorityColors[order.priority] ?? (kMuted, kCareBg);
    final (sFg, sBg) = _statusColors[order.status] ?? (kMuted, kCareBg);

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
                Expanded(child: Text(order.patientName ?? 'Patient', style: CareText.titleLg)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(order.status.replaceAll('_', ' '), style: CareText.chip(sFg)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text('${order.modality} · ${order.bodyPart}', style: CareText.mutedSm),
            Text(order.studyDescription, style: CareText.mutedXs),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: pBg, borderRadius: BorderRadius.circular(7)),
                  child: Text(order.priority, style: TextStyle(color: pFg, fontSize: CareText.xxs, fontWeight: CareText.bold)),
                ),
                const Spacer(),
                Text(order.orderNo ?? '', style: CareText.mutedXs),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
