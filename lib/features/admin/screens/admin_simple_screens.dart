import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/admin_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

/// The admin sections that are a list and nothing more: the staff roster,
/// the activity log, the notification log, and the billing service
/// catalogue. Each is short enough that a file of its own would be mostly
/// imports.

// --------------------------------------------------------------- staff

typedef StaffPayload = ({List<AdminUser> staff, Map<String, int> byRole});

class AdminStaffViewModel extends AdminSectionViewModel<StaffPayload> {
  String role = '';

  @override
  Future<StaffPayload> fetch(String token) => api.staff(token, role: role);

  void setRole(String value) {
    role = value;
    load();
  }
}

class AdminStaffScreen extends StatelessWidget {
  const AdminStaffScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminStaffViewModel(),
        child: const CareTheme(child: _StaffView()),
      );
}

class _StaffView extends StatelessWidget {
  const _StaffView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminStaffViewModel>();
    final staff = viewModel.data?.staff ?? const <AdminUser>[];
    final byRole = viewModel.data?.byRole ?? const <String, int>{};

    return AdminSectionScaffold(
      title: 'Staff',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: staff.length,
      onRefresh: viewModel.load,
      emptyIcon: Icons.groups_outlined,
      emptyTitle: 'No staff match',
      emptyMessage: 'Accounts are created under User Management.',
      header: AdminFilterChips(
        value: viewModel.role,
        onChanged: viewModel.setRole,
        options: [
          (value: '', label: 'Everyone'),
          for (final role in byRole.keys) (value: role, label: '${role.replaceAll('_', ' ')} (${byRole[role]})'),
        ],
      ),
      itemBuilder: (context, i) => AdminCard(
        title: staff[i].name,
        subtitle: staff[i].email,
        detail: staff[i].phone,
        badge: staff[i].role?.replaceAll('_', ' '),
      ),
    );
  }
}

// -------------------------------------------------------- activity log

typedef ActivityPayload = ({List<AdminActivityEntry> logs, List<String> modules});

class AdminActivityViewModel extends AdminSectionViewModel<ActivityPayload> {
  String module = '';

  @override
  Future<ActivityPayload> fetch(String token) => api.activityLog(token, module: module);

  void setModule(String value) {
    module = value;
    load();
  }
}

class AdminActivityLogScreen extends StatelessWidget {
  const AdminActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminActivityViewModel(),
        child: const CareTheme(child: _ActivityView()),
      );
}

class _ActivityView extends StatelessWidget {
  const _ActivityView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminActivityViewModel>();
    final logs = viewModel.data?.logs ?? const <AdminActivityEntry>[];
    final modules = viewModel.data?.modules ?? const <String>[];

    return AdminSectionScaffold(
      title: 'Activity Log',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: logs.length,
      onRefresh: viewModel.load,
      emptyIcon: Icons.history_rounded,
      emptyTitle: 'Nothing logged yet',
      emptyMessage: 'Changes people make across the hospital are recorded here.',
      header: AdminFilterChips(
        value: viewModel.module,
        onChanged: viewModel.setModule,
        options: [
          (value: '', label: 'All modules'),
          for (final m in modules) (value: m, label: m),
        ],
      ),
      itemBuilder: (context, i) {
        final entry = logs[i];
        return AdminCard(
          title: entry.description ?? '${entry.action} ${entry.module}',
          subtitle: [entry.userName, entry.module].where((s) => s != null && s.isNotEmpty).join(' · '),
          detail: [entry.at, entry.ipAddress].where((s) => s != null && s.isNotEmpty).join(' · '),
          badge: entry.action,
        );
      },
    );
  }
}

// ------------------------------------------------------- notifications

typedef NotificationsPayload = ({List<AdminNotificationEntry> logs, Map<String, int> totals});

class AdminNotificationsViewModel extends AdminSectionViewModel<NotificationsPayload> {
  String status = '';

  @override
  Future<NotificationsPayload> fetch(String token) => api.notifications(token, status: status);

  void setStatus(String value) {
    status = value;
    load();
  }
}

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminNotificationsViewModel(),
        child: const CareTheme(child: _NotificationsView()),
      );
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminNotificationsViewModel>();
    final logs = viewModel.data?.logs ?? const <AdminNotificationEntry>[];
    final totals = viewModel.data?.totals ?? const <String, int>{};

    return AdminSectionScaffold(
      title: 'Notifications',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: logs.length,
      onRefresh: viewModel.load,
      emptyIcon: Icons.notifications_none_rounded,
      emptyTitle: 'Nothing sent yet',
      emptyMessage: 'Reminders and alerts the hospital sends out are listed here.',
      header: Column(
        children: [
          AdminStatRow(stats: [
            AdminStat(value: '${totals['sent'] ?? 0}', label: 'Sent', color: kSuccessFg),
            AdminStat(value: '${totals['failed'] ?? 0}', label: 'Failed', color: kDangerFg),
          ]),
          AdminFilterChips(
            value: viewModel.status,
            onChanged: viewModel.setStatus,
            options: const [
              (value: '', label: 'All'),
              (value: 'sent', label: 'Sent'),
              (value: 'failed', label: 'Failed'),
            ],
          ),
        ],
      ),
      itemBuilder: (context, i) {
        final entry = logs[i];
        final failed = entry.status == 'failed';
        return AdminCard(
          title: entry.recipient ?? '—',
          subtitle: [entry.channel, entry.template].where((s) => s != null && s.isNotEmpty).join(' · '),
          detail: failed ? entry.errorMessage : entry.sentAt,
          badge: entry.status,
          badgeColor: failed ? kDangerFg : kSuccessFg,
          badgeBg: failed ? kDangerBg : kSuccessBg,
        );
      },
    );
  }
}

// ----------------------------------------------- notification templates

class AdminTemplatesViewModel extends AdminSectionViewModel<List<AdminTemplate>> {
  @override
  Future<List<AdminTemplate>> fetch(String token) => api.templates(token);
}

/// The message bodies the hospital sends from -- the web's
/// Notification Templates page.
///
/// Templates were the one half of notifications the app could not reach:
/// the log of what went out was already here, but nothing could read or
/// change the wording behind it.
class AdminNotificationTemplatesScreen extends StatelessWidget {
  const AdminNotificationTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminTemplatesViewModel(),
        child: const CareTheme(child: _TemplatesView()),
      );
}

class _TemplatesView extends StatelessWidget {
  const _TemplatesView();

  Future<void> _addOrEdit(BuildContext context, AdminTemplatesViewModel viewModel, [AdminTemplate? template]) async {
    final values = await careFormSheet(
      context,
      title: template == null ? 'Add template' : 'Edit ${template.name}',
      fields: [
        CareFormField('name', 'Internal name', initial: template?.name, required: true, icon: Icons.label_outline),
        CareFormField('title', 'Title', initial: template?.title, required: true, icon: Icons.title_rounded),
        CareFormField('sms_template', 'SMS text', initial: template?.sms, maxLines: 3, icon: Icons.sms_outlined),
        CareFormField('whatsapp_template', 'WhatsApp text', initial: template?.whatsapp, maxLines: 3, icon: Icons.chat_outlined),
        CareFormField('email_template', 'Email body', initial: template?.email, maxLines: 5, icon: Icons.mail_outline),
        CareFormField('is_active', 'Status',
            initial: (template?.isActive ?? true) ? 'Active' : 'Paused',
            options: const ['Active', 'Paused'],
            icon: Icons.toggle_on_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    // The sheet hands back the label; the API wants the flag.
    values['is_active'] = values['is_active'] == 'Paused' ? '0' : '1';

    final error = await viewModel.mutate((api, token) =>
        template == null ? api.templateStore(token, values) : api.templateUpdate(token, template.id, values));
    if (context.mounted) {
      careSnack(context, error ?? (template == null ? 'Template added.' : 'Template updated.'), isError: error != null);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminTemplatesViewModel>();
    final templates = viewModel.data ?? const <AdminTemplate>[];

    return AdminSectionScaffold(
      title: 'Notification Templates',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: templates.length,
      onRefresh: viewModel.load,
      emptyIcon: Icons.mark_email_unread_outlined,
      emptyTitle: 'No templates yet',
      emptyMessage: 'Add one and the hospital can send it as SMS, WhatsApp or email.',
      createLabel: 'Add template',
      onCreate: () => _addOrEdit(context, viewModel),
      itemBuilder: (context, i) {
        final template = templates[i];
        // Which channels this template can actually go out on.
        final channels = [
          if ((template.sms ?? '').isNotEmpty) 'SMS',
          if ((template.whatsapp ?? '').isNotEmpty) 'WhatsApp',
          if ((template.email ?? '').isNotEmpty) 'Email',
        ];

        return AdminCard(
          title: template.title?.isNotEmpty == true ? template.title! : template.name,
          subtitle: template.name,
          detail: channels.isEmpty ? 'No channel filled in yet' : channels.join(' · '),
          badge: template.isActive ? 'active' : 'paused',
          badgeColor: template.isActive ? kSuccessFg : kMuted,
          badgeBg: template.isActive ? kSuccessBg : kCareNeutralBg,
          onTap: () => _addOrEdit(context, viewModel, template),
          actions: [
            (label: 'Edit', icon: Icons.edit_outlined, onTap: () => _addOrEdit(context, viewModel, template), destructive: false),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------ services

typedef ServicesPayload = ({List<AdminService> services, List<String> categories});

class AdminServicesViewModel extends AdminSectionViewModel<ServicesPayload> {
  String category = '';

  @override
  Future<ServicesPayload> fetch(String token) => api.services(token, category: category);

  void setCategory(String value) {
    category = value;
    load();
  }
}

class AdminServicesScreen extends StatelessWidget {
  const AdminServicesScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminServicesViewModel(),
        child: const CareTheme(child: _ServicesView()),
      );
}

class _ServicesView extends StatelessWidget {
  const _ServicesView();

  Future<void> _addOrEdit(BuildContext context, AdminServicesViewModel viewModel, [AdminService? service]) async {
    final values = await careFormSheet(
      context,
      title: service == null ? 'Add service' : 'Edit ${service.serviceName}',
      fields: [
        CareFormField('service_name', 'Service name', initial: service?.serviceName, required: true, icon: Icons.local_offer_outlined),
        CareFormField('category', 'Category', initial: service?.category, required: true, icon: Icons.category_outlined),
        CareFormField('price', 'Price', initial: service?.price.toStringAsFixed(2), required: true,
            keyboard: TextInputType.number, icon: Icons.payments_outlined),
        CareFormField('description', 'Description', initial: service?.description, maxLines: 3, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) =>
        service == null ? api.serviceStore(token, values) : api.serviceUpdate(token, service.id, values));
    if (context.mounted) {
      careSnack(context, error ?? (service == null ? 'Service added.' : 'Service updated.'), isError: error != null);
    }
  }

  Future<void> _delete(BuildContext context, AdminServicesViewModel viewModel, AdminService service) async {
    final yes = await careConfirm(context,
        title: 'Remove ${service.serviceName}?',
        message: 'Invoices already raised with it keep their line and their price.');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.serviceDestroy(token, service.id));
    if (context.mounted) careSnack(context, error ?? 'Service removed.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminServicesViewModel>();
    final services = viewModel.data?.services ?? const <AdminService>[];
    final categories = viewModel.data?.categories ?? const <String>[];

    return AdminSectionScaffold(
      title: 'Billing Services',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: services.length,
      onRefresh: viewModel.load,
      createLabel: 'Add service',
      onCreate: () => _addOrEdit(context, viewModel),
      emptyIcon: Icons.local_offer_outlined,
      emptyTitle: 'No services in the catalogue',
      emptyMessage: 'What you add here is what the front desk can put on an invoice.',
      header: AdminFilterChips(
        value: viewModel.category,
        onChanged: viewModel.setCategory,
        options: [
          (value: '', label: 'All'),
          for (final c in categories) (value: c, label: c),
        ],
      ),
      itemBuilder: (context, i) {
        final service = services[i];
        return AdminCard(
          title: service.serviceName,
          subtitle: service.category,
          detail: service.description,
          badge: '₹${service.price.toStringAsFixed(0)}',
          onTap: () => _addOrEdit(context, viewModel, service),
          actions: [
            (label: 'Edit', icon: Icons.edit_outlined, onTap: () => _addOrEdit(context, viewModel, service), destructive: false),
            (label: 'Remove', icon: Icons.delete_outline, onTap: () => _delete(context, viewModel, service), destructive: true),
          ],
        );
      },
    );
  }
}
