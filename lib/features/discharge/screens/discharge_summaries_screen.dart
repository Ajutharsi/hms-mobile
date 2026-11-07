import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/features/discharge/services/discharge_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_forms.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/discharge/models/discharge_models.dart';

class DischargeStaysViewModel extends ChangeNotifier {
  final DischargeApiService api;
  final AuthStorage authStorage;

  DischargeStaysViewModel({DischargeApiService? api, AuthStorage? authStorage})
      : api = api ?? DischargeApiService(),
        authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<DischargeStay> stays = [];
  int admitted = 0;
  int unwritten = 0;
  String state = 'admitted';

  Future<String> _token() async => (await authStorage.readToken())!;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async {
        final result = await api.stays(await _token(), state: state);
        stays = result.stays;
        admitted = result.admitted;
        unwritten = result.unwritten;
      });
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void showState(String value) {
    if (state == value) return;
    state = value;
    load();
  }
}

/// Which stays still need the document the patient leaves with.
class DischargeSummariesScreen extends StatelessWidget {
  const DischargeSummariesScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => DischargeStaysViewModel(),
        child: const CareTheme(child: _StaysView()),
      );
}

class _StaysView extends StatelessWidget {
  const _StaysView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DischargeStaysViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, 'Discharge summaries'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                CareChoicePill(
                  label: 'Admitted (${viewModel.admitted})',
                  selected: viewModel.state == 'admitted',
                  onTap: () => viewModel.showState('admitted'),
                ),
                const SizedBox(width: 8),
                CareChoicePill(
                  label: viewModel.unwritten > 0 ? 'Discharged (${viewModel.unwritten} to write)' : 'Discharged',
                  selected: viewModel.state == 'discharged',
                  onTap: () => viewModel.showState('discharged'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kCare,
              onRefresh: viewModel.load,
              child: _body(context, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, DischargeStaysViewModel viewModel) {
    if (viewModel.isLoading && viewModel.stays.isEmpty) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.stays.isEmpty) return CareStateView.error(viewModel.loadError!);
    if (viewModel.stays.isEmpty) {
      return const CareStateView(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Nothing here',
        message: 'Stays appear here while the patient is in, and after they leave.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: viewModel.stays.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final stay = viewModel.stays[i];

        return CareCard(
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DischargeSummaryScreen(admissionId: stay.id),
            ));
            if (context.mounted) viewModel.load();
          },
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stay.patientName ?? 'Patient',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleMd),
                    Text(
                      [stay.admissionNo, stay.patientMrn ?? '', stay.where].where((s) => s.isNotEmpty).join(' · '),
                      style: CareText.mutedSm,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stay.dischargeDate?.isNotEmpty == true
                          ? 'In ${stay.admissionDate} — out ${stay.dischargeDate}'
                          : 'Admitted ${stay.admissionDate}',
                      style: CareText.mutedXs,
                    ),
                  ],
                ),
              ),
              CareChip(
                label: stay.hasSummary ? 'written' : 'to write',
                bg: stay.hasSummary ? kSuccessBg : kWarningBg,
                fg: stay.hasSummary ? kSuccessFg : kWarningFg,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------- one summary

class DischargeSummaryViewModel extends ChangeNotifier {
  final int admissionId;
  final DischargeApiService api;
  final AuthStorage authStorage;

  DischargeSummaryViewModel({
    required this.admissionId,
    DischargeApiService? api,
    AuthStorage? authStorage,
  })  : api = api ?? DischargeApiService(),
        authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  bool isSaving = false;
  String? loadError;
  DischargeSummary? summary;

  Future<String> _token() async => (await authStorage.readToken())!;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async {
        summary = await api.summary(await _token(), admissionId);
      });
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> save(String notes) async {
    isSaving = true;
    notifyListeners();
    try {
      await guardNetworkErrors(() async => api.save(await _token(), admissionId, notes));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}

/// One stay, gathered, with the doctor's closing note at the end.
///
/// The diagnosis, the drugs and the tests are read from the stay rather
/// than typed again; only the note is written here.
class DischargeSummaryScreen extends StatelessWidget {
  final int admissionId;
  const DischargeSummaryScreen({super.key, required this.admissionId});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => DischargeSummaryViewModel(admissionId: admissionId),
        child: const CareTheme(child: _SummaryView()),
      );
}

class _SummaryView extends StatelessWidget {
  const _SummaryView();

  Future<void> _write(BuildContext context, DischargeSummaryViewModel viewModel) async {
    final existing = viewModel.summary?.stay.dischargeNotes ?? '';

    final values = await careFormSheet(
      context,
      title: existing.isEmpty ? 'Write summary' : 'Edit summary',
      submitLabel: 'Save',
      fields: [
        CareFormField('discharge_notes', 'Condition on discharge and advice',
            initial: existing, required: true, maxLines: 8, icon: Icons.edit_note_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.save(values['discharge_notes']?.toString() ?? '');
    if (context.mounted) careSnack(context, error ?? 'Discharge summary saved.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DischargeSummaryViewModel>();
    final summary = viewModel.summary;

    return Scaffold(
      appBar: carePageAppBar(context, 'Discharge summary'),
      floatingActionButton: summary == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _write(context, viewModel),
              backgroundColor: kCareDark,
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              label: Text(
                (summary.stay.dischargeNotes ?? '').isEmpty ? 'Write' : 'Edit',
                style: CareText.onCareBold,
              ),
            ),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: _body(context, viewModel, summary),
      ),
    );
  }

  Widget _body(BuildContext context, DischargeSummaryViewModel viewModel, DischargeSummary? summary) {
    if (viewModel.isLoading && summary == null) return const CareStateView.loading();
    if (viewModel.loadError != null && summary == null) return CareStateView.error(viewModel.loadError!);
    if (summary == null) return const CareStateView.loading();

    final stay = summary.stay;
    final notes = stay.dischargeNotes ?? '';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 92),
      children: [
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stay.patientName ?? 'Patient', style: CareText.titleXl),
              Text([stay.admissionNo, stay.patientMrn].where((s) => (s ?? '').isNotEmpty).join(' · '),
                  style: CareText.mutedSm),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (stay.where.isNotEmpty) CareChip(label: stay.where, bg: kCareSoft, fg: kCareDark),
                  if (stay.days != null)
                    CareChip(label: '${stay.days} day${stay.days == 1 ? '' : 's'}', bg: kInfoBg, fg: kInfoFg),
                  CareChip.status(stay.status),
                ],
              ),
              if ((stay.admissionReason ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Admitted for', style: CareText.mutedXs),
                Text(stay.admissionReason!, style: CareText.bodyMd),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        const CareSectionTitle(title: 'Condition on discharge'),
        const SizedBox(height: 8),
        CareCard(
          child: notes.isEmpty
              ? const Row(
                  children: [
                    Icon(Icons.edit_note_outlined, color: kWarningFg),
                    SizedBox(width: 10),
                    Expanded(child: Text('Not written yet.', style: CareText.bodyMdMuted)),
                  ],
                )
              : Text(notes, style: CareText.bodyMd),
        ),
        _Section(
          title: 'Diagnoses',
          empty: 'No consultation was recorded during this stay.',
          isEmpty: summary.diagnoses.isEmpty,
          child: Column(
            children: [
              for (final d in summary.diagnoses)
                _Line(
                  title: d.diagnosis?.isNotEmpty == true ? d.diagnosis! : (d.chiefComplaint ?? 'Consultation'),
                  subtitle: [d.date, d.doctorName, d.icd10Code].where((s) => (s ?? '').isNotEmpty).join(' · '),
                  body: d.treatmentPlan,
                  isLast: d == summary.diagnoses.last,
                ),
            ],
          ),
        ),
        _Section(
          title: 'Medicines given',
          empty: 'Nothing was prescribed during this stay.',
          isEmpty: summary.medicines.isEmpty,
          child: Column(
            children: [
              for (final m in summary.medicines)
                _Line(
                  title: m.medicineName,
                  subtitle: m.instruction,
                  isLast: m == summary.medicines.last,
                ),
            ],
          ),
        ),
        _Section(
          title: 'Tests',
          empty: 'No lab test was ordered during this stay.',
          isEmpty: summary.tests.isEmpty,
          child: Column(
            children: [
              for (final t in summary.tests)
                _Line(
                  title: t.testName ?? 'Test',
                  subtitle: [t.orderNo, t.status].where((s) => (s ?? '').isNotEmpty).join(' · '),
                  isLast: t == summary.tests.last,
                ),
            ],
          ),
        ),
        if (summary.lastVitals != null) ...[
          const SizedBox(height: 18),
          const CareSectionTitle(title: 'Last recorded vitals'),
          const SizedBox(height: 8),
          CareCard(
            child: Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                for (final entry in summary.lastVitals!.entries)
                  if (entry.value.isNotEmpty && entry.key != 'recorded_at')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key.replaceAll('_', ' '), style: CareText.mutedXs),
                        Text(entry.value, style: CareText.titleMd),
                      ],
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String empty;
  final bool isEmpty;
  final Widget child;

  const _Section({required this.title, required this.empty, required this.isEmpty, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        CareSectionTitle(title: title),
        const SizedBox(height: 8),
        CareCard(child: isEmpty ? Text(empty, style: CareText.mutedSm) : child),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? body;
  final bool isLast;

  const _Line({required this.title, required this.subtitle, this.body, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: CareText.titleMd),
              if (subtitle.isNotEmpty) Text(subtitle, style: CareText.mutedSm),
              if ((body ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: kCareNeutralBg,
                    borderRadius: BorderRadius.circular(CareRadius.control),
                  ),
                  child: Text(body!, style: CareText.mutedSm),
                ),
              ],
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: kCareBorder),
      ],
    );
  }
}
