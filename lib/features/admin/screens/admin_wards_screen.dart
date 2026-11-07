import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/hospital_settings.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/admin_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

typedef WardsPayload = ({Map<String, int> stats, List<AdminWard> wards});

class AdminWardsViewModel extends AdminSectionViewModel<WardsPayload> {
  @override
  Future<WardsPayload> fetch(String token) => api.wards(token);
}

/// Wards and beds for the administrator.
///
/// The app could already show a ward and admit into it; creating one,
/// renaming it, changing the nightly charge or adding a bed was a
/// web-only job. Tapping a ward opens its beds.
class AdminWardsScreen extends StatelessWidget {
  const AdminWardsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminWardsViewModel(),
        child: const CareTheme(child: _WardsView()),
      );
}

class _WardsView extends StatelessWidget {
  const _WardsView();

  Future<void> _addOrEdit(BuildContext context, AdminWardsViewModel viewModel, [AdminWard? ward]) async {
    final values = await careFormSheet(
      context,
      title: ward == null ? 'Add ward' : 'Edit ${ward.name}',
      fields: [
        CareFormField('name', 'Ward name', initial: ward?.name, required: true, icon: Icons.holiday_village_outlined),
        CareFormField('type', 'Type',
            initial: ward?.type,
            options: const ['general', 'private', 'semi_private', 'icu', 'nicu', 'emergency'],
            icon: Icons.category_outlined),
        // Beds are created with the ward and added one at a time after,
        // so the count is only asked for once.
        if (ward == null)
          const CareFormField('total_beds', 'How many beds',
              required: true, keyboard: TextInputType.number, icon: Icons.bed_outlined),
        CareFormField('charge_per_day', 'Charge per day',
            initial: ward?.chargePerDay.toStringAsFixed(2),
            required: true,
            keyboard: TextInputType.number,
            icon: Icons.payments_outlined),
        CareFormField('floor', 'Floor', initial: ward?.floor, icon: Icons.stairs_outlined),
        CareFormField('building', 'Building', initial: ward?.building, icon: Icons.apartment_outlined),
        CareFormField('status', 'Status',
            initial: ward?.status, options: const ['active', 'inactive'], icon: Icons.toggle_on_outlined),
        CareFormField('description', 'Description', initial: ward?.description, maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) =>
        ward == null ? api.wardStore(token, values) : api.wardUpdate(token, ward.id, values));
    if (context.mounted) {
      careSnack(context, error ?? (ward == null ? 'Ward added.' : 'Ward updated.'), isError: error != null);
    }
  }

  Future<void> _delete(BuildContext context, AdminWardsViewModel viewModel, AdminWard ward) async {
    final yes = await careConfirm(context,
        title: 'Remove ${ward.name}?',
        message: 'Its beds go with it. A ward with patients in it cannot be removed.',
        confirmLabel: 'Remove');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.wardDestroy(token, ward.id));
    if (context.mounted) careSnack(context, error ?? 'Ward removed.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminWardsViewModel>();
    final wards = viewModel.data?.wards ?? const <AdminWard>[];
    final stats = viewModel.data?.stats ?? const <String, int>{};

    return AdminSectionScaffold(
      title: 'Wards & Beds',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: wards.length,
      onRefresh: viewModel.load,
      emptyIcon: Icons.holiday_village_outlined,
      emptyTitle: 'No wards yet',
      emptyMessage: 'Add a ward and its beds are created with it.',
      createLabel: 'Add ward',
      onCreate: () => _addOrEdit(context, viewModel),
      header: AdminStatRow(stats: [
        AdminStat(value: '${stats['wards'] ?? 0}', label: 'Wards'),
        AdminStat(value: '${stats['free'] ?? 0}', label: 'Free beds', color: kSuccessFg),
        AdminStat(value: '${stats['occupied'] ?? 0}', label: 'Occupied', color: kDangerFg),
      ]),
      itemBuilder: (context, i) {
        final ward = wards[i];
        final full = ward.availableBeds == 0 && ward.totalBeds > 0;

        return AdminCard(
          title: ward.name,
          subtitle: '${ward.wardNo} · ${ward.where}',
          detail: '${ward.availableBeds} free of ${ward.totalBeds} beds · ${money(ward.chargePerDay)}/day',
          badge: full ? 'full' : ward.status,
          badgeColor: full ? kDangerFg : (ward.status == 'active' ? kSuccessFg : kMuted),
          badgeBg: full ? kDangerBg : (ward.status == 'active' ? kSuccessBg : kCareNeutralBg),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AdminWardBedsScreen(wardId: ward.id, wardName: ward.name),
            ));
            if (context.mounted) viewModel.load();
          },
          actions: [
            (label: 'Edit', icon: Icons.edit_outlined, onTap: () => _addOrEdit(context, viewModel, ward), destructive: false),
            (label: 'Remove', icon: Icons.delete_outline, onTap: () => _delete(context, viewModel, ward), destructive: true),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------ beds

class AdminWardBedsViewModel extends AdminSectionViewModel<AdminWardDetail> {
  final int wardId;
  AdminWardBedsViewModel({required this.wardId});

  @override
  Future<AdminWardDetail> fetch(String token) => api.ward(token, wardId);
}

/// One ward's beds, with the patient in each occupied one.
class AdminWardBedsScreen extends StatelessWidget {
  final int wardId;
  final String wardName;

  const AdminWardBedsScreen({super.key, required this.wardId, required this.wardName});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminWardBedsViewModel(wardId: wardId),
        child: CareTheme(child: _BedsView(wardName: wardName)),
      );
}

class _BedsView extends StatelessWidget {
  final String wardName;
  const _BedsView({required this.wardName});

  Future<void> _add(BuildContext context, AdminWardBedsViewModel viewModel) async {
    final values = await careFormSheet(
      context,
      title: 'Add bed',
      fields: const [
        CareFormField('type', 'Type', options: ['standard', 'electric', 'icu', 'nicu'], icon: Icons.bed_outlined),
        CareFormField('status', 'Status',
            options: ['available', 'maintenance', 'reserved'], icon: Icons.toggle_on_outlined),
        // Left blank, the server numbers it after the ward.
        CareFormField('bed_no', 'Bed number (optional)', icon: Icons.tag_outlined),
        CareFormField('notes', 'Notes', maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.bedStore(token, viewModel.wardId, values));
    if (context.mounted) careSnack(context, error ?? 'Bed added.', isError: error != null);
  }

  Future<void> _edit(BuildContext context, AdminWardBedsViewModel viewModel, AdminBed bed) async {
    if (bed.isOccupied) {
      careSnack(context, '${bed.bedNo} has a patient in it.', isError: true);
      return;
    }

    final values = await careFormSheet(
      context,
      title: bed.bedNo,
      submitLabel: 'Update',
      fields: [
        CareFormField('type', 'Type',
            initial: bed.type, options: const ['standard', 'electric', 'icu', 'nicu'], icon: Icons.bed_outlined),
        CareFormField('status', 'Status',
            initial: bed.status,
            options: const ['available', 'maintenance', 'reserved'],
            icon: Icons.toggle_on_outlined),
        CareFormField('notes', 'Notes', initial: bed.notes, maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.bedUpdate(token, bed.id, values));
    if (context.mounted) careSnack(context, error ?? 'Bed updated.', isError: error != null);
  }

  Future<void> _delete(BuildContext context, AdminWardBedsViewModel viewModel, AdminBed bed) async {
    final yes = await careConfirm(context,
        title: 'Remove ${bed.bedNo}?',
        message: 'The bed disappears from this ward.',
        confirmLabel: 'Remove');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.bedDestroy(token, bed.id));
    if (context.mounted) careSnack(context, error ?? 'Bed removed.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminWardBedsViewModel>();
    final beds = viewModel.data?.beds ?? const <AdminBed>[];
    final occupied = beds.where((b) => b.isOccupied).length;

    return AdminSectionScaffold(
      title: wardName,
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: beds.length,
      onRefresh: viewModel.load,
      emptyIcon: Icons.bed_outlined,
      emptyTitle: 'No beds',
      emptyMessage: 'Add the first bed to this ward.',
      createLabel: 'Add bed',
      onCreate: () => _add(context, viewModel),
      header: AdminStatRow(stats: [
        AdminStat(value: '${beds.length}', label: 'Beds'),
        AdminStat(value: '${beds.length - occupied}', label: 'Free', color: kSuccessFg),
        AdminStat(value: '$occupied', label: 'Occupied', color: kDangerFg),
      ]),
      itemBuilder: (context, i) {
        final bed = beds[i];
        final (Color fg, Color bg) = switch (bed.status) {
          'occupied' => (kDangerFg, kDangerBg),
          'maintenance' => (kWarningFg, kWarningBg),
          'reserved' => (kInfoFg, kInfoBg),
          _ => (kSuccessFg, kSuccessBg),
        };

        return AdminCard(
          title: bed.bedNo,
          subtitle: bed.type,
          detail: bed.isOccupied ? bed.patientName : bed.notes,
          badge: bed.status,
          badgeColor: fg,
          badgeBg: bg,
          onTap: () => _edit(context, viewModel, bed),
          actions: bed.isOccupied
              ? const []
              : [
                  (label: 'Remove', icon: Icons.delete_outline, onTap: () => _delete(context, viewModel, bed), destructive: true),
                ],
        );
      },
    );
  }
}
