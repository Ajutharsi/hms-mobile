import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_forms.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/me/viewmodels/me_view_models.dart';

/// Every message the hospital has sent this person.
///
/// The admin's notification log answers "what did we send"; this is the
/// same rows seen from the other end, which nobody could do before. The
/// app does not receive push notifications yet, so these are messages
/// that went out by SMS, WhatsApp or email -- the inbox is where they
/// can be read back.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => InboxViewModel(),
        child: const CareTheme(child: _InboxView()),
      );
}

class _InboxView extends StatelessWidget {
  const _InboxView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<InboxViewModel>();
    final inbox = viewModel.inbox;

    return Scaffold(
      appBar: carePageAppBar(
        context,
        'Notifications',
        actions: [
          if ((inbox?.unread ?? 0) > 0)
            TextButton(
              onPressed: () async {
                final error = await viewModel.markAllRead();
                if (context.mounted && error != null) careSnack(context, error, isError: true);
              },
              child: const Text('Mark all read', style: CareText.onCare),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: switch ((viewModel.isLoading, viewModel.loadError, inbox)) {
          (true, _, null) => const CareStateView.loading(),
          (_, final String error, null) => CareStateView.error(error),
          (_, _, null) => const CareStateView.loading(),
          (_, _, final inbox) when inbox!.messages.isEmpty => const CareStateView(
              icon: Icons.notifications_none_rounded,
              title: 'Nothing yet',
              message: 'Appointment reminders and alerts the hospital sends you appear here.',
            ),
          (_, _, final inbox) => ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              itemCount: inbox!.messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final message = inbox.messages[i];

                return CareCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: message.read ? kCareNeutralBg : kCareSoft,
                          borderRadius: BorderRadius.circular(CareRadius.control),
                        ),
                        child: Icon(
                          switch (message.channel) {
                            'email' => Icons.mail_outline_rounded,
                            'whatsapp' => Icons.chat_outlined,
                            _ => Icons.sms_outlined,
                          },
                          size: 19,
                          color: message.read ? kMuted : kCare,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    message.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: message.read ? CareText.titleMdMedium : CareText.titleMd,
                                  ),
                                ),
                                // An unread dot rather than a chip: the
                                // list is read top to bottom, not scanned.
                                if (!message.read)
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(color: kCare, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(message.message, style: CareText.bodyMdMuted),
                            if ((message.sentAt ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('${message.channel} · ${message.sentAt}', style: CareText.mutedXs),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        },
      ),
    );
  }
}
