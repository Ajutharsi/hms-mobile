import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/admin_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

typedef AttendancePayload = ({List<AdminAttendanceRow> rows, Map<String, int> totals, String date});

class AdminAttendanceViewModel extends AdminSectionViewModel<AttendancePayload> {
  DateTime date = DateTime.now();

  @override
  Future<AttendancePayload> fetch(String token) =>
      api.attendance(token, date: date.toIso8601String().split('T').first);

  void setDate(DateTime value) {
    date = value;
    load();
  }
}

/// One day's attendance register, with the date as the main control —
/// correcting yesterday is the usual reason to open this away from a desk.
///
/// Marking someone twice on the same day corrects the first mark rather
/// than adding a second; the API does that, so the screen can simply
/// offer "mark" without asking whether this is a correction.
class AdminAttendanceScreen extends StatelessWidget {
  const AdminAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminAttendanceViewModel(),
        child: const CareTheme(child: _AttendanceView()),
      );
}

class _AttendanceView extends StatelessWidget {
  const _AttendanceView();

  static const _statuses = ['present', 'absent', 'leave', 'half_day'];

  Future<void> _pickDate(BuildContext context, AdminAttendanceViewModel viewModel) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) viewModel.setDate(picked);
  }

  Future<void> _edit(BuildContext context, AdminAttendanceViewModel viewModel, AdminAttendanceRow row) async {
    final values = await careFormSheet(
      context,
      title: row.userName ?? 'Attendance',
      fields: [
        CareFormField('status', 'Status', initial: row.status, required: true, options: _statuses, icon: Icons.how_to_reg_outlined),
        CareFormField('shift', 'Shift', initial: row.shift, icon: Icons.schedule_outlined),
        CareFormField('check_in', 'Check in (HH:MM)', initial: row.checkIn, icon: Icons.login_outlined),
        CareFormField('check_out', 'Check out (HH:MM)', initial: row.checkOut, icon: Icons.logout_outlined),
        CareFormField('notes', 'Notes', initial: row.notes, maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.attendanceUpdate(token, row.id, values));
    if (context.mounted) careSnack(context, error ?? 'Attendance updated.', isError: error != null);
  }

  (Color, Color) _tone(String? status) => switch (status) {
        'present' => (kSuccessFg, kSuccessBg),
        'absent' => (kDangerFg, kDangerBg),
        'leave' => (kInfoFg, kInfoBg),
        _ => (kWarnText, kWarnSurface),
      };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminAttendanceViewModel>();
    final rows = viewModel.data?.rows ?? const <AdminAttendanceRow>[];
    final totals = viewModel.data?.totals ?? const <String, int>{};
    final shown = viewModel.data?.date ?? '';

    return AdminSectionScaffold(
      title: 'Attendance',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: rows.length,
      onRefresh: viewModel.load,
      emptyIcon: Icons.how_to_reg_outlined,
      emptyTitle: 'Nobody marked for this day',
      emptyMessage: 'Pick another date, or mark the register on the web.',
      header: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: CareCard(
              onTap: () => _pickDate(context, viewModel),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: kCare),
                  const SizedBox(width: 10),
                  Expanded(child: Text(shown.isEmpty ? 'Pick a date' : shown, style: CareText.titleMd)),
                  const Icon(Icons.chevron_right_rounded, color: kCareChevron),
                ],
              ),
            ),
          ),
          AdminStatRow(stats: [
            AdminStat(value: '${totals['present'] ?? 0}', label: 'Present', color: kSuccessFg),
            AdminStat(value: '${totals['absent'] ?? 0}', label: 'Absent', color: kDangerFg),
            AdminStat(value: '${totals['leave'] ?? 0}', label: 'On leave', color: kInfoFg),
            AdminStat(value: '${totals['marked'] ?? 0}', label: 'Marked'),
          ]),
        ],
      ),
      itemBuilder: (context, i) {
        final row = rows[i];
        final (fg, bg) = _tone(row.status);
        return AdminCard(
          title: row.userName ?? 'Staff member',
          subtitle: [row.shift, if (row.checkIn != null) '${row.checkIn} – ${row.checkOut ?? '…'}']
              .where((s) => s != null && s.isNotEmpty)
              .join(' · '),
          detail: row.notes,
          badge: row.status?.replaceAll('_', ' '),
          badgeColor: fg,
          badgeBg: bg,
          onTap: () => _edit(context, viewModel, row),
          actions: [
            (label: 'Edit', icon: Icons.edit_outlined, onTap: () => _edit(context, viewModel, row), destructive: false),
          ],
        );
      },
    );
  }
}
