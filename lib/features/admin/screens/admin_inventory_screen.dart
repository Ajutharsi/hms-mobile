import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/admin_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

typedef InventoryPayload = ({List<AdminInventoryItem> items, Map<String, num> totals, List<String> categories});

class AdminInventoryViewModel extends AdminSectionViewModel<InventoryPayload> {
  bool lowStockOnly = false;

  @override
  Future<InventoryPayload> fetch(String token) => api.inventory(token, lowStockOnly: lowStockOnly);

  void setLowStockOnly(bool value) {
    lowStockOnly = value;
    load();
  }
}

/// Non-drug stock: gloves, linen, syringes. Medicines are the pharmacy's
/// Drug Master, which is a separate screen with its own dispensing rules.
class AdminInventoryScreen extends StatelessWidget {
  const AdminInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminInventoryViewModel(),
      child: const CareTheme(child: _InventoryView()),
    );
  }
}

class _InventoryView extends StatelessWidget {
  const _InventoryView();

  Future<void> _addOrEdit(BuildContext context, AdminInventoryViewModel viewModel, [AdminInventoryItem? item]) async {
    final values = await adminFormSheet(
      context,
      title: item == null ? 'Add item' : 'Edit ${item.itemName}',
      fields: [
        AdminField('item_name', 'Item name', initial: item?.itemName, required: true, icon: Icons.inventory_2_outlined),
        AdminField('category', 'Category', initial: item?.category, required: true, icon: Icons.category_outlined),
        AdminField('unit', 'Unit', initial: item?.unit ?? 'piece', required: true, icon: Icons.straighten_outlined),
        AdminField('unit_price', 'Unit price', initial: item?.unitPrice.toStringAsFixed(2),
            required: true, keyboard: TextInputType.number, icon: Icons.payments_outlined),
        AdminField('current_stock', 'Current stock', initial: '${item?.currentStock ?? 0}',
            keyboard: TextInputType.number, icon: Icons.numbers_outlined),
        AdminField('min_stock_level', 'Reorder level', initial: '${item?.minStockLevel ?? 0}',
            keyboard: TextInputType.number, icon: Icons.warning_amber_outlined),
        AdminField('supplier', 'Supplier', initial: item?.supplier, icon: Icons.local_shipping_outlined),
        AdminField('location', 'Location', initial: item?.location, icon: Icons.place_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) =>
        item == null ? api.inventoryStore(token, values) : api.inventoryUpdate(token, item.id, values));
    if (context.mounted) {
      adminSnack(context, error ?? (item == null ? 'Item added.' : 'Item updated.'), isError: error != null);
    }
  }

  Future<void> _delete(BuildContext context, AdminInventoryViewModel viewModel, AdminInventoryItem item) async {
    final yes = await adminConfirm(context,
        title: 'Remove ${item.itemName}?', message: 'Purchase orders that reference it keep their lines.');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.inventoryDestroy(token, item.id));
    if (context.mounted) adminSnack(context, error ?? 'Item removed.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminInventoryViewModel>();
    final items = viewModel.data?.items ?? const <AdminInventoryItem>[];
    final totals = viewModel.data?.totals ?? const <String, num>{};

    return AdminSectionScaffold(
      title: 'Inventory',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: items.length,
      onRefresh: viewModel.load,
      createLabel: 'Add item',
      onCreate: () => _addOrEdit(context, viewModel),
      emptyIcon: Icons.inventory_2_outlined,
      emptyTitle: viewModel.lowStockOnly ? 'Nothing is running low' : 'No stock items yet',
      emptyMessage: viewModel.lowStockOnly
          ? 'Everything is above its reorder level.'
          : 'Gloves, linen, syringes — anything that is not a medicine.',
      header: Column(
        children: [
          AdminStatRow(stats: [
            AdminStat(value: '${totals['items']?.toInt() ?? 0}', label: 'Items'),
            AdminStat(
              value: '${totals['low_stock']?.toInt() ?? 0}',
              label: 'Low stock',
              color: (totals['low_stock'] ?? 0) > 0 ? kWarnText : null,
            ),
            AdminStat(value: '₹${(totals['stock_value'] ?? 0).toStringAsFixed(0)}', label: 'Value'),
          ]),
          AdminFilterChips(
            value: viewModel.lowStockOnly ? 'low' : '',
            onChanged: (v) => viewModel.setLowStockOnly(v == 'low'),
            options: const [
              (value: '', label: 'All items'),
              (value: 'low', label: 'Low stock only'),
            ],
          ),
        ],
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return AdminCard(
          title: item.itemName,
          subtitle: [item.category, item.supplier].where((s) => s != null && s.isNotEmpty).join(' · '),
          detail: '${item.currentStock} ${item.unit ?? ''} · reorder at ${item.minStockLevel} · ₹${item.unitPrice.toStringAsFixed(2)}',
          badge: item.isLowStock ? 'low' : null,
          badgeColor: kWarnText,
          badgeBg: kWarnSurface,
          onTap: () => _addOrEdit(context, viewModel, item),
          actions: [
            (label: 'Edit', icon: Icons.edit_outlined, onTap: () => _addOrEdit(context, viewModel, item), destructive: false),
            (label: 'Remove', icon: Icons.delete_outline, onTap: () => _delete(context, viewModel, item), destructive: true),
          ],
        );
      },
    );
  }
}
