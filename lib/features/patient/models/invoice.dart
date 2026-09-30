import 'package:hms_mobile/core/models/json_value.dart';

class InvoiceItem {
  final String itemName;
  final String? description;
  final num quantity;
  final double unitPrice;
  final double total;

  const InvoiceItem({
    required this.itemName,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        itemName: json['item_name']?.toString() ?? '',
        description: json['description']?.toString(),
        quantity: asNum(json['quantity']) ?? 1,
        unitPrice: asDoubleOr(json['unit_price'], 0),
        total: asDoubleOr(json['total'], 0),
      );
}

class Invoice {
  final int id;
  final String invoiceNo;
  final String date;
  final String? dueDate;
  final double total;
  final double paidAmount;
  final double balance;
  final String status;
  final List<InvoiceItem> items;

  const Invoice({
    required this.id,
    required this.invoiceNo,
    required this.date,
    this.dueDate,
    required this.total,
    required this.paidAmount,
    required this.balance,
    required this.status,
    required this.items,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as int,
        invoiceNo: json['invoice_no']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        dueDate: json['due_date']?.toString(),
        total: asDoubleOr(json['total'], 0),
        paidAmount: asDoubleOr(json['paid_amount'], 0),
        balance: asDoubleOr(json['balance'], 0),
        status: json['status']?.toString() ?? 'unpaid',
        items: (json['items'] as List? ?? [])
            .map((item) => InvoiceItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  bool get hasBalance => balance > 0;
}
