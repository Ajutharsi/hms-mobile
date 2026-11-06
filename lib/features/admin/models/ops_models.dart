import 'package:hms_mobile/core/models/json_value.dart';

// ------------------------------------------------------------- roster

/// One day in one person's week on the roster.
class RosterDay {
  final String date;
  final int? id;
  final String? shift;
  final String? wardName;
  final String? notes;
  final bool onLeave;

  const RosterDay({
    required this.date,
    this.id,
    this.shift,
    this.wardName,
    this.notes,
    required this.onLeave,
  });

  factory RosterDay.fromJson(Map<String, dynamic> j) => RosterDay(
        date: j['date']?.toString() ?? '',
        id: j['id'] as int?,
        shift: j['shift']?.toString(),
        wardName: j['ward_name']?.toString(),
        notes: j['notes']?.toString(),
        onLeave: j['on_leave'] == true,
      );

  bool get isSet => (shift ?? '').isNotEmpty;

  /// M / E / N / — : a week has to fit across a phone.
  String get initial => switch (shift) {
        'morning' => 'M',
        'evening' => 'E',
        'night' => 'N',
        'off' => 'O',
        _ => '·',
      };
}

class RosterPerson {
  final int id;
  final String name;
  final String? role;
  final List<RosterDay> days;

  const RosterPerson({required this.id, required this.name, this.role, required this.days});

  factory RosterPerson.fromJson(Map<String, dynamic> j) => RosterPerson(
        id: asIntOr(j['id']),
        name: j['name']?.toString() ?? '',
        role: j['role']?.toString(),
        days: ((j['days'] as List?) ?? const [])
            .map((d) => RosterDay.fromJson((d as Map).cast<String, dynamic>()))
            .toList(),
      );

  bool get hasAnyShift => days.any((d) => d.isSet);
}

class RosterWeek {
  final String weekStart;
  final List<String> days;
  final Map<String, int> stats;
  final List<RosterPerson> staff;

  const RosterWeek({
    required this.weekStart,
    required this.days,
    required this.stats,
    required this.staff,
  });

  factory RosterWeek.fromJson(Map<String, dynamic> j) => RosterWeek(
        weekStart: j['week_start']?.toString() ?? '',
        days: ((j['days'] as List?) ?? const []).map((d) => d.toString()).toList(),
        stats: ((j['stats'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', asIntOr(v))),
        staff: ((j['staff'] as List?) ?? const [])
            .map((s) => RosterPerson.fromJson((s as Map).cast<String, dynamic>()))
            .toList(),
      );
}

// ------------------------------------------------------------ payroll

class PayrollLine {
  final int userId;
  final String name;
  final String? role;
  final String period;
  final int? payrollId;
  final double basic;
  final double allowances;
  final double deductions;
  final double netPay;
  final String status;
  final String? paidOn;
  final int presentDays;
  final int absentDays;

  const PayrollLine({
    required this.userId,
    required this.name,
    this.role,
    required this.period,
    this.payrollId,
    required this.basic,
    required this.allowances,
    required this.deductions,
    required this.netPay,
    required this.status,
    this.paidOn,
    required this.presentDays,
    required this.absentDays,
  });

  factory PayrollLine.fromJson(Map<String, dynamic> j) => PayrollLine(
        userId: asIntOr(j['user_id']),
        name: j['name']?.toString() ?? '',
        role: j['role']?.toString(),
        period: j['period']?.toString() ?? '',
        payrollId: j['payroll_id'] as int?,
        basic: asDoubleOr(j['basic']),
        allowances: asDoubleOr(j['allowances']),
        deductions: asDoubleOr(j['deductions']),
        netPay: asDoubleOr(j['net_pay']),
        status: j['status']?.toString() ?? 'not run',
        paidOn: j['paid_on']?.toString(),
        presentDays: asIntOr(j['present_days']),
        absentDays: asIntOr(j['absent_days']),
      );

  bool get isRun => payrollId != null;
  bool get isPaid => status == 'paid';
}

class PayrollRun {
  final String period;
  final Map<String, num> stats;
  final List<PayrollLine> lines;

  const PayrollRun({required this.period, required this.stats, required this.lines});

  factory PayrollRun.fromJson(Map<String, dynamic> j) => PayrollRun(
        period: j['period']?.toString() ?? '',
        stats: ((j['stats'] as Map?) ?? const {})
            .map((k, v) => MapEntry('$k', v is num ? v : asDoubleOr(v))),
        lines: ((j['lines'] as List?) ?? const [])
            .map((l) => PayrollLine.fromJson((l as Map).cast<String, dynamic>()))
            .toList(),
      );
}

// ----------------------------------------------------------- accounts

class ExpenseRow {
  final int id;
  final String? date;
  final String category;
  final String? paidTo;
  final double amount;
  final String paymentMode;
  final String? referenceNo;
  final String? notes;
  final String? recordedBy;

  const ExpenseRow({
    required this.id,
    this.date,
    required this.category,
    this.paidTo,
    required this.amount,
    required this.paymentMode,
    this.referenceNo,
    this.notes,
    this.recordedBy,
  });

  factory ExpenseRow.fromJson(Map<String, dynamic> j) => ExpenseRow(
        id: asIntOr(j['id']),
        date: j['date']?.toString(),
        category: j['category']?.toString() ?? '',
        paidTo: j['paid_to']?.toString(),
        amount: asDoubleOr(j['amount']),
        paymentMode: j['payment_mode']?.toString() ?? 'cash',
        referenceNo: j['reference_no']?.toString(),
        notes: j['notes']?.toString(),
        recordedBy: j['recorded_by']?.toString(),
      );
}

class ExpenseMonth {
  final String month;
  final Map<String, num> stats;
  final List<({String category, double total, int count})> byCategory;
  final List<ExpenseRow> expenses;

  const ExpenseMonth({
    required this.month,
    required this.stats,
    required this.byCategory,
    required this.expenses,
  });

  factory ExpenseMonth.fromJson(Map<String, dynamic> j) => ExpenseMonth(
        month: j['month']?.toString() ?? '',
        stats: ((j['stats'] as Map?) ?? const {})
            .map((k, v) => MapEntry('$k', v is num ? v : asDoubleOr(v))),
        byCategory: ((j['by_category'] as List?) ?? const []).map((c) {
          final row = (c as Map).cast<String, dynamic>();
          return (
            category: row['category']?.toString() ?? '',
            total: asDoubleOr(row['total']),
            count: asIntOr(row['count']),
          );
        }).toList(),
        expenses: ((j['expenses'] as List?) ?? const [])
            .map((e) => ExpenseRow.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// A day before it is closed: everything counted from the rows.
class DayEnd {
  final String date;
  final bool closed;
  final Map<String, num> counted;
  final DayClosing? closing;

  const DayEnd({required this.date, required this.closed, required this.counted, this.closing});

  factory DayEnd.fromJson(Map<String, dynamic> j) => DayEnd(
        date: j['date']?.toString() ?? '',
        closed: j['closed'] == true,
        counted: ((j['counted'] as Map?) ?? const {})
            .map((k, v) => MapEntry('$k', v is num ? v : asDoubleOr(v))),
        closing: j['closing'] == null
            ? null
            : DayClosing.fromJson((j['closing'] as Map).cast<String, dynamic>()),
      );
}

class DayClosing {
  final int id;
  final String? date;
  final double collections;
  final double expenses;
  final double expectedCash;
  final double countedCash;
  final double variance;
  final String varianceLabel;
  final String? closedBy;
  final String? closedAt;
  final String? notes;

  const DayClosing({
    required this.id,
    this.date,
    required this.collections,
    required this.expenses,
    required this.expectedCash,
    required this.countedCash,
    required this.variance,
    required this.varianceLabel,
    this.closedBy,
    this.closedAt,
    this.notes,
  });

  factory DayClosing.fromJson(Map<String, dynamic> j) => DayClosing(
        id: asIntOr(j['id']),
        date: j['date']?.toString(),
        collections: asDoubleOr(j['collections']),
        expenses: asDoubleOr(j['expenses']),
        expectedCash: asDoubleOr(j['expected_cash']),
        countedCash: asDoubleOr(j['counted_cash']),
        variance: asDoubleOr(j['variance']),
        varianceLabel: j['variance_label']?.toString() ?? 'balanced',
        closedBy: j['closed_by']?.toString(),
        closedAt: j['closed_at']?.toString(),
        notes: j['notes']?.toString(),
      );

  bool get isBalanced => varianceLabel == 'balanced';
}
