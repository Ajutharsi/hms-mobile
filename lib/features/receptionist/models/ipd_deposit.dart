class IpdDepositStats {
  final double totalCollected;
  final double totalRefunded;
  final double todayCollection;

  const IpdDepositStats({required this.totalCollected, required this.totalRefunded, required this.todayCollection});

  factory IpdDepositStats.fromJson(Map<String, dynamic> json) => IpdDepositStats(
        totalCollected: (json['total_collected'] as num?)?.toDouble() ?? 0,
        totalRefunded: (json['total_refunded'] as num?)?.toDouble() ?? 0,
        todayCollection: (json['today_collection'] as num?)?.toDouble() ?? 0,
      );
}

class IpdDeposit {
  final int id;
  final String? depositNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final double amount;
  final String type;
  final String paymentMethod;
  final String? referenceNo;
  final String? notes;
  final String? collectedByName;
  final String? depositedAt;
  final double balance;

  const IpdDeposit({
    required this.id,
    this.depositNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    required this.amount,
    required this.type,
    required this.paymentMethod,
    this.referenceNo,
    this.notes,
    this.collectedByName,
    this.depositedAt,
    required this.balance,
  });

  factory IpdDeposit.fromJson(Map<String, dynamic> json) => IpdDeposit(
        id: json['id'] as int,
        depositNo: json['deposit_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        type: json['type']?.toString() ?? 'advance',
        paymentMethod: json['payment_method']?.toString() ?? '',
        referenceNo: json['reference_no']?.toString(),
        notes: json['notes']?.toString(),
        collectedByName: json['collected_by_name']?.toString(),
        depositedAt: json['deposited_at']?.toString(),
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
      );
}
