import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/hospital_settings.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/admin_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

typedef PurchaseOrdersPayload = ({List<AdminPurchaseOrder> orders, Map<String, num> totals});

class AdminPurchaseOrdersViewModel extends AdminSectionViewModel<PurchaseOrdersPayload> {
  String status = '';

  @override
  Future<PurchaseOrdersPayload> fetch(String token) => api.purchaseOrders(token, status: status);

  void setStatus(String value) {
    status = value;
    load();
  }
}

/// Purchase orders, and the one action worth having on a phone: marking a
/// delivery received, which raises the stock of every line on it.
///
/// Raising an order means picking items and quantities, which is a real
/// form and belongs on the web. The screen says so rather than offering a
/// button that cannot work.
class AdminPurchaseOrdersScreen extends StatelessWidget {
  const AdminPurchaseOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminPurchaseOrdersViewModel(),
        child: const CareTheme(child: _PurchaseOrdersView()),
      );
}

class _PurchaseOrdersView extends StatelessWidget {
  const _PurchaseOrdersView();

  Future<void> _receive(BuildContext context, AdminPurchaseOrdersViewModel viewModel, AdminPurchaseOrder po) async {
    final yes = await careConfirm(
      context,
      title: 'Mark ${po.poNo ?? 'this order'} received?',
      message: 'Stock goes up by the quantity on each of its ${po.itemCount} line'
          '${po.itemCount == 1 ? '' : 's'}. This cannot be undone from here.',
      confirmLabel: 'Mark received',
    );
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.purchaseOrderReceive(token, po.id));
    if (context.mounted) careSnack(context, error ?? 'Received — stock updated.', isError: error != null);
  }

  Future<void> _delete(BuildContext context, AdminPurchaseOrdersViewModel viewModel, AdminPurchaseOrder po) async {
    final yes = await careConfirm(context,
        title: 'Delete ${po.poNo ?? 'this order'}?', message: 'Its lines go with it. Stock is not affected.');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.purchaseOrderDestroy(token, po.id));
    if (context.mounted) careSnack(context, error ?? 'Purchase order deleted.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminPurchaseOrdersViewModel>();
    final orders = viewModel.data?.orders ?? const <AdminPurchaseOrder>[];
    final totals = viewModel.data?.totals ?? const <String, num>{};

    return AdminSectionScaffold(
      title: 'Purchase Orders',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: orders.length,
      onRefresh: viewModel.load,
      emptyIcon: Icons.receipt_long_outlined,
      emptyTitle: 'No purchase orders',
      emptyMessage: 'Raise one on the web, then mark it received here when the delivery arrives.',
      header: Column(
        children: [
          AdminStatRow(stats: [
            AdminStat(value: '${totals['draft']?.toInt() ?? 0}', label: 'Awaiting', color: kWarnText),
            AdminStat(value: '${totals['received']?.toInt() ?? 0}', label: 'Received', color: kSuccessFg),
            AdminStat(value: money((totals['value'] ?? 0)), label: 'Value'),
          ]),
          AdminFilterChips(
            value: viewModel.status,
            onChanged: viewModel.setStatus,
            options: const [
              (value: '', label: 'All'),
              (value: 'draft', label: 'Awaiting delivery'),
              (value: 'received', label: 'Received'),
            ],
          ),
        ],
      ),
      itemBuilder: (context, i) {
        final po = orders[i];
        return AdminCard(
          title: po.poNo ?? 'Purchase order',
          subtitle: po.supplier,
          detail: [
            '${po.itemCount} line${po.itemCount == 1 ? '' : 's'} · ${money(po.totalAmount)}',
            if (po.isReceived) 'Received ${po.receivedDate}' else 'Expected ${po.expectedDate ?? '—'}',
          ].join('\n'),
          badge: po.status,
          badgeColor: po.isReceived ? kSuccessFg : kWarnText,
          badgeBg: po.isReceived ? kSuccessBg : kWarnSurface,
          actions: po.isReceived
              ? const []
              : [
                  (label: 'Mark received', icon: Icons.inventory_rounded, onTap: () => _receive(context, viewModel, po), destructive: false),
                  (label: 'Delete', icon: Icons.delete_outline, onTap: () => _delete(context, viewModel, po), destructive: true),
                ],
        );
      },
    );
  }
}
