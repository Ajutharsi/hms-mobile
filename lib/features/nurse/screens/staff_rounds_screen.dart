import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/viewmodels/rounds_view_model.dart';

/// Read-only charge-nurse view of every active round assignment across the
/// hospital. The web's assign/deactivate actions aren't wired into the
/// mobile API yet, so this screen is list-only for now.
class StaffRoundsScreen extends StatelessWidget {
  const StaffRoundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => StaffRoundsViewModel(),
      child: const _StaffRoundsView(),
    );
  }
}

class _StaffRoundsView extends StatelessWidget {
  const _StaffRoundsView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<StaffRoundsViewModel>();

    return CareTheme(child: Scaffold(
      appBar: carePageAppBar(context, 'Staff Rounds'),
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(viewModel)),
    ));
  }

  Widget _buildBody(StaffRoundsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.assignments.isEmpty) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }

    if (viewModel.loadError != null && viewModel.assignments.isEmpty) {
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

    if (viewModel.assignments.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.groups_outlined, color: kMuted, size: 40),
          SizedBox(height: 12),
          Text('No active round assignments', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: viewModel.assignments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final a = viewModel.assignments[index];
        final overdue = a['is_overdue'] == true;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: overdue ? kDangerFg : kCareBg, width: overdue ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${a['ward_name'] ?? 'Ward'}', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk)),
                    const SizedBox(height: 2),
                    Text('${a['staff_name'] ?? 'Staff'} · every ${a['frequency_hours'] ?? '?'}h', style: const TextStyle(fontSize: 12.5, color: kMuted)),
                    const SizedBox(height: 2),
                    Text('Assigned by ${a['assigned_by'] ?? '—'}', style: const TextStyle(fontSize: 11.5, color: kMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: overdue ? kDangerBg : kSuccessBg, borderRadius: BorderRadius.circular(8)),
                    child: Text(overdue ? 'Overdue' : 'On track', style: TextStyle(color: overdue ? kDangerFg : kSuccessFg, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  Text('Next: ${a['next_round_at'] ?? '—'}', style: const TextStyle(fontSize: 11, color: kMuted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
