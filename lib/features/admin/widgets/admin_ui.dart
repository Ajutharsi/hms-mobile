import 'package:flutter/material.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';

export 'package:hms_mobile/core/theme/care_forms.dart';

/// The pieces every admin section is built from.
///
/// All twelve look the same on purpose: a titled header, a row of totals,
/// a filter, a list of cards, and a form in a sheet. Writing that once
/// means a new section is a list of fields rather than another 300 lines
/// of scaffolding — and it is what kept the nurse and front-desk screens
/// from drifting apart once they shared CareStateView.

/// A number above a word — the strip under an admin screen's header.
class AdminStat extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  const AdminStat({super.key, required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Expanded(
      child: Column(
        children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: CareText.h3, fontWeight: CareText.heavy, color: color ?? kInk)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: CareText.mutedXs),
        ],
      ),
    );
  }
}

class AdminStatRow extends StatelessWidget {
  final List<AdminStat> stats;
  const AdminStatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: CareCard(child: Row(children: stats)),
    );
  }
}

/// A row of single-choice chips. An empty [value] means "all".
class AdminFilterChips extends StatelessWidget {
  final List<({String value, String label})> options;
  final String value;
  final ValueChanged<String> onChanged;
  const AdminFilterChips({super.key, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final option = options[i];
          final selected = option.value == value;
          return ChoiceChip(
            label: Text(option.label,
                style: TextStyle(
                  fontSize: CareText.sm,
                  fontWeight: CareText.medium,
                  color: selected ? kCareOn : kInk,
                )),
            selected: selected,
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: kCare,
            side: BorderSide(color: selected ? kCare : kCareBorder),
            onSelected: (_) => onChanged(option.value),
          );
        },
      ),
    );
  }
}

/// A list row: a title, a couple of grey lines under it, a trailing chip,
/// and an optional overflow menu.
class AdminCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? detail;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeBg;
  final VoidCallback? onTap;
  final List<({String label, IconData icon, VoidCallback onTap, bool destructive})> actions;

  const AdminCard({
    super.key,
    required this.title,
    this.subtitle,
    this.detail,
    this.badge,
    this.badgeColor,
    this.badgeBg,
    this.onTap,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: CareCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: CareText.titleMd),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.mutedSm),
                  ],
                  if (detail != null) ...[
                    const SizedBox(height: 6),
                    Text(detail!, maxLines: 2, overflow: TextOverflow.ellipsis, style: CareText.mutedXs),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: badgeBg ?? kCareSoft, borderRadius: BorderRadius.circular(CareRadius.pill)),
                child: Text(badge!, style: CareText.chip(badgeColor ?? kCareDark, size: CareText.xs)),
              ),
            ],
            if (actions.isNotEmpty)
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: kCareChevron),
                onSelected: (i) => actions[i].onTap(),
                itemBuilder: (context) => [
                  for (var i = 0; i < actions.length; i++)
                    PopupMenuItem(
                      value: i,
                      child: Row(
                        children: [
                          Icon(actions[i].icon, size: 18, color: actions[i].destructive ? kDangerText : kInk),
                          const SizedBox(width: 10),
                          Text(actions[i].label,
                              style: TextStyle(
                                fontSize: CareText.md,
                                color: actions[i].destructive ? kDangerText : kInk,
                              )),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The whole screen: header, totals, filter, list, and a create button.
class AdminSectionScaffold extends StatelessWidget {
  final String title;
  final bool isLoading;
  final String? error;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Future<void> Function() onRefresh;
  final Widget? header;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptyMessage;
  final String? createLabel;
  final VoidCallback? onCreate;

  const AdminSectionScaffold({
    super.key,
    required this.title,
    required this.isLoading,
    required this.error,
    required this.itemCount,
    required this.itemBuilder,
    required this.onRefresh,
    this.header,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptyMessage,
    this.createLabel,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, title),
      floatingActionButton: onCreate == null
          ? null
          : FloatingActionButton.extended(
              onPressed: onCreate,
              backgroundColor: kCareDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(createLabel ?? 'Add'),
            ),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: onRefresh,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (isLoading && itemCount == 0 && header == null) return const CareStateView.loading();
    if (error != null && itemCount == 0) return CareStateView.error(error!);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        if (header != null) header!,
        if (itemCount == 0)
          CareStateView.inline(icon: emptyIcon, title: emptyTitle, message: emptyMessage)
        else
          for (var i = 0; i < itemCount; i++) Builder(builder: (context) => itemBuilder(context, i)),
      ],
    );
  }
}
