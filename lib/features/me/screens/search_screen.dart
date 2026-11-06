import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/me/models/me_models.dart';
import 'package:hms_mobile/features/me/viewmodels/me_view_models.dart';

/// One box over patients, appointments and invoices.
///
/// It matches the identifiers people quote down a phone -- an MRN, an
/// appointment number, an invoice number -- plus a patient's full name.
/// Names are encrypted in the database, so a partial name cannot be
/// matched; the screen says so rather than quietly returning nothing.
class GlobalSearchScreen extends StatelessWidget {
  /// Called with the hit the person picked, if the caller can open it.
  final void Function(BuildContext context, SearchHit hit)? onOpen;

  const GlobalSearchScreen({super.key, this.onOpen});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => SearchViewModel(),
        child: CareTheme(child: _SearchView(onOpen: onOpen)),
      );
}

class _SearchView extends StatelessWidget {
  final void Function(BuildContext context, SearchHit hit)? onOpen;
  const _SearchView({this.onOpen});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<SearchViewModel>();

    return Scaffold(
      appBar: carePageAppBar(context, 'Search'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: TextField(
              autofocus: true,
              onChanged: viewModel.search,
              decoration: careFieldDecoration(
                'Search',
                hint: 'MRN, appointment or invoice number',
                icon: Icons.search_rounded,
              ),
            ),
          ),
          Expanded(child: _body(context, viewModel)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, SearchViewModel viewModel) {
    if (viewModel.query.trim().length < 2) {
      return const CareStateView(
        icon: Icons.search_rounded,
        title: 'Search the hospital',
        message: 'Type an MRN, an appointment number, an invoice number, or a patient\'s full name.',
      );
    }
    if (viewModel.isSearching && viewModel.hits.isEmpty) return const CareStateView.loading();
    if (viewModel.loadError != null) return CareStateView.error(viewModel.loadError!);
    if (viewModel.hits.isEmpty) {
      return const CareStateView(
        icon: Icons.search_off_rounded,
        title: 'Nothing found',
        message: 'Patient names are stored encrypted, so a name has to be spelled in full to match.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: viewModel.hits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final hit = viewModel.hits[i];
        final (IconData icon, String label) = switch (hit.type) {
          'patient' => (Icons.person_outline_rounded, 'Patient'),
          'appointment' => (Icons.event_outlined, 'Appointment'),
          'invoice' => (Icons.receipt_long_outlined, 'Invoice'),
          _ => (Icons.help_outline_rounded, hit.type),
        };

        return CareCard(
          onTap: onOpen == null ? null : () => onOpen!(context, hit),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: kCareSoft, borderRadius: BorderRadius.circular(CareRadius.control)),
                child: Icon(icon, size: 20, color: kCare),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hit.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleMd),
                    if (hit.subtitle.isNotEmpty)
                      Text(hit.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.mutedSm),
                  ],
                ),
              ),
              CareChip(label: label, bg: kCareNeutralBg, fg: kMuted),
            ],
          ),
        );
      },
    );
  }
}
