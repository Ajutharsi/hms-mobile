class Drug {
  final int id;
  final String? drugCode;
  final String drugName;
  final String? genericName;
  final String category;
  final String form;
  final String? strength;
  final String? manufacturer;
  final double unitPrice;
  final int? minStockLevel;
  final int currentStock;
  final String? expiryDate;
  final String status;
  final bool isExpired;
  final bool isLowStock;
  final bool isNearExpiry;

  const Drug({
    required this.id,
    this.drugCode,
    required this.drugName,
    this.genericName,
    required this.category,
    required this.form,
    this.strength,
    this.manufacturer,
    required this.unitPrice,
    this.minStockLevel,
    required this.currentStock,
    this.expiryDate,
    required this.status,
    required this.isExpired,
    required this.isLowStock,
    required this.isNearExpiry,
  });

  factory Drug.fromJson(Map<String, dynamic> json) => Drug(
        id: json['id'] as int,
        drugCode: json['drug_code']?.toString(),
        drugName: json['drug_name']?.toString() ?? '',
        genericName: json['generic_name']?.toString(),
        category: json['category']?.toString() ?? '',
        form: json['form']?.toString() ?? '',
        strength: json['strength']?.toString(),
        manufacturer: json['manufacturer']?.toString(),
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
        minStockLevel: json['min_stock_level'] as int?,
        currentStock: json['current_stock'] as int? ?? 0,
        expiryDate: json['expiry_date']?.toString(),
        status: json['status']?.toString() ?? 'active',
        isExpired: json['is_expired'] == true,
        isLowStock: json['is_low_stock'] == true,
        isNearExpiry: json['is_near_expiry'] == true,
      );
}

class DrugStockEntry {
  final int id;
  final String type;
  final int quantity;
  final int balance;
  final String? reason;
  final String? notes;
  final String? performedByName;
  final String? createdAt;

  const DrugStockEntry({
    required this.id,
    required this.type,
    required this.quantity,
    required this.balance,
    this.reason,
    this.notes,
    this.performedByName,
    this.createdAt,
  });

  factory DrugStockEntry.fromJson(Map<String, dynamic> json) => DrugStockEntry(
        id: json['id'] as int,
        type: json['type']?.toString() ?? '',
        quantity: json['quantity'] as int? ?? 0,
        balance: json['balance'] as int? ?? 0,
        reason: json['reason']?.toString(),
        notes: json['notes']?.toString(),
        performedByName: json['performed_by_name']?.toString(),
        createdAt: json['created_at']?.toString(),
      );
}
