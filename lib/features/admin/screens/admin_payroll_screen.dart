import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/hospital_settings.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/ops_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

class AdminPayrollViewModel extends AdminSectionViewModel<PayrollRun> {
  /// YYYY-MM; null means this month.
  String? period;

  /// Hide the staff whose line has not been entered yet.
  bool onlyRun = false;

  @override
  Future<PayrollRun> fetch(String token) => api.payroll(token, period: period);

  void showPeriod(String value) {
    period = value;
    load();
  }

  void setOnlyRun(bool value) {
    if (onlyRun == value) return;
    onlyRun = value;
    notifyListeners();
  }
}

/// Salary, a month at a time.
///
/// There is no tax engine here on purpose: every hospital's slabs
/// differ and a wrong one is worse than none. The screen holds the
/// three numbers somebody works out, keeps the arithmetic honest and
/// records when it was paid. Attendance sits beside each line because
/// that is what a deduction usually argues with.
class AdminPayrollScreen extends StatelessWidget {
  const AdminPayrollScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminPayrollViewModel(),
        child: const CareTheme(child: _PayrollView()),
      );
}

class _PayrollView extends StatelessWidget {
  const _PayrollView();

  Future<void> _edit(BuildContext context, AdminPayrollViewModel viewModel, PayrollLine line) async {
    if (line.isPaid) {
      careSnack(context, 'That payslip is already paid.', isError: true);
      return;
    }

    final values = await careFormSheet(
      context,
      title: line.name,
      submitLabel: 'Save',
      fields: [
        CareFormField('basic', 'Basic',
            initial: line.basic == 0 ? null : line.basic.toStringAsFixed(2),
            required: true,
            keyboard: TextInputType.number,
            icon: Icons.payments_outlined),
        CareFormField('allowances', 'Allowances',
            initial: line.allowances == 0 ? null : line.allowances.toStringAsFixed(2),
            keyboard: TextInputType.number,
            icon: Icons.add_circle_outline),
        CareFormField('deductions', 'Deductions',
            initial: line.deductions == 0 ? null : line.deductions.toStringAsFixed(2),
            keyboard: TextInputType.number,
            icon: Icons.remove_circle_outline),
        const CareFormField('notes', 'Notes', maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.payrollSave(token, {
          ...values,
          'user_id': line.userId,
          'period': line.period,
        }));
    if (context.mounted) careSnack(context, error ?? 'Payroll line saved.', isError: error != null);
  }

  Future<void> _pay(BuildContext context, AdminPayrollViewModel viewModel, PayrollLine line) async {
    final values = await careFormSheet(
      context,
      title: 'Pay ${line.name}',
      submitLabel: 'Mark paid',
      fields: const [
        CareFormField('payment_mode', 'Paid by',
            options: ['bank_transfer', 'cash', 'cheque', 'upi'], icon: Icons.account_balance_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.payrollPay(token, line.payrollId!, values));
    if (context.mounted) careSnack(context, error ?? 'Marked paid.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminPayrollViewModel>();
    final run = viewModel.data;
    final lines = run == null
        ? const <PayrollLine>[]
        : (viewModel.onlyRun ? run.lines.where((l) => l.isRun).toList() : run.lines);

    return Scaffold(
      appBar: carePageAppBar(context, 'Payroll'),
      body: Column(
        children: [
          if (run != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: () => viewModel.showPeriod(_shiftMonth(run.period, -1)),
                    icon: Icon(Icons.chevron_left_rounded, color: kCare),
                  ),
                  Expanded(child: Text(run.period, textAlign: TextAlign.center, style: CareText.titleMd)),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: () => viewModel.showPeriod(_shiftMonth(run.period, 1)),
                    icon: Icon(Icons.chevron_right_rounded, color: kCare),
                  ),
                ],
              ),
            ),
          if (run != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: AdminStatRow(stats: [
                AdminStat(value: '${run.stats['run'] ?? 0}', label: 'Lines run'),
                AdminStat(value: '${run.stats['paid'] ?? 0}', label: 'Paid', color: kSuccessFg),
                AdminStat(value: money((run.stats['total_net'] ?? 0)), label: 'Net total'),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                CareChoicePill(
                  label: 'Run',
                  selected: viewModel.onlyRun,
                  onTap: () => viewModel.setOnlyRun(true),
                ),
                const SizedBox(width: 8),
                CareChoicePill(
                  label: 'Everyone',
                  selected: !viewModel.onlyRun,
                  onTap: () => viewModel.setOnlyRun(false),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kCare,
              onRefresh: viewModel.load,
              child: _body(context, viewModel, run, lines),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AdminPayrollViewModel viewModel, PayrollRun? run, List<PayrollLine> lines) {
    if (viewModel.isLoading && run == null) return const CareStateView.loading();
    if (viewModel.loadError != null && run == null) return CareStateView.error(viewModel.loadError!);
    if (run == null) return const CareStateView.loading();

    if (lines.isEmpty) {
      return CareStateView(
        icon: Icons.payments_outlined,
        title: viewModel.onlyRun ? 'Nothing run for this month' : 'No staff',
        message: viewModel.onlyRun
            ? 'Switch to everyone and tap a name to enter their pay.'
            : 'Add staff accounts before running payroll.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: lines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final line = lines[i];

        return CareCard(
          onTap: () => _edit(context, viewModel, line),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(line.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: CareText.titleMd),
                        Text(
                          [
                            line.role ?? '',
                            '${line.presentDays} present',
                            if (line.absentDays > 0) '${line.absentDays} absent',
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: CareText.mutedSm,
                        ),
                      ],
                    ),
                  ),
                  CareChip(
                    label: line.status,
                    bg: switch (line.status) {
                      'paid' => kSuccessBg,
                      'not run' => kCareNeutralBg,
                      _ => kWarningBg,
                    },
                    fg: switch (line.status) {
                      'paid' => kSuccessFg,
                      'not run' => kMuted,
                      _ => kWarningFg,
                    },
                  ),
                ],
              ),
              if (line.isRun) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${money(line.basic)} + ${money(line.allowances)} '
                        '− ${money(line.deductions)}',
                        style: CareText.mutedSm,
                      ),
                    ),
                    Text(money(line.netPay), style: CareText.titleLg),
                  ],
                ),
                if (!line.isPaid) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _pay(context, viewModel, line),
                      child: const Text('Mark paid'),
                    ),
                  ),
                ] else if ((line.paidOn ?? '').isNotEmpty)
                  Text('Paid ${line.paidOn}', style: CareText.mutedXs),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _shiftMonth(String period, int by) {
    final parts = period.split('-');
    final year = int.tryParse(parts.first) ?? DateTime.now().year;
    final month = parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1;
    final moved = DateTime(year, month + by);
    return '${moved.year}-${moved.month.toString().padLeft(2, '0')}';
  }
}
