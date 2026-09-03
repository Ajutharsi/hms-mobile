class BloodUnit {
  final int id;
  final String? unitNo;
  final String bloodGroup;
  final String component;
  final String? donorName;
  final String? collectionDate;
  final String? expiryDate;
  final String status;
  final bool isNearExpiry;
  final String? reservedForName;
  final String? notes;

  const BloodUnit({
    required this.id,
    this.unitNo,
    required this.bloodGroup,
    required this.component,
    this.donorName,
    this.collectionDate,
    this.expiryDate,
    required this.status,
    required this.isNearExpiry,
    this.reservedForName,
    this.notes,
  });

  bool get isAvailable => status == 'available';

  factory BloodUnit.fromJson(Map<String, dynamic> json) => BloodUnit(
        id: json['id'] as int,
        unitNo: json['unit_no']?.toString(),
        bloodGroup: json['blood_group']?.toString() ?? '',
        component: json['component']?.toString() ?? '',
        donorName: json['donor_name']?.toString(),
        collectionDate: json['collection_date']?.toString(),
        expiryDate: json['expiry_date']?.toString(),
        status: json['status']?.toString() ?? '',
        isNearExpiry: json['is_near_expiry'] == true,
        reservedForName: json['reserved_for_name']?.toString(),
        notes: json['notes']?.toString(),
      );
}

class BloodTransfusion {
  final int id;
  final String? transfusionNo;
  final int patientId;
  final String? bloodGroup;
  final String? unitNo;
  final String? indication;
  final String status;
  final String? administeredByName;
  final String? startedAt;
  final String? completedAt;

  const BloodTransfusion({
    required this.id,
    this.transfusionNo,
    required this.patientId,
    this.bloodGroup,
    this.unitNo,
    this.indication,
    required this.status,
    this.administeredByName,
    this.startedAt,
    this.completedAt,
  });

  factory BloodTransfusion.fromJson(Map<String, dynamic> json) => BloodTransfusion(
        id: json['id'] as int,
        transfusionNo: json['transfusion_no']?.toString(),
        patientId: json['patient_id'] as int,
        bloodGroup: json['blood_group']?.toString(),
        unitNo: json['unit_no']?.toString(),
        indication: json['indication']?.toString(),
        status: json['status']?.toString() ?? '',
        administeredByName: json['administered_by_name']?.toString(),
        startedAt: json['started_at']?.toString(),
        completedAt: json['completed_at']?.toString(),
      );
}
