import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/round_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_forms.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/rounds/models/round_models.dart';

class WardRoundsViewModel extends ChangeNotifier {
  final RoundApiService api;
  final AuthStorage authStorage;

  WardRoundsViewModel({RoundApiService? api, AuthStorage? authStorage})
      : api = api ?? RoundApiService(),
        authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  List<RoundPatient> patients = [];
  Map<String, int> stats = const {};

  /// Hide the patients already seen today, which is most of them by
  /// the end of a round.
  bool onlyUnseen = true;

  List<RoundPatient> get shown =>
      onlyUnseen ? patients.where((p) => !p.seenToday).toList() : patients;

  Future<String> _token() async => (await authStorage.readToken())!;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async {
        final result = await api.round(await _token());
        patients = result.patients;
        stats = result.stats;
      });
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setOnlyUnseen(bool value) {
    if (onlyUnseen == value) return;
    onlyUnseen = value;
    notifyListeners();
  }
}

/// Who on the ward has not been seen today.
///
/// Nurses had nursing notes and the clinic had consultations; the daily
/// round on an admitted patient had nowhere to go. The list is ordered
/// by who has waited longest, which is the question a round asks.
class WardRoundsScreen extends StatelessWidget {
  const WardRoundsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => WardRoundsViewModel(),
        child: const CareTheme(child: _RoundsView()),
      );
}

class _RoundsView extends StatelessWidget {
  const _RoundsView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<WardRoundsViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, 'Ward round'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                CareChoicePill(
                  label: 'Not seen (${viewModel.stats['not_seen'] ?? 0})',
                  selected: viewModel.onlyUnseen,
                  onTap: () => viewModel.setOnlyUnseen(true),
                ),
                const SizedBox(width: 8),
                CareChoicePill(
                  label: 'Everyone (${viewModel.stats['admitted'] ?? 0})',
                  selected: !viewModel.onlyUnseen,
                  onTap: () => viewModel.setOnlyUnseen(false),
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

  Widget _body(BuildContext context, WardRoundsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.patients.isEmpty) return const CareStateView.loading();
    if (viewModel.loadError != null && viewModel.patients.isEmpty) return CareStateView.error(viewModel.loadError!);

    final shown = viewModel.shown;
    if (shown.isEmpty) {
      return CareStateView(
        icon: Icons.done_all_rounded,
        title: viewModel.onlyUnseen ? 'Everyone has been seen' : 'Nobody is admitted',
        message: viewModel.onlyUnseen
            ? 'Every admitted patient has a note from today.'
            : 'Admitted patients appear here for the round.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: shown.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final patient = shown[i];

        return CareCard(
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RoundNotesScreen(admissionId: patient.admissionId),
            ));
            if (context.mounted) viewModel.load();
          },
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.patientName ?? 'Patient',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleMd),
                    Text(
                      [patient.patientMrn ?? '', patient.where].where((s) => s.isNotEmpty).join(' · '),
                      style: CareText.mutedSm,
                    ),
                    const SizedBox(height: 2),
                    Text(patient.lastSeen, style: CareText.mutedXs),
                  ],
                ),
              ),
              CareChip(
                label: patient.seenToday ? 'seen' : 'to see',
                bg: patient.seenToday ? kSuccessBg : kWarningBg,
                fg: patient.seenToday ? kSuccessFg : kWarningFg,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------- one patient

class RoundNotesViewModel extends ChangeNotifier {
  final int admissionId;
  final RoundApiService api;
  final AuthStorage authStorage;

  RoundNotesViewModel({required this.admissionId, RoundApiService? api, AuthStorage? authStorage})
      : api = api ?? RoundApiService(),
        authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  RoundDetail? detail;

  Future<String> _token() async => (await authStorage.readToken())!;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async {
        detail = await api.detail(await _token(), admissionId);
      });
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> mutate(Future<void> Function(RoundApiService api, String token) action) async {
    try {
      await guardNetworkErrors(() async => action(api, await _token()));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

/// One patient's round notes, newest first, with the last vitals beside
/// them because that is what the note is written against.
class RoundNotesScreen extends StatelessWidget {
  final int admissionId;
  const RoundNotesScreen({super.key, required this.admissionId});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => RoundNotesViewModel(admissionId: admissionId),
        child: const CareTheme(child: _NotesView()),
      );
}

class _NotesView extends StatelessWidget {
  const _NotesView();

  Future<void> _add(BuildContext context, RoundNotesViewModel viewModel) async {
    final values = await careFormSheet(
      context,
      title: 'Round note',
      submitLabel: 'Save note',
      fields: const [
        CareFormField('subjective', 'Subjective — what they report',
            maxLines: 2, icon: Icons.record_voice_over_outlined),
        CareFormField('objective', 'Objective — what you find', maxLines: 2, icon: Icons.visibility_outlined),
        CareFormField('assessment', 'Assessment', maxLines: 2, icon: Icons.psychology_outlined),
        CareFormField('plan', 'Plan', maxLines: 3, icon: Icons.checklist_rounded),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.addNote(token, viewModel.admissionId, values));
    if (context.mounted) careSnack(context, error ?? 'Note added.', isError: error != null);
  }

  Future<void> _remove(BuildContext context, RoundNotesViewModel viewModel, RoundNote note) async {
    final yes = await careConfirm(context,
        title: 'Remove this note?',
        message: 'It disappears from the patient\'s record.',
        confirmLabel: 'Remove');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.removeNote(token, note.id));
    if (context.mounted) careSnack(context, error ?? 'Note removed.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<RoundNotesViewModel>();
    final detail = viewModel.detail;

    return Scaffold(
      appBar: carePageAppBar(context, detail?.patientName ?? 'Round notes'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, viewModel),
        backgroundColor: kCareDark,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add note', style: CareText.onCareBold),
      ),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: _body(context, viewModel, detail),
      ),
    );
  }

  Widget _body(BuildContext context, RoundNotesViewModel viewModel, RoundDetail? detail) {
    if (viewModel.isLoading && detail == null) return const CareStateView.loading();
    if (viewModel.loadError != null && detail == null) return CareStateView.error(viewModel.loadError!);
    if (detail == null) return const CareStateView.loading();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 92),
      children: [
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.patientName ?? 'Patient', style: CareText.titleXl),
              Text([detail.admissionNo, detail.patientMrn ?? '', detail.where].where((s) => s.isNotEmpty).join(' · '),
                  style: CareText.mutedSm),
              if ((detail.admissionReason ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(detail.admissionReason!, style: CareText.bodyMdMuted),
              ],
              if (detail.lastVitals != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: kCareNeutralBg,
                    borderRadius: BorderRadius.circular(CareRadius.control),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      for (final entry in detail.lastVitals!.entries)
                        if (entry.value.isNotEmpty && entry.key != 'recorded_at')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key.replaceAll('_', ' '), style: CareText.mutedXs),
                              Text(entry.value, style: CareText.titleSm),
                            ],
                          ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (detail.notes.isEmpty)
          const CareStateView.inline(
            icon: Icons.edit_note_outlined,
            title: 'No notes yet',
            message: 'Add the first round note for this stay.',
          )
        else
          for (final note in detail.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(note.notedAt ?? '', style: CareText.titleMd),
                              if ((note.author ?? '').isNotEmpty)
                                Text(note.author!, style: CareText.mutedSm),
                            ],
                          ),
                        ),
                        CareChip(label: note.noteType, bg: kCareSoft, fg: kCareDark),
                        IconButton(
                          onPressed: () => _remove(context, viewModel, note),
                          icon: const Icon(Icons.close_rounded, size: 18, color: kCareHint),
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final part in note.parts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(part.label, style: CareText.mutedXs),
                            Text(part.text, style: CareText.bodyMd),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
