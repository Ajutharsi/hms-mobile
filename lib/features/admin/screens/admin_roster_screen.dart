import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/ops_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

class AdminRosterViewModel extends AdminSectionViewModel<RosterWeek> {
  /// Monday of the week being shown; null means this week.
  String? week;

  /// Hide everyone with no shift set, which on a big staff list is most
  /// of them.
  bool onlyRostered = false;

  @override
  Future<RosterWeek> fetch(String token) => api.rosterWeek(token, week: week);

  void showWeek(String value) {
    week = value;
    load();
  }

  void setOnlyRostered(bool value) {
    if (onlyRostered == value) return;
    onlyRostered = value;
    notifyListeners();
  }
}

/// Who is on which shift, a week at a time.
///
/// Attendance says what happened and leave says who is away; this is
/// what was planned, and it was the only one of the three that lived
/// on paper.
class AdminRosterScreen extends StatelessWidget {
  const AdminRosterScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminRosterViewModel(),
        child: const CareTheme(child: _RosterView()),
      );
}

class _RosterView extends StatelessWidget {
  const _RosterView();

  static const _shifts = ['morning', 'evening', 'night', 'off'];

  Future<void> _edit(BuildContext context, AdminRosterViewModel viewModel, RosterPerson person, RosterDay day) async {
    if (day.onLeave) {
      careSnack(context, '${person.name} has approved leave on ${day.date}.', isError: true);
      return;
    }

    final values = await careFormSheet(
      context,
      title: '${person.name} · ${day.date}',
      submitLabel: 'Set shift',
      fields: [
        CareFormField('shift', 'Shift', initial: day.shift ?? 'morning', options: _shifts, icon: Icons.schedule_outlined),
        CareFormField('notes', 'Notes', initial: day.notes, maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.rosterSet(token, {
          ...values,
          'user_id': person.id,
          'duty_date': day.date,
        }));
    if (context.mounted) careSnack(context, error ?? 'Shift set.', isError: error != null);
  }

  Future<void> _clear(BuildContext context, AdminRosterViewModel viewModel, RosterDay day) async {
    if (day.id == null) return;

    final error = await viewModel.mutate((api, token) => api.rosterClear(token, day.id!));
    if (context.mounted) careSnack(context, error ?? 'Shift cleared.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminRosterViewModel>();
    final weekData = viewModel.data;
    final staff = weekData == null
        ? const <RosterPerson>[]
        : (viewModel.onlyRostered ? weekData.staff.where((p) => p.hasAnyShift).toList() : weekData.staff);

    return Scaffold(
      appBar: carePageAppBar(context, 'Duty roster'),
      body: Column(
        children: [
          if (weekData != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous week',
                    onPressed: () => viewModel.showWeek(_shift(weekData.weekStart, -7)),
                    icon: Icon(Icons.chevron_left_rounded, color: kCare),
                  ),
                  Expanded(
                    child: Text(
                      'Week of ${weekData.weekStart}',
                      textAlign: TextAlign.center,
                      style: CareText.titleMd,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next week',
                    onPressed: () => viewModel.showWeek(_shift(weekData.weekStart, 7)),
                    icon: Icon(Icons.chevron_right_rounded, color: kCare),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                CareChoicePill(
                  label: 'Rostered (${weekData?.stats['shifts'] ?? 0})',
                  selected: viewModel.onlyRostered,
                  onTap: () => viewModel.setOnlyRostered(true),
                ),
                const SizedBox(width: 8),
                CareChoicePill(
                  label: 'All staff (${weekData?.stats['staff'] ?? 0})',
                  selected: !viewModel.onlyRostered,
                  onTap: () => viewModel.setOnlyRostered(false),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kCare,
              onRefresh: viewModel.load,
              child: _body(context, viewModel, weekData, staff),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AdminRosterViewModel viewModel,
    RosterWeek? weekData,
    List<RosterPerson> staff,
  ) {
    if (viewModel.isLoading && weekData == null) return const CareStateView.loading();
    if (viewModel.loadError != null && weekData == null) return CareStateView.error(viewModel.loadError!);
    if (weekData == null) return const CareStateView.loading();

    if (staff.isEmpty) {
      return CareStateView(
        icon: Icons.event_note_outlined,
        title: viewModel.onlyRostered ? 'Nobody rostered yet' : 'No staff',
        message: viewModel.onlyRostered
            ? 'Switch to all staff and tap a day to set a shift.'
            : 'Add staff accounts before building a roster.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: staff.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final person = staff[i];

        return CareCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(person.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleMd),
                  ),
                  if ((person.role ?? '').isNotEmpty)
                    CareChip(label: person.role!, bg: kCareNeutralBg, fg: kMuted),
                ],
              ),
              const SizedBox(height: 10),
              // A week has to fit across a phone, so each day is one
              // letter; the detail is behind a tap.
              Row(
                children: [
                  for (final day in person.days)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _edit(context, viewModel, person, day),
                        onLongPress: day.id == null ? null : () => _clear(context, viewModel, day),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _background(day),
                            borderRadius: BorderRadius.circular(CareRadius.chip),
                          ),
                          child: Column(
                            children: [
                              Text(day.date.substring(8), style: CareText.mutedXxs),
                              const SizedBox(height: 2),
                              Text(
                                day.onLeave ? 'L' : day.initial,
                                style: CareText.titleSm.copyWith(color: _foreground(day)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Color _background(RosterDay day) {
    if (day.onLeave) return kWarningBg;
    return switch (day.shift) {
      'morning' => kSuccessBg,
      'evening' => kInfoBg,
      'night' => kCareSoft,
      'off' => kCareNeutralBg,
      _ => kCareNeutralBg,
    };
  }

  static Color _foreground(RosterDay day) {
    if (day.onLeave) return kWarningFg;
    return switch (day.shift) {
      'morning' => kSuccessFg,
      'evening' => kInfoFg,
      'night' => kCareDark,
      'off' => kMuted,
      _ => kCareHint,
    };
  }

  /// Dates are plain YYYY-MM-DD strings from the server.
  static String _shift(String date, int days) {
    final parsed = DateTime.tryParse(date) ?? DateTime.now();
    final moved = parsed.add(Duration(days: days));
    return '${moved.year}-${moved.month.toString().padLeft(2, '0')}-${moved.day.toString().padLeft(2, '0')}';
  }
}
