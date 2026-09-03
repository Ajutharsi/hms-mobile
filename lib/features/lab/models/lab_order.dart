class LabOrder {
  final int id;
  final String? orderNo;
  final int patientId;
  final String? patientName;
  final String? patientMrn;
  final String? doctorName;
  final String? orderDate;
  final String status;
  final String? notes;
  final int testsCount;

  const LabOrder({
    required this.id,
    this.orderNo,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.doctorName,
    this.orderDate,
    required this.status,
    this.notes,
    required this.testsCount,
  });

  factory LabOrder.fromJson(Map<String, dynamic> json) => LabOrder(
        id: json['id'] as int,
        orderNo: json['order_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        doctorName: json['doctor_name']?.toString(),
        orderDate: json['order_date']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        notes: json['notes']?.toString(),
        testsCount: json['tests_count'] as int? ?? 0,
      );
}

class LabOrderResult {
  final String resultValue;
  final String? unit;
  final String? normalRange;
  final String? flag;
  final String? remarks;
  final String? resultDate;

  const LabOrderResult({required this.resultValue, this.unit, this.normalRange, this.flag, this.remarks, this.resultDate});

  factory LabOrderResult.fromJson(Map<String, dynamic> json) => LabOrderResult(
        resultValue: json['result_value']?.toString() ?? '',
        unit: json['unit']?.toString(),
        normalRange: json['normal_range']?.toString(),
        flag: json['flag']?.toString(),
        remarks: json['remarks']?.toString(),
        resultDate: json['result_date']?.toString(),
      );
}

class LabOrderItem {
  final int id;
  final String? testName;
  final String? category;
  final String? sampleType;
  final String? unit;
  final String? normalRangeMale;
  final String? normalRangeFemale;
  final String status;
  final LabOrderResult? result;

  const LabOrderItem({
    required this.id,
    this.testName,
    this.category,
    this.sampleType,
    this.unit,
    this.normalRangeMale,
    this.normalRangeFemale,
    required this.status,
    this.result,
  });

  factory LabOrderItem.fromJson(Map<String, dynamic> json) => LabOrderItem(
        id: json['id'] as int,
        testName: json['test_name']?.toString(),
        category: json['category']?.toString(),
        sampleType: json['sample_type']?.toString(),
        unit: json['unit']?.toString(),
        normalRangeMale: json['normal_range_male']?.toString(),
        normalRangeFemale: json['normal_range_female']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        result: json['result'] != null ? LabOrderResult.fromJson(json['result'] as Map<String, dynamic>) : null,
      );
}

class LabOrderDetail extends LabOrder {
  final List<LabOrderItem> items;

  const LabOrderDetail({
    required super.id,
    super.orderNo,
    required super.patientId,
    super.patientName,
    super.patientMrn,
    super.doctorName,
    super.orderDate,
    required super.status,
    super.notes,
    required this.items,
  }) : super(testsCount: 0);

  factory LabOrderDetail.fromJson(Map<String, dynamic> json) => LabOrderDetail(
        id: json['id'] as int,
        orderNo: json['order_no']?.toString(),
        patientId: json['patient_id'] as int,
        patientName: json['patient_name']?.toString(),
        patientMrn: json['patient_mrn']?.toString(),
        doctorName: json['doctor_name']?.toString(),
        orderDate: json['order_date']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        notes: json['notes']?.toString(),
        items: (json['items'] as List? ?? []).map((i) => LabOrderItem.fromJson(i as Map<String, dynamic>)).toList(),
      );
}

class LabPatient {
  final int id;
  final String mrn;
  final String name;
  final String? phone;

  const LabPatient({required this.id, required this.mrn, required this.name, this.phone});

  factory LabPatient.fromJson(Map<String, dynamic> json) => LabPatient(
        id: json['id'] as int,
        mrn: json['mrn']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString(),
      );
}
