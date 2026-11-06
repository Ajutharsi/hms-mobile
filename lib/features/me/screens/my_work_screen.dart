import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_forms.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/me/models/me_models.dart';
import 'package:hms_mobile/features/me/viewmodels/me_view_models.dart';

/// "My attendance and leave" — the staff member's own record.
///
/// The administrator could already see everybody's attendance and
/// approve leave; the people it is about could see neither, and had to
/// ask. Applying for leave from here is the same request the admin
/// screen approves.
class MyWorkScreen extends StatelessWidget {
  const MyWorkScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => MyWorkViewModel(),
        child: const CareTheme(child: _MyWorkView()),
      );
}

class _MyWorkView extends StatefulWidget {
  const _MyWorkView();

  @override
  State<_MyWorkView> createState() => _MyWorkViewState();
}

class _MyWorkViewState extends State<_MyWorkView> {
  bool _showingLeave = false;

  Future<void> _apply(BuildContext context, MyWorkViewModel viewModel) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final values = await careFormSheet(
      context,
      title: 'Apply for leave',
      submitLabel: 'Send request',
      fields: [
        const CareFormField('leave_type', 'Type',
            options: ['casual', 'sick', 'annual', 'emergency', 'maternity', 'paternity'],
            icon: Icons.category_outlined),
        CareFormField('from_date', 'From (YYYY-MM-DD)', initial: today, required: true, icon: Icons.event_outlined),
        CareFormField('to_date', 'To (YYYY-MM-DD)', initial: today, required: true, icon: Icons.event_available_outlined),
        const CareFormField('reason', 'Reason', required: true, maxLines: 3, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.applyLeave(token, values));
    if (!context.mounted) return;
    careSnack(context, error ?? 'Request sent for approval.', isError: error != null);
    if (error == null) viewModel.load();
  }

  Future<void> _withdraw(BuildContext context, MyWorkViewModel viewModel, MyLeave leave) async {
    final yes = await careConfirm(context,
        title: 'Withdraw this request?',
        message: 'Your ${leave.leaveType} leave for ${leave.span} will be taken back.',
        confirmLabel: 'Withdraw');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.withdrawLeave(token, leave.id));
    if (!context.mounted) return;
    careSnack(context, error ?? 'Request withdrawn.', isError: error != null);
    if (error == null) viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<MyWorkViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, 'My attendance & leave'),
      floatingActionButton: _showingLeave
          ? FloatingActionButton.extended(
              onPressed: () => _apply(context, viewModel),
              backgroundColor: kCareDark,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Apply', style: CareText.onCareBold),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                CareChoicePill(
                  label: 'Attendance',
                  selected: !_showingLeave,
                  onTap: () => setState(() => _showingLeave = false),
                ),
                const SizedBox(width: 8),
                CareChoicePill(
                  label: 'Leave',
                  selected: _showingLeave,
                  onTap: () => setState(() => _showingLeave = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kCare,
              onRefresh: viewModel.load,
              child: _showingLeave ? _leave(context, viewModel) : _attendance(context, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendance(BuildContext context, MyWorkViewModel viewModel) {
    final attendance = viewModel.attendance;
    if (viewModel.isLoading && attendance == null) return const CareStateView.loading();
    if (viewModel.loadError != null && attendance == null) return CareStateView.error(viewModel.loadError!);
    if (attendance == null) return const CareStateView.loading();

    final summary = attendance.summary;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            Expanded(child: Text(_monthLabel(attendance.month), style: CareText.titleLg)),
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => viewModel.showMonth(_shift(attendance.month, -1)),
              icon: Icon(Icons.chevron_left_rounded, color: kCare),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () => viewModel.showMonth(_shift(attendance.month, 1)),
              icon: Icon(Icons.chevron_right_rounded, color: kCare),
            ),
          ],
        ),
        const SizedBox(height: 6),
        CareCard(
          child: Wrap(
            spacing: 22,
            runSpacing: 12,
            children: [
              _Figure(value: '${summary['present'] ?? 0}', label: 'Present', color: kSuccessFg),
              _Figure(value: '${summary['late'] ?? 0}', label: 'Late', color: kWarningFg),
              _Figure(value: '${summary['absent'] ?? 0}', label: 'Absent', color: kDangerFg),
              _Figure(value: '${summary['hours'] ?? 0}', label: 'Hours', color: kCareDark),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (attendance.days.isEmpty)
          const CareStateView.inline(
            icon: Icons.event_busy_outlined,
            title: 'Nothing marked',
            message: 'No attendance was recorded for you this month.',
          )
        else
          CareCard(
            child: Column(
              children: [
                for (final day in attendance.days)
                  _Line(
                    title: day.date,
                    subtitle: [day.hours, if ((day.shift ?? '').isNotEmpty) day.shift!].where((s) => s.isNotEmpty).join(' · '),
                    badge: day.status.replaceAll('_', ' '),
                    badgeFg: switch (day.status) {
                      'present' => kSuccessFg,
                      'late' => kWarningFg,
                      'absent' => kDangerFg,
                      _ => kInfoFg,
                    },
                    badgeBg: switch (day.status) {
                      'present' => kSuccessBg,
                      'late' => kWarningBg,
                      'absent' => kDangerBg,
                      _ => kInfoBg,
                    },
                    isLast: day == attendance.days.last,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _leave(BuildContext context, MyWorkViewModel viewModel) {
    final leaves = viewModel.leaves;
    if (viewModel.isLoading && leaves == null) return const CareStateView.loading();
    if (viewModel.loadError != null && leaves == null) return CareStateView.error(viewModel.loadError!);
    if (leaves == null) return const CareStateView.loading();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      children: [
        CareCard(
          child: Wrap(
            spacing: 22,
            runSpacing: 12,
            children: [
              _Figure(value: '${leaves.summary['pending'] ?? 0}', label: 'Pending', color: kWarningFg),
              _Figure(value: '${leaves.summary['approved'] ?? 0}', label: 'Approved', color: kSuccessFg),
              _Figure(value: '${leaves.summary['days_taken'] ?? 0}', label: 'Days taken', color: kCareDark),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (leaves.leaves.isEmpty)
          const CareStateView.inline(
            icon: Icons.beach_access_outlined,
            title: 'No leave requested',
            message: 'Tap Apply to send a request to your administrator.',
          )
        else
          for (final leave in leaves.leaves)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CareCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${leave.leaveType} · ${leave.days} day${leave.days == 1 ? '' : 's'}',
                              style: CareText.titleMd),
                          const SizedBox(height: 2),
                          Text(leave.span, style: CareText.mutedSm),
                          const SizedBox(height: 4),
                          Text(leave.reason, style: CareText.bodyMdMuted),
                          if ((leave.remarks ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(leave.remarks!, style: CareText.mutedSmItalic),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CareChip.status(leave.status),
                        if (leave.isPending)
                          TextButton(
                            onPressed: () => _withdraw(context, viewModel, leave),
                            child: const Text('Withdraw', style: CareText.mutedSmMedium),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  static String _monthLabel(String month) {
    final parts = month.split('-');
    if (parts.length != 2) return month;
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final index = int.tryParse(parts[1]) ?? 0;
    if (index < 1 || index > 12) return month;
    return '${names[index - 1]} ${parts[0]}';
  }

  static DateTime _shift(String month, int by) {
    final parts = month.split('-');
    final year = int.tryParse(parts.first) ?? DateTime.now().year;
    final index = parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1;
    return DateTime(year, index + by);
  }
}

class _Figure extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Figure({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: CareText.titleXl.copyWith(color: color)),
        Text(label, style: CareText.mutedXs),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeFg;
  final Color badgeBg;
  final bool isLast;

  const _Line({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeFg,
    required this.badgeBg,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: CareText.titleMd),
                    if (subtitle.isNotEmpty) Text(subtitle, style: CareText.mutedSm),
                  ],
                ),
              ),
              CareChip(label: badge, bg: badgeBg, fg: badgeFg),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: kCareBorder),
      ],
    );
  }
}
