import 'package:hms_mobile/core/models/json_value.dart';

class InvoiceStats {
  final int totalInvoices;
  final double paid;
  final double outstanding;
  final int overdue;

  const InvoiceStats({required this.totalInvoices, required this.paid, required this.outstanding, required this.overdue});

  factory InvoiceStats.fromJson(Map<String, dynamic> json) => InvoiceStats(
        totalInvoices: json['total_invoices'] as int? ?? 0,
        paid: asDoubleOr(json['paid'], 0),
        outstanding: asDoubleOr(json['outstanding'], 0),
        overdue: json['overdue'] as int? ?? 0,
      );
}

class Invoice {
  final int id;
  final String? invoiceNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String? invoiceDate;
  final String? dueDate;
  final double total;
  final double paidAmount;
  final double balance;
  final String status;

  const Invoice({
    required this.id,
    this.invoiceNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.invoiceDate,
    this.dueDate,
    required this.total,
    required this.paidAmount,
    required this.balance,
    required this.status,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as int,
        invoiceNo: json['invoice_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        invoiceDate: json['invoice_date']?.toString(),
        dueDate: json['due_date']?.toString(),
        total: asDoubleOr(json['total'], 0),
        paidAmount: asDoubleOr(json['paid_amount'], 0),
        balance: asDoubleOr(json['balance'], 0),
        status: json['status']?.toString() ?? 'draft',
      );
}

class InvoiceItemLine {
  final String itemName;
  final String? itemType;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double total;

  const InvoiceItemLine({
    required this.itemName,
    this.itemType,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.total,
  });

  factory InvoiceItemLine.fromJson(Map<String, dynamic> json) => InvoiceItemLine(
        itemName: json['item_name']?.toString() ?? '',
        itemType: json['item_type']?.toString(),
        description: json['description']?.toString(),
        quantity: json['quantity'] as int? ?? 0,
        unitPrice: asDoubleOr(json['unit_price'], 0),
        discount: asDoubleOr(json['discount'], 0),
        total: asDoubleOr(json['total'], 0),
      );
}

class InvoicePayment {
  final String? paymentNo;
  final double amount;
  final String paymentMethod;
  final String? referenceNo;
  final String? paymentDate;
  final String? receivedByName;

  const InvoicePayment({
    this.paymentNo,
    required this.amount,
    required this.paymentMethod,
    this.referenceNo,
    this.paymentDate,
    this.receivedByName,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic> json) => InvoicePayment(
        paymentNo: json['payment_no']?.toString(),
        amount: asDoubleOr(json['amount'], 0),
        paymentMethod: json['payment_method']?.toString() ?? '',
        referenceNo: json['reference_no']?.toString(),
        paymentDate: json['payment_date']?.toString(),
        receivedByName: json['received_by_name']?.toString(),
      );
}

class InvoiceDetail extends Invoice {
  final double subtotal;
  final double discount;
  final double tax;
  final String? notes;
  final String? createdByName;
  final List<InvoiceItemLine> items;
  final List<InvoicePayment> payments;

  const InvoiceDetail({
    required super.id,
    super.invoiceNo,
    required super.patientId,
    super.patientName,
    super.patientMrn,
    super.invoiceDate,
    super.dueDate,
    required super.total,
    required super.paidAmount,
    required super.balance,
    required super.status,
    required this.subtotal,
    required this.discount,
    required this.tax,
    this.notes,
    this.createdByName,
    required this.items,
    required this.payments,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) => InvoiceDetail(
        id: json['id'] as int,
        invoiceNo: json['invoice_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        invoiceDate: json['invoice_date']?.toString(),
        dueDate: json['due_date']?.toString(),
        total: asDoubleOr(json['total'], 0),
        paidAmount: asDoubleOr(json['paid_amount'], 0),
        balance: asDoubleOr(json['balance'], 0),
        status: json['status']?.toString() ?? 'draft',
        subtotal: asDoubleOr(json['subtotal'], 0),
        discount: asDoubleOr(json['discount'], 0),
        tax: asDoubleOr(json['tax'], 0),
        notes: json['notes']?.toString(),
        createdByName: json['created_by_name']?.toString(),
        items: (json['items'] as List? ?? []).map((i) => InvoiceItemLine.fromJson(i as Map<String, dynamic>)).toList(),
        payments: (json['payments'] as List? ?? []).map((p) => InvoicePayment.fromJson(p as Map<String, dynamic>)).toList(),
      );
}

class BillingServiceItem {
  final int id;
  final String? serviceCode;
  final String serviceName;
  final String? category;
  final double price;

  const BillingServiceItem({required this.id, this.serviceCode, required this.serviceName, this.category, required this.price});

  factory BillingServiceItem.fromJson(Map<String, dynamic> json) => BillingServiceItem(
        id: json['id'] as int,
        serviceCode: json['service_code']?.toString(),
        serviceName: json['service_name']?.toString() ?? '',
        category: json['category']?.toString(),
        price: asDoubleOr(json['price'], 0),
      );
}
