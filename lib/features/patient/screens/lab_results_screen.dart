import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/features/patient/models/lab_order.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/patient/viewmodels/lab_results_view_model.dart';

/// The Lab Results tab body — embedded inside [HomeScreen]'s bottom-nav
/// shell rather than being its own full Scaffold.
class LabResultsTabBody extends StatelessWidget {
  const LabResultsTabBody({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LabResultsViewModel>();

    return RefreshIndicator(
      color: kTeal,
      onRefresh: viewModel.loadLabResults,
      child: _buildBody(viewModel),
    );
  }

  Widget _buildBody(LabResultsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.labOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }

    if (viewModel.errorMessage != null && viewModel.labOrders.isEmpty) {
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

    if (viewModel.labOrders.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.biotech_outlined, color: kMuted, size: 40),
          SizedBox(height: 12),
          Text(
            'No lab results yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk),
          ),
          SizedBox(height: 6),
          Text(
            'Your lab orders will show up here as soon as one is placed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 13.5),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                  order.doctorName ?? 'Lab Order',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: kInk),
                ),
              ),
              if (hasAbnormal) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFBEAE8), borderRadius: BorderRadius.circular(8)),
                  child: const Text(
                    'Review',
                    style: TextStyle(color: Color(0xFFB3261E), fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              _OrderStatusChip(status: order.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: kMuted),
                const SizedBox(width: 5),
                Text(order.date, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                const SizedBox(width: 12),
                Text(order.orderNo, style: const TextStyle(fontSize: 12.5, color: kMuted)),
              ],
            ),
          ),
          children: [
            if ((order.notes ?? '').isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  order.notes!,
                  style: const TextStyle(fontSize: 13, color: kMuted, fontStyle: FontStyle.italic),
                ),
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

class _OrderStatusChip extends StatelessWidget {
  final String status;
  const _OrderStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      'pending' => (const Color(0xFFFBF1DE), const Color(0xFF8A5A00), 'Pending'),
      'processing' => (const Color(0xFFE3EEFB), const Color(0xFF2B6CB0), 'Processing'),
      'completed' => (const Color(0xFFE6F4E6), const Color(0xFF2F7D5B), 'Completed'),
      'cancelled' => (const Color(0xFFF1E9E9), const Color(0xFF8A6B6B), 'Cancelled'),
      _ => (kFieldFill, kMuted, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final LabResultItem item;
  const _ResultRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasResult = (item.resultValue ?? '').isNotEmpty;

    final (Color flagColor, String flagLabel) = switch (item.flag) {
      'high' => (const Color(0xFFB3261E), 'High'),
      'low' => (const Color(0xFF2B6CB0), 'Low'),
      'normal' => (const Color(0xFF2F7D5B), 'Normal'),
      _ => (kMuted, ''),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.testName ?? 'Test',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk),
                ),
              ),
              if (flagLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: flagColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    flagLabel,
                    style: TextStyle(color: flagColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          if ((item.category ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(item.category!, style: const TextStyle(fontSize: 12, color: kMuted)),
          ],
          const SizedBox(height: 6),
          if (hasResult)
            Row(
              children: [
                Text(
                  '${item.resultValue} ${item.unit ?? ''}'.trim(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk),
                ),
                if ((item.normalRange ?? '').isNotEmpty && item.normalRange != 'N/A') ...[
                  const SizedBox(width: 10),
                  Text('Normal: ${item.normalRange}', style: const TextStyle(fontSize: 12, color: kMuted)),
                ],
              ],
            )
          else
            const Text(
              'Awaiting results',
              style: TextStyle(fontSize: 13, color: kMuted, fontStyle: FontStyle.italic),
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
