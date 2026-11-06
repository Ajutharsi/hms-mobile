import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/admin_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

typedef SuppliersPayload = ({Map<String, int> stats, List<AdminSupplier> suppliers});

class AdminSuppliersViewModel extends AdminSectionViewModel<SuppliersPayload> {
  @override
  Future<SuppliersPayload> fetch(String token) => api.suppliers(token);
}

/// The vendor master behind purchase orders.
///
/// Orders carry the supplier as free text, so the same vendor turns up
/// spelled three ways and nobody can see what has been ordered from one
/// of them. Each row here shows that total.
class AdminSuppliersScreen extends StatelessWidget {
  const AdminSuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminSuppliersViewModel(),
        child: const CareTheme(child: _SuppliersView()),
      );
}

class _SuppliersView extends StatelessWidget {
  const _SuppliersView();

  Future<void> _addOrEdit(BuildContext context, AdminSuppliersViewModel viewModel, [AdminSupplier? supplier]) async {
    final values = await careFormSheet(
      context,
      title: supplier == null ? 'Add supplier' : 'Edit ${supplier.name}',
      fields: [
        CareFormField('name', 'Supplier name', initial: supplier?.name, required: true, icon: Icons.store_outlined),
        CareFormField('contact_person', 'Contact person', initial: supplier?.contactPerson, icon: Icons.person_outline),
        CareFormField('phone', 'Phone',
            initial: supplier?.phone, keyboard: TextInputType.phone, icon: Icons.phone_outlined),
        CareFormField('email', 'Email',
            initial: supplier?.email, keyboard: TextInputType.emailAddress, icon: Icons.mail_outline),
        CareFormField('gst_no', 'GST number', initial: supplier?.gstNo, icon: Icons.receipt_long_outlined),
        CareFormField('payment_terms', 'Payment terms', initial: supplier?.paymentTerms, icon: Icons.schedule_outlined),
        CareFormField('address', 'Address', initial: supplier?.address, maxLines: 2, icon: Icons.location_on_outlined),
        CareFormField('status', 'Status',
            initial: supplier?.status, options: const ['active', 'inactive'], icon: Icons.toggle_on_outlined),
        CareFormField('notes', 'Notes', initial: supplier?.notes, maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) =>
        supplier == null ? api.supplierStore(token, values) : api.supplierUpdate(token, supplier.id, values));
    if (context.mounted) {
      careSnack(context, error ?? (supplier == null ? 'Supplier added.' : 'Supplier updated.'), isError: error != null);
    }
  }

  Future<void> _delete(BuildContext context, AdminSuppliersViewModel viewModel, AdminSupplier supplier) async {
    final yes = await careConfirm(context,
        title: 'Remove ${supplier.name}?',
        message: 'A supplier with purchase orders cannot be removed. Mark it inactive instead.',
        confirmLabel: 'Remove');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.supplierDestroy(token, supplier.id));
    if (context.mounted) careSnack(context, error ?? 'Supplier removed.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminSuppliersViewModel>();
    final suppliers = viewModel.data?.suppliers ?? const <AdminSupplier>[];
    final stats = viewModel.data?.stats ?? const <String, int>{};

    return AdminSectionScaffold(
      title: 'Suppliers',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: suppliers.length,
      onRefresh: viewModel.load,
      emptyIcon: Icons.local_shipping_outlined,
      emptyTitle: 'No suppliers yet',
      emptyMessage: 'Add the vendors the hospital buys stock from.',
      createLabel: 'Add supplier',
      onCreate: () => _addOrEdit(context, viewModel),
      header: AdminStatRow(stats: [
        AdminStat(value: '${stats['suppliers'] ?? 0}', label: 'Suppliers'),
        AdminStat(value: '${stats['active'] ?? 0}', label: 'Active', color: kSuccessFg),
      ]),
      itemBuilder: (context, i) {
        final supplier = suppliers[i];

        return AdminCard(
          title: supplier.name,
          subtitle: supplier.contact.isEmpty ? supplier.email : supplier.contact,
          detail: supplier.orders == 0
              ? 'No orders yet'
              : '${supplier.orders} order${supplier.orders == 1 ? '' : 's'} · ₹${supplier.spend.toStringAsFixed(0)}',
          badge: supplier.status,
          badgeColor: supplier.status == 'active' ? kSuccessFg : kMuted,
          badgeBg: supplier.status == 'active' ? kSuccessBg : kCareNeutralBg,
          onTap: () => _addOrEdit(context, viewModel, supplier),
          actions: [
            (label: 'Edit', icon: Icons.edit_outlined, onTap: () => _addOrEdit(context, viewModel, supplier), destructive: false),
            (label: 'Remove', icon: Icons.delete_outline, onTap: () => _delete(context, viewModel, supplier), destructive: true),
          ],
        );
      },
    );
  }
}
