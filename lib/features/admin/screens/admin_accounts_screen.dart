import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/admin_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_forms.dart';
import 'package:hms_mobile/core/theme/care_radius.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/ops_models.dart';

/// Expenses and the end of the day's cash on one screen, because they
/// are the same question asked twice: what went out, and does the
/// drawer agree.
class AdminAccountsViewModel extends ChangeNotifier {
  final AdminApiService api;
  final AuthStorage authStorage;

  AdminAccountsViewModel({AdminApiService? api, AuthStorage? authStorage})
      : api = api ?? AdminApiService(),
        authStorage = authStorage ?? AuthStorage() {
    load();
  }

  bool isLoading = true;
  String? loadError;
  ExpenseMonth? month;
  DayEnd? day;
  List<DayClosing> closings = [];

  /// 'expenses' or 'day-end'.
  String tab = 'expenses';

  Future<String> _token() async => (await authStorage.readToken())!;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      await guardNetworkErrors(() async {
        final token = await _token();
        month = await api.expenses(token);
        day = await api.dayEnd(token);
        closings = await api.closings(token);
      });
    } on ApiException catch (e) {
      loadError = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void showTab(String value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
  }

  Future<String?> mutate(Future<void> Function(AdminApiService api, String token) action) async {
    try {
      await guardNetworkErrors(() async => action(api, await _token()));
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Returns the server's sentence (it says over or short), or an error.
  Future<(String?, String?)> close(Map<String, dynamic> body) async {
    try {
      final message = await guardNetworkErrors(() async => api.closeDay(await _token(), body));
      await load();
      return (message, null);
    } on ApiException catch (e) {
      return (null, e.message);
    }
  }
}

class AdminAccountsScreen extends StatelessWidget {
  const AdminAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AdminAccountsViewModel(),
        child: const CareTheme(child: _AccountsView()),
      );
}

class _AccountsView extends StatelessWidget {
  const _AccountsView();

  Future<void> _addExpense(BuildContext context, AdminAccountsViewModel viewModel) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final values = await careFormSheet(
      context,
      title: 'Record expense',
      submitLabel: 'Save',
      fields: [
        const CareFormField('category', 'Category',
            options: ['Utilities', 'Salaries', 'Supplies', 'Maintenance', 'Rent', 'Transport', 'Other'],
            icon: Icons.category_outlined),
        const CareFormField('amount', 'Amount',
            required: true, keyboard: TextInputType.number, icon: Icons.currency_rupee_rounded),
        const CareFormField('paid_to', 'Paid to', icon: Icons.store_outlined),
        const CareFormField('payment_mode', 'Paid by',
            options: ['cash', 'bank_transfer', 'upi', 'card', 'cheque'], icon: Icons.account_balance_wallet_outlined),
        CareFormField('expense_date', 'Date', initial: today, required: true, icon: Icons.event_outlined),
        const CareFormField('reference_no', 'Reference', icon: Icons.tag_outlined),
        const CareFormField('notes', 'Notes', maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.expenseStore(token, values));
    if (context.mounted) careSnack(context, error ?? 'Expense recorded.', isError: error != null);
  }

  Future<void> _closeDay(BuildContext context, AdminAccountsViewModel viewModel) async {
    final day = viewModel.day;
    if (day == null) return;

    final expected = day.counted['expected_cash'] ?? 0;

    final values = await careFormSheet(
      context,
      title: 'Close ${day.date}',
      submitLabel: 'Close day',
      fields: [
        // The one number nothing else can know.
        CareFormField('counted_cash', 'Cash counted in the drawer',
            initial: expected.toStringAsFixed(2),
            required: true,
            keyboard: TextInputType.number,
            icon: Icons.account_balance_wallet_outlined),
        const CareFormField('notes', 'Notes', maxLines: 2, icon: Icons.notes_outlined),
      ],
    );
    if (values == null || !context.mounted) return;

    final (message, error) = await viewModel.close({...values, 'date': day.date});
    if (context.mounted) careSnack(context, error ?? message!, isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminAccountsViewModel>();
    final onExpenses = viewModel.tab == 'expenses';

    return Scaffold(
      appBar: carePageAppBar(context, 'Accounts'),
      floatingActionButton: onExpenses
          ? FloatingActionButton.extended(
              onPressed: () => _addExpense(context, viewModel),
              backgroundColor: kCareDark,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Expense', style: CareText.onCareBold),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                CareChoicePill(
                  label: 'Expenses',
                  selected: onExpenses,
                  onTap: () => viewModel.showTab('expenses'),
                ),
                const SizedBox(width: 8),
                CareChoicePill(
                  label: 'Day end',
                  selected: !onExpenses,
                  onTap: () => viewModel.showTab('day-end'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kCare,
              onRefresh: viewModel.load,
              child: onExpenses ? _expenses(context, viewModel) : _dayEnd(context, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenses(BuildContext context, AdminAccountsViewModel viewModel) {
    final month = viewModel.month;
    if (viewModel.isLoading && month == null) return const CareStateView.loading();
    if (viewModel.loadError != null && month == null) return CareStateView.error(viewModel.loadError!);
    if (month == null) return const CareStateView.loading();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      children: [
        CareCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(month.month, style: CareText.mutedSm),
                    Text('₹${(month.stats['total'] ?? 0).toStringAsFixed(0)}', style: CareText.display),
                    Text('${month.stats['count'] ?? 0} entries', style: CareText.mutedXs),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('of which cash', style: CareText.mutedXs),
                  Text('₹${(month.stats['cash'] ?? 0).toStringAsFixed(0)}', style: CareText.titleLg),
                ],
              ),
            ],
          ),
        ),
        if (month.byCategory.isNotEmpty) ...[
          const SizedBox(height: 16),
          const CareSectionTitle(title: 'Where it went'),
          const SizedBox(height: 8),
          CareCard(
            child: Column(
              children: [
                for (final row in month.byCategory)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(row.category, style: CareText.titleMd)),
                        Text('₹${row.total.toStringAsFixed(0)}', style: CareText.titleMd),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        const CareSectionTitle(title: 'Entries'),
        const SizedBox(height: 8),
        if (month.expenses.isEmpty)
          const CareStateView.inline(
            icon: Icons.receipt_long_outlined,
            title: 'Nothing recorded',
            message: 'Expenses added this month appear here.',
          )
        else
          for (final expense in month.expenses)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CareCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.category, style: CareText.titleMd),
                          Text(
                            [expense.paidTo ?? '', expense.date ?? '', expense.paymentMode]
                                .where((s) => s.isNotEmpty)
                                .join(' · '),
                            style: CareText.mutedSm,
                          ),
                        ],
                      ),
                    ),
                    Text('₹${expense.amount.toStringAsFixed(0)}', style: CareText.titleMd),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _dayEnd(BuildContext context, AdminAccountsViewModel viewModel) {
    final day = viewModel.day;
    if (viewModel.isLoading && day == null) return const CareStateView.loading();
    if (viewModel.loadError != null && day == null) return CareStateView.error(viewModel.loadError!);
    if (day == null) return const CareStateView.loading();

    final counted = day.counted;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(day.date, style: CareText.titleXl)),
                  CareChip(
                    label: day.closed ? 'closed' : 'open',
                    bg: day.closed ? kSuccessBg : kWarningBg,
                    fg: day.closed ? kSuccessFg : kWarningFg,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Money(label: 'Collections', value: counted['collections'] ?? 0),
              _Money(label: 'of which cash', value: counted['cash_collections'] ?? 0, muted: true),
              _Money(label: 'Expenses', value: counted['expenses'] ?? 0),
              _Money(label: 'Opening cash', value: counted['opening_cash'] ?? 0, muted: true),
              Divider(height: 20, color: kCareBorder),
              _Money(label: 'Cash expected', value: counted['expected_cash'] ?? 0, strong: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (day.closed && day.closing != null)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: day.closing!.isBalanced ? kSuccessBg : kWarningBg,
              borderRadius: BorderRadius.circular(CareRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.closing!.isBalanced
                      ? 'Closed and balanced'
                      : 'Closed ${day.closing!.varianceLabel} by ₹${day.closing!.variance.abs().toStringAsFixed(2)}',
                  style: CareText.titleMd,
                ),
                const SizedBox(height: 4),
                Text(
                  'Counted ₹${day.closing!.countedCash.toStringAsFixed(2)} against '
                  '₹${day.closing!.expectedCash.toStringAsFixed(2)} expected',
                  style: CareText.mutedSm,
                ),
                if ((day.closing!.closedBy ?? '').isNotEmpty)
                  Text('by ${day.closing!.closedBy} · ${day.closing!.closedAt ?? ''}', style: CareText.mutedXs),
                if ((day.closing!.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(day.closing!.notes!, style: CareText.bodyMdMuted),
                ],
              ],
            ),
          )
        else
          CarePrimaryButton(
            label: 'Count the drawer and close',
            icon: Icons.lock_clock_rounded,
            onPressed: () => _closeDay(context, viewModel),
          ),
        if (viewModel.closings.isNotEmpty) ...[
          const SizedBox(height: 18),
          const CareSectionTitle(title: 'Recent closings'),
          const SizedBox(height: 8),
          CareCard(
            child: Column(
              children: [
                for (final closing in viewModel.closings.take(14))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(closing.date ?? '', style: CareText.titleMd),
                              Text('₹${closing.collections.toStringAsFixed(0)} in · '
                                  '₹${closing.expenses.toStringAsFixed(0)} out',
                                  style: CareText.mutedSm),
                            ],
                          ),
                        ),
                        CareChip(
                          label: closing.isBalanced
                              ? 'balanced'
                              : '${closing.varianceLabel} ₹${closing.variance.abs().toStringAsFixed(0)}',
                          bg: closing.isBalanced ? kSuccessBg : kWarningBg,
                          fg: closing.isBalanced ? kSuccessFg : kWarningFg,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Money extends StatelessWidget {
  final String label;
  final num value;
  final bool muted;
  final bool strong;

  const _Money({required this.label, required this.value, this.muted = false, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: muted ? CareText.mutedXs : CareText.bodyMd)),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: strong ? CareText.titleLg : (muted ? CareText.mutedSm : CareText.titleMd),
          ),
        ],
      ),
    );
  }
}
