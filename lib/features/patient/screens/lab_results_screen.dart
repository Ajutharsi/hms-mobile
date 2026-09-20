import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/patient/models/lab_order.dart';
import 'package:hms_mobile/features/patient/viewmodels/lab_results_view_model.dart';

/// The Lab tab body — sits under the home shell's "Lab Results" header.
class LabResultsTabBody extends StatelessWidget {
  const LabResultsTabBody({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LabResultsViewModel>();

    return RefreshIndicator(
      color: kCare,
      onRefresh: viewModel.loadLabResults,
      child: _buildBody(viewModel),
    );
  }

  Widget _buildBody(LabResultsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.labOrders.isEmpty) return const CareStateView.loading();
    if (viewModel.errorMessage != null && viewModel.labOrders.isEmpty) return CareStateView.error(viewModel.errorMessage!);
    if (viewModel.labOrders.isEmpty) {
      return const CareStateView(
        icon: Icons.biotech_rounded,
        title: 'No lab results yet',
        message: 'Your lab orders will show up here as soon as one is placed.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      itemCount: viewModel.labOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _LabOrderCard(order: viewModel.labOrders[index]),
    );
  }
}

class _LabOrderCard extends StatelessWidget {
  final LabOrder order;
  const _LabOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final hasAbnormal = order.isCompleted && order.items.any((item) => item.flag == 'high' || item.flag == 'low');

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
          leading: const CareIconBox(icon: Icons.biotech_rounded, size: 44),
          title: Text(
            order.orderNo.isNotEmpty ? order.orderNo : 'Lab Order',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((order.doctorName ?? '').isNotEmpty)
                  Text(order.doctorName!, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    CareChip(label: order.date, bg: kCarePinkBg, fg: kCarePinkFg, icon: Icons.calendar_today_rounded),
                    CareChip.status(order.status),
                    if (hasAbnormal) const CareChip(label: 'Review', bg: kDangerBg, fg: kDangerFg, icon: Icons.priority_high_rounded),
                  ],
                ),
              ],
            ),
          ),
          children: [
            if ((order.notes ?? '').isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(order.notes!, style: const TextStyle(fontSize: 13, color: kMuted, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 10),
            ],
            ...order.items.map((item) => _ResultRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final LabResultItem item;
  const _ResultRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasResult = (item.resultValue ?? '').isNotEmpty;

    final (Color flagBg, Color flagFg, String flagLabel) = switch (item.flag) {
      'high' => (kDangerBg, kDangerFg, 'High'),
      'low' => (kInfoBg, kInfoFg, 'Low'),
      'normal' => (kSuccessBg, kSuccessFg, 'Normal'),
      _ => (kCareBg, kMuted, ''),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.testName ?? 'Test', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
              ),
              if (flagLabel.isNotEmpty) CareChip(label: flagLabel, bg: flagBg, fg: flagFg),
            ],
          ),
          if ((item.category ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(item.category!, style: const TextStyle(fontSize: 12, color: kMuted)),
          ],
          const SizedBox(height: 8),
          if (hasResult)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.resultValue} ${item.unit ?? ''}'.trim(),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kCareDark),
                ),
                if ((item.normalRange ?? '').isNotEmpty && item.normalRange != 'N/A') ...[
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('Normal: ${item.normalRange}', style: const TextStyle(fontSize: 12, color: kMuted)),
                  ),
                ],
              ],
            )
          else
            const Row(
              children: [
                Icon(Icons.hourglass_top_rounded, size: 14, color: kMuted),
                SizedBox(width: 4),
                Text('Awaiting results', style: TextStyle(fontSize: 13, color: kMuted, fontStyle: FontStyle.italic)),
              ],
            ),
          if ((item.remarks ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.remarks!, style: const TextStyle(fontSize: 12.5, color: kMuted)),
          ],
        ],
      ),
    );
  }
}
