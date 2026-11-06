import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_forms.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/doctor/models/doctor_models.dart';
import 'package:hms_mobile/features/doctor/viewmodels/doctor_view_models.dart';

/// The doctor's own clinic week.
///
/// These rows are what the patient app's slot picker is built from, and
/// until now only an administrator could change them, on the web. A
/// doctor who stops a Friday clinic had to ask somebody.
class DoctorScheduleScreen extends StatelessWidget {
  const DoctorScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => DoctorScheduleViewModel(),
        child: const CareTheme(child: _ScheduleView()),
      );
}

class _ScheduleView extends StatelessWidget {
  const _ScheduleView();

  static const _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  Future<void> _addOrEdit(BuildContext context, DoctorScheduleViewModel viewModel, [DoctorScheduleEntry? entry]) async {
    final values = await careFormSheet(
      context,
      title: entry == null ? 'Add clinic hours' : entry.dayLabel,
      fields: [
        CareFormField('day', 'Day', initial: entry?.day, options: _days, icon: Icons.calendar_today_outlined),
        CareFormField('start_time', 'From (HH:MM)',
            initial: entry?.startTime ?? '09:00', required: true, icon: Icons.schedule_outlined),
        CareFormField('end_time', 'To (HH:MM)',
            initial: entry?.endTime ?? '17:00', required: true, icon: Icons.schedule_rounded),
        CareFormField('slot_duration', 'Minutes per patient',
            initial: '${entry?.slotDuration ?? 30}', keyboard: TextInputType.number, icon: Icons.timelapse_outlined),
        CareFormField('is_available', 'Taking bookings',
            initial: (entry?.isAvailable ?? true) ? 'yes' : 'no',
            options: const ['yes', 'no'],
            icon: Icons.event_available_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    // The sheet hands back words; the API wants the flag.
    values['is_available'] = values['is_available'] == 'no' ? '0' : '1';

    final error = await viewModel.mutate((api, token) =>
        entry == null ? api.scheduleStore(token, values) : api.scheduleUpdate(token, entry.id, values));
    if (context.mounted) {
      careSnack(context, error ?? (entry == null ? 'Clinic hours added.' : 'Clinic hours updated.'), isError: error != null);
    }
  }

  Future<void> _delete(BuildContext context, DoctorScheduleViewModel viewModel, DoctorScheduleEntry entry) async {
    final yes = await careConfirm(context,
        title: 'Remove ${entry.dayLabel} ${entry.hours}?',
        message: 'Patients will no longer be offered these slots. Visits already booked are not touched.',
        confirmLabel: 'Remove');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.scheduleDestroy(token, entry.id));
    if (context.mounted) careSnack(context, error ?? 'Clinic hours removed.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DoctorScheduleViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, 'My schedule'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(context, viewModel),
        backgroundColor: kCareDark,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add hours', style: CareText.onCareBold),
      ),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: _body(context, viewModel),
      ),
    );
  }

  Widget _body(BuildContext context, DoctorScheduleViewModel viewModel) {
    if (viewModel.isLoading && viewModel.entries.isEmpty) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.entries.isEmpty) return CareStateView.error(viewModel.loadError!);
    if (viewModel.entries.isEmpty) {
      return const CareStateView(
        icon: Icons.event_note_outlined,
        title: 'No clinic hours set',
        message: 'Until a session is added here, the patient app offers no slots with you.',
      );
    }

    // Grouped by day so the week reads as a week.
    final byDay = <String, List<DoctorScheduleEntry>>{};
    for (final entry in viewModel.entries) {
      byDay.putIfAbsent(entry.day, () => []).add(entry);
    }
    final days = _days.where(byDay.containsKey).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        CareCard(
          child: Row(
            children: [
              Icon(Icons.event_available_rounded, color: kCare),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  viewModel.days == 1
                      ? 'Taking bookings on 1 day a week'
                      : 'Taking bookings on ${viewModel.days} days a week',
                  style: CareText.bodyMd,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final day in days) ...[
          Text(day[0].toUpperCase() + day.substring(1), style: CareText.titleLg),
          const SizedBox(height: 8),
          CareCard(
            child: Column(
              children: [
                for (final entry in byDay[day]!)
                  Opacity(
                    opacity: entry.isAvailable ? 1 : 0.55,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.hours, style: CareText.titleMd),
                                  Text(
                                    entry.isAvailable
                                        ? '${entry.slotDuration} min each · ${entry.slots} slots'
                                        : 'Not taking bookings',
                                    style: CareText.mutedSm,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _addOrEdit(context, viewModel, entry),
                              icon: Icon(Icons.edit_outlined, size: 19, color: kCare),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              onPressed: () => _delete(context, viewModel, entry),
                              icon: const Icon(Icons.close_rounded, size: 19, color: kCareHint),
                            ),
                          ],
                        ),
                        if (entry != byDay[day]!.last) Divider(height: 1, color: kCareBorder),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
