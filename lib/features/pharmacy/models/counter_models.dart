import 'package:hms_mobile/core/models/json_value.dart';

/// A line on a counter entry: what was sold, or what came back.
class CounterItem {
  final int? itemId;
  final String medicineName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const CounterItem({
    this.itemId,
    required this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory CounterItem.fromJson(Map<String, dynamic> j) => CounterItem(
        itemId: j['item_id'] as int?,
        medicineName: j['medicine_name']?.toString() ?? '',
        quantity: asIntOr(j['quantity']),
        unitPrice: asDoubleOr(j['unit_price']),
        totalPrice: asDoubleOr(j['total_price']),
      );
}

/// One entry at the counter: a walk-in sale or a return.
class CounterEntry {
  final int id;
  final String dispensingNo;
  final String saleType;
  final String? patientName;
  final String? patientMrn;
  final String? date;
  final double totalAmount;
  final String? status;
  final String? notes;
  final List<CounterItem> items;

  const CounterEntry({
    required this.id,
    required this.dispensingNo,
    required this.saleType,
    this.patientName,
    this.patientMrn,
    this.date,
    required this.totalAmount,
    this.status,
    this.notes,
    required this.items,
  });

  factory CounterEntry.fromJson(Map<String, dynamic> j) => CounterEntry(
        id: asIntOr(j['id']),
        dispensingNo: j['dispensing_no']?.toString() ?? '',
        saleType: j['sale_type']?.toString() ?? 'otc',
        patientName: j['patient_name']?.toString(),
        patientMrn: j['patient_mrn']?.toString(),
        date: j['date']?.toString(),
        totalAmount: asDoubleOr(j['total_amount']),
        status: j['status']?.toString(),
        notes: j['notes']?.toString(),
        items: ((j['items'] as List?) ?? const [])
            .map((i) => CounterItem.fromJson((i as Map).cast<String, dynamic>()))
            .toList(),
      );

  bool get isReturn => saleType == 'return';

  String get summary => items.map((i) => '${i.medicineName} ×${i.quantity}').join(', ');
}

class CounterDay {
  final Map<String, num> stats;
  final List<CounterEntry> entries;

  const CounterDay({required this.stats, required this.entries});

  factory CounterDay.fromJson(Map<String, dynamic> j) => CounterDay(
        stats: ((j['stats'] as Map?) ?? const {})
            .map((k, v) => MapEntry('$k', v is num ? v : asDoubleOr(v))),
        entries: ((j['entries'] as List?) ?? const [])
            .map((e) => CounterEntry.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}
