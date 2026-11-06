import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/admin_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

typedef LeavesPayload = ({List<AdminLeave> leaves, Map<String, int> totals});

class AdminLeavesViewModel extends AdminSectionViewModel<LeavesPayload> {
  String status = 'pending';

  @override
  Future<LeavesPayload> fetch(String token) => api.leaves(token, status: status);

  void setStatus(String value) {
    status = value;
    load();
  }
}

/// Leave requests, opening on the pending ones.
///
/// Deciding a request is the one thing on this screen anyone wants to do
/// away from a desk, so approve is a single tap. Rejecting asks for a
/// reason, because a refusal without one is no use to whoever asked.
class AdminLeavesScreen extends StatelessWidget {
  const AdminLeavesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminLeavesViewModel(),
      child: const CareTheme(child: _LeavesView()),
    );
  }
}

class _LeavesView extends StatelessWidget {
  const _LeavesView();

  Future<void> _approve(BuildContext context, AdminLeavesViewModel viewModel, AdminLeave leave) async {
    final yes = await careConfirm(context,
        title: 'Approve ${leave.days} day${leave.days == 1 ? '' : 's'}?',
        message: '${leave.userName ?? 'This person'} is away ${leave.fromDate} to ${leave.toDate}.',
        confirmLabel: 'Approve');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.leaveApprove(token, leave.id));
    if (context.mounted) careSnack(context, error ?? 'Leave approved.', isError: error != null);
  }

  Future<void> _reject(BuildContext context, AdminLeavesViewModel viewModel, AdminLeave leave) async {
    final values = await careFormSheet(
      context,
      title: 'Reject this request',
      submitLabel: 'Reject',
      fields: const [CareFormField('remarks', 'Reason', required: true, maxLines: 3, icon: Icons.notes_outlined)],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.leaveReject(token, leave.id, values['remarks'] as String));
    if (context.mounted) careSnack(context, error ?? 'Leave rejected.', isError: error != null);
  }

  (Color, Color) _tone(String? status) => switch (status) {
        'approved' => (kSuccessFg, kSuccessBg),
        'rejected' => (kDangerFg, kDangerBg),
        _ => (kWarnText, kWarnSurface),
      };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminLeavesViewModel>();
    final leaves = viewModel.data?.leaves ?? const <AdminLeave>[];
    final totals = viewModel.data?.totals ?? const <String, int>{};

    return AdminSectionScaffold(
      title: 'Leave Requests',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: leaves.length,
      onRefresh: viewModel.load,
      emptyIcon: Icons.event_available_outlined,
      emptyTitle: viewModel.status == 'pending' ? 'Nothing waiting on you' : 'No requests here',
      emptyMessage: viewModel.status == 'pending'
          ? 'New requests appear here as soon as they are raised.'
          : 'Try another status.',
      header: Column(
        children: [
          AdminStatRow(stats: [
            AdminStat(value: '${totals['pending'] ?? 0}', label: 'Pending', color: kWarnText),
            AdminStat(value: '${totals['approved'] ?? 0}', label: 'Approved', color: kSuccessFg),
            AdminStat(value: '${totals['rejected'] ?? 0}', label: 'Rejected', color: kDangerFg),
          ]),
          AdminFilterChips(
            value: viewModel.status,
            onChanged: viewModel.setStatus,
            options: const [
              (value: 'pending', label: 'Pending'),
              (value: 'approved', label: 'Approved'),
              (value: 'rejected', label: 'Rejected'),
              (value: '', label: 'All'),
            ],
          ),
        ],
      ),
      itemBuilder: (context, i) {
        final leave = leaves[i];
        final (fg, bg) = _tone(leave.status);
        return AdminCard(
          title: leave.userName ?? 'Staff member',
          subtitle: '${leave.leaveType ?? 'Leave'} · ${leave.days} day${leave.days == 1 ? '' : 's'}',
          detail: [
            '${leave.fromDate} → ${leave.toDate}',
            if (leave.reason != null && leave.reason!.isNotEmpty) leave.reason,
            if (leave.remarks != null && leave.remarks!.isNotEmpty) 'Remarks: ${leave.remarks}',
          ].join('\n'),
          badge: leave.status,
          badgeColor: fg,
          badgeBg: bg,
          actions: leave.isPending
              ? [
                  (label: 'Approve', icon: Icons.check_rounded, onTap: () => _approve(context, viewModel, leave), destructive: false),
                  (label: 'Reject', icon: Icons.close_rounded, onTap: () => _reject(context, viewModel, leave), destructive: true),
                ]
              : const [],
        );
      },
    );
  }
}
