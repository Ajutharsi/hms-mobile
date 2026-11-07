import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/hospital_settings.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/admin_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

enum AdminReportKind { patients, billing, inventory }

typedef ReportPayload = ({
  AdminReportKind kind,
  Map<String, num> totals,
  List<AdminPatientReportRow> patients,
  List<AdminBillingReportRow> invoices,
  List<AdminInventoryReportRow> drugs,
});

class AdminReportsViewModel extends AdminSectionViewModel<ReportPayload> {
  AdminReportKind kind = AdminReportKind.patients;

  @override
  Future<ReportPayload> fetch(String token) async {
    switch (kind) {
      case AdminReportKind.patients:
        final r = await api.patientReport(token);
        return (kind: kind, totals: r.totals, patients: r.rows,
            invoices: const <AdminBillingReportRow>[], drugs: const <AdminInventoryReportRow>[]);
      case AdminReportKind.billing:
        final r = await api.billingReport(token);
        return (kind: kind, totals: r.totals, patients: const <AdminPatientReportRow>[],
            invoices: r.rows, drugs: const <AdminInventoryReportRow>[]);
      case AdminReportKind.inventory:
        final r = await api.inventoryReport(token);
        return (kind: kind, totals: r.totals, patients: const <AdminPatientReportRow>[],
            invoices: const <AdminBillingReportRow>[], drugs: r.rows);
    }
  }

  void setKind(AdminReportKind value) {
    kind = value;
    load();
  }
}

/// The three reports the web has, on one screen with a switch.
///
/// Each is capped at 500 rows by the API. A phone is not where anyone
/// reads nine hundred invoices — this is for checking a figure, and the
/// web keeps the PDF export for everything else.
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminReportsViewModel(),
        child: const CareTheme(child: _ReportsView()),
      );
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  String _money(num? v) => money((v ?? 0));

  List<AdminStat> _stats(ReportPayload data) => switch (data.kind) {
        AdminReportKind.patients => [
            AdminStat(value: '${data.totals['total']?.toInt() ?? data.patients.length}', label: 'Patients'),
          ],
        AdminReportKind.billing => [
            AdminStat(value: _money(data.totals['amount']), label: 'Billed'),
            AdminStat(value: _money(data.totals['paid']), label: 'Collected', color: kSuccessFg),
            AdminStat(value: _money(data.totals['balance']), label: 'Outstanding', color: kWarnText),
          ],
        AdminReportKind.inventory => [
            AdminStat(value: '${data.totals['drugs']?.toInt() ?? 0}', label: 'Drugs'),
            AdminStat(value: '${data.totals['low_stock']?.toInt() ?? 0}', label: 'Low stock', color: kWarnText),
            AdminStat(value: _money(data.totals['stock_value']), label: 'Stock value'),
          ],
      };

  int _count(ReportPayload? d) => switch (d?.kind) {
        AdminReportKind.patients => d!.patients.length,
        AdminReportKind.billing => d!.invoices.length,
        AdminReportKind.inventory => d!.drugs.length,
        null => 0,
      };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminReportsViewModel>();
    final data = viewModel.data;

    return AdminSectionScaffold(
      title: 'Reports',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: _count(data),
      onRefresh: viewModel.load,
      emptyIcon: Icons.insert_chart_outlined_rounded,
      emptyTitle: 'Nothing to report',
      emptyMessage: 'No rows match for this period.',
      header: Column(
        children: [
          if (data != null) AdminStatRow(stats: _stats(data)),
          AdminFilterChips(
            value: viewModel.kind.name,
            onChanged: (v) => viewModel.setKind(AdminReportKind.values.byName(v)),
            options: const [
              (value: 'patients', label: 'Patients'),
              (value: 'billing', label: 'Billing'),
              (value: 'inventory', label: 'Inventory'),
            ],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Up to 500 rows. The web has the full export.',
                    style: CareText.mutedXs,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      itemBuilder: (context, i) => switch (data!.kind) {
        AdminReportKind.patients => _patientRow(data.patients[i]),
        AdminReportKind.billing => _invoiceRow(data.invoices[i]),
        AdminReportKind.inventory => _drugRow(data.drugs[i]),
      },
    );
  }

  Widget _patientRow(AdminPatientReportRow p) => AdminCard(
        title: p.name,
        subtitle: [p.mrn, p.gender].where((s) => s != null && s.isNotEmpty).join(' · '),
        detail: 'Registered ${p.registeredOn ?? '—'}',
        badge: p.patientType?.toUpperCase(),
      );

  Widget _invoiceRow(AdminBillingReportRow inv) {
    final unpaid = inv.balance > 0;
    return AdminCard(
      title: inv.patientName ?? inv.invoiceNo ?? 'Invoice',
      subtitle: [inv.invoiceNo, inv.invoiceDate].where((s) => s != null && s.isNotEmpty).join(' · '),
      detail: 'Billed ${money(inv.total)} · paid ${money(inv.paid)}'
          '${unpaid ? ' · due ${money(inv.balance)}' : ''}',
      badge: inv.status,
      badgeColor: unpaid ? kWarnText : kSuccessFg,
      badgeBg: unpaid ? kWarnSurface : kSuccessBg,
    );
  }

  Widget _drugRow(AdminInventoryReportRow d) {
    final low = d.currentStock <= d.minStockLevel;
    return AdminCard(
      title: d.drugName,
      subtitle: d.category,
      detail: '${d.currentStock} in stock · reorder at ${d.minStockLevel} · ${money(d.unitPrice, decimals: 2)}'
          '${d.expiryDate != null ? ' · exp ${d.expiryDate}' : ''}',
      badge: low ? 'low' : null,
      badgeColor: kWarnText,
      badgeBg: kWarnSurface,
    );
  }
}
