import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/admin_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

typedef SettingsPayload = ({AdminSettings? settings, List<AdminDepartment> departments});

class AdminSettingsViewModel extends AdminSectionViewModel<SettingsPayload> {
  @override
  Future<SettingsPayload> fetch(String token) async {
    // Two calls, one screen: the hospital's own details and the
    // departments that hang off them are edited in the same sitting.
    final settings = await api.settings(token);
    final departments = await api.departments(token);
    return (settings: settings, departments: departments);
  }
}

/// Hospital details and the department list.
///
/// A hospital can have no settings row yet — the web's form creates one on
/// first save and so does the API, so this screen shows the form either
/// way rather than an error.
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminSettingsViewModel(),
        child: const CareTheme(child: _SettingsView()),
      );
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  Future<void> _editHospital(BuildContext context, AdminSettingsViewModel viewModel, AdminSettings? s) async {
    final values = await careFormSheet(
      context,
      title: s == null ? 'Set up this hospital' : 'Hospital details',
      fields: [
        CareFormField('hospital_name', 'Hospital name', initial: s?.hospitalName, required: true, icon: Icons.local_hospital_outlined),
        CareFormField('address', 'Address', initial: s?.address, maxLines: 2, icon: Icons.place_outlined),
        CareFormField('city', 'City', initial: s?.city, icon: Icons.location_city_outlined),
        CareFormField('phone', 'Phone', initial: s?.phone, keyboard: TextInputType.phone, icon: Icons.phone_outlined),
        CareFormField('email', 'Email', initial: s?.email, keyboard: TextInputType.emailAddress, icon: Icons.mail_outline),
        CareFormField('website', 'Website', initial: s?.website, icon: Icons.language_outlined),
        CareFormField('low_stock_threshold', 'Low stock threshold', initial: '${s?.lowStockThreshold ?? 10}',
            keyboard: TextInputType.number, icon: Icons.warning_amber_outlined),
        CareFormField('near_expiry_days', 'Near expiry (days)', initial: '${s?.nearExpiryDays ?? 30}',
            keyboard: TextInputType.number, icon: Icons.event_busy_outlined),
        CareFormField('round_alert_hours', 'Round alert (hours)', initial: '${s?.roundAlertHours ?? 4}',
            keyboard: TextInputType.number, icon: Icons.alarm_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.updateSettings(token, values));
    if (context.mounted) careSnack(context, error ?? 'Settings saved.', isError: error != null);
  }

  Future<void> _editDepartment(BuildContext context, AdminSettingsViewModel viewModel, [AdminDepartment? d]) async {
    final values = await careFormSheet(
      context,
      title: d == null ? 'Add department' : 'Edit ${d.name}',
      fields: [
        CareFormField('name', 'Name', initial: d?.name, required: true, icon: Icons.apartment_outlined),
        CareFormField('code', 'Code', initial: d?.code, icon: Icons.tag_outlined),
        CareFormField('description', 'Description', initial: d?.description, maxLines: 2, icon: Icons.notes_outlined),
        CareFormField('status', 'Status', initial: d?.status ?? 'active', options: const ['active', 'inactive'], icon: Icons.toggle_on_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) =>
        d == null ? api.departmentStore(token, values) : api.departmentUpdate(token, d.id, values));
    if (context.mounted) {
      careSnack(context, error ?? (d == null ? 'Department added.' : 'Department updated.'), isError: error != null);
    }
  }

  Future<void> _deleteDepartment(BuildContext context, AdminSettingsViewModel viewModel, AdminDepartment d) async {
    final yes = await careConfirm(context,
        title: 'Remove ${d.name}?', message: 'Doctors assigned to it keep the name on their record.');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.departmentDestroy(token, d.id));
    if (context.mounted) careSnack(context, error ?? 'Department removed.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminSettingsViewModel>();
    final settings = viewModel.data?.settings;
    final departments = viewModel.data?.departments ?? const <AdminDepartment>[];

    return AdminSectionScaffold(
      title: 'Settings',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: departments.length,
      onRefresh: viewModel.load,
      createLabel: 'Add department',
      onCreate: () => _editDepartment(context, viewModel),
      emptyIcon: Icons.apartment_outlined,
      emptyTitle: 'No departments yet',
      emptyMessage: 'Departments group doctors and show up on appointment forms.',
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: CareCard(
              onTap: () => _editHospital(context, viewModel, settings),
              child: Row(
                children: [
                  const CareIconBox(icon: Icons.local_hospital_rounded, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(settings?.hospitalName.isNotEmpty == true ? settings!.hospitalName : 'Set up this hospital',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleMd),
                        const SizedBox(height: 2),
                        Text(
                          settings == null
                              ? 'Name, contact details and thresholds'
                              : [settings.city, settings.phone].where((s) => s != null && s.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CareText.mutedSm,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: kCareChevron),
                ],
              ),
            ),
          ),
          if (settings != null)
            AdminStatRow(stats: [
              AdminStat(value: '${settings.lowStockThreshold}', label: 'Low stock at'),
              AdminStat(value: '${settings.nearExpiryDays}d', label: 'Near expiry'),
              AdminStat(value: '${settings.roundAlertHours}h', label: 'Round alert'),
            ]),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Departments', style: CareText.titleH3),
          ),
        ],
      ),
      itemBuilder: (context, i) {
        final d = departments[i];
        final inactive = d.status == 'inactive';
        return AdminCard(
          title: d.name,
          subtitle: d.code,
          detail: d.description,
          badge: inactive ? 'inactive' : null,
          badgeColor: kMuted,
          badgeBg: kCareNeutralBg,
          onTap: () => _editDepartment(context, viewModel, d),
          actions: [
            (label: 'Edit', icon: Icons.edit_outlined, onTap: () => _editDepartment(context, viewModel, d), destructive: false),
            (label: 'Remove', icon: Icons.delete_outline, onTap: () => _deleteDepartment(context, viewModel, d), destructive: true),
          ],
        );
      },
    );
  }
}
