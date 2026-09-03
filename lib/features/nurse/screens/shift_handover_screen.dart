import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/nurse/models/shift_handover.dart';
import 'package:hms_mobile/features/nurse/screens/shift_handover_create_screen.dart';
import 'package:hms_mobile/features/nurse/screens/shift_handover_detail_screen.dart';
import 'package:hms_mobile/features/nurse/viewmodels/shift_handover_view_model.dart';

class ShiftHandoverScreen extends StatelessWidget {
  const ShiftHandoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShiftHandoverViewModel(),
      child: const _ShiftHandoverView(),
    );
  }
}

class _ShiftHandoverView extends StatelessWidget {
  const _ShiftHandoverView();

  static const _statuses = [null, 'draft', 'pending_acceptance', 'accepted', 'rejected'];
  static const _statusLabels = {
    null: 'All',
    'draft': 'Draft',
    'pending_acceptance': 'Pending',
    'accepted': 'Accepted',
    'rejected': 'Rejected',
  };

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ShiftHandoverViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Shift Handover')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final createdId = await Navigator.of(context).push<int>(
            MaterialPageRoute(builder: (_) => const ShiftHandoverCreateScreen()),
          );
          if (createdId != null && context.mounted) {
            viewModel.load();
          }
        },
        backgroundColor: kTealDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New handover', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                for (final status in _statuses) ...[
                  _FilterChip(
                    label: _statusLabels[status]!,
                    selected: viewModel.statusFilter == status,
                    onTap: () => viewModel.setStatusFilter(status),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kTeal,
              onRefresh: viewModel.load,
              child: _buildBody(context, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ShiftHandoverViewModel viewModel) {
    if (viewModel.isLoading && viewModel.handovers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }

    if (viewModel.loadError != null && viewModel.handovers.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
          const SizedBox(height: 12),
          Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
        ],
      );
    }

    if (viewModel.handovers.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.swap_horiz_rounded, color: kMuted, size: 40),
          SizedBox(height: 12),
          Text('No handovers yet', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: viewModel.handovers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final handover = viewModel.handovers[index];
        return _HandoverCard(
          handover: handover,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ShiftHandoverDetailScreen(handoverId: handover.id)),
            );
            viewModel.load();
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kTealDark : kFieldFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : kMuted, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _HandoverCard extends StatelessWidget {
  final ShiftHandoverSummary handover;
  final VoidCallback onTap;
  const _HandoverCard({required this.handover, required this.onTap});

  static const _statusStyle = {
    'draft': (kMuted, kFieldFill, 'Draft'),
    'pending_acceptance': (kWarningFg, kWarningBg, 'Pending'),
    'accepted': (kSuccessFg, kSuccessBg, 'Accepted'),
    'rejected': (kDangerFg, kDangerBg, 'Rejected'),
  };

  @override
  Widget build(BuildContext context) {
    final (fg, bg, label) = _statusStyle[handover.status] ?? (kMuted, kFieldFill, handover.status);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(handover.wardName ?? 'Ward', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${handover.currentShift.toUpperCase()} → ${handover.nextShift.toUpperCase()} · ${handover.handoverDate ?? ''}',
              style: const TextStyle(fontSize: 12.5, color: kMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.arrow_upward_rounded, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Text(handover.outgoingNurseName ?? '—', style: const TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(width: 14),
                const Icon(Icons.arrow_downward_rounded, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Text(handover.incomingNurseName ?? '—', style: const TextStyle(fontSize: 12, color: kMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
