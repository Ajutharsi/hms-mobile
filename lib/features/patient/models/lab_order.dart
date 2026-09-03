class LabResultItem {
  final String? testName;
  final String? category;
  final String? resultValue;
  final String? unit;
  final String? normalRange;
  final String? flag;
  final String? remarks;

  const LabResultItem({
    this.testName,
    this.category,
    this.resultValue,
    this.unit,
    this.normalRange,
    this.flag,
    this.remarks,
  });

  factory LabResultItem.fromJson(Map<String, dynamic> json) => LabResultItem(
        testName: json['test_name']?.toString(),
        category: json['category']?.toString(),
        resultValue: json['result_value']?.toString(),
        unit: json['unit']?.toString(),
        normalRange: json['normal_range']?.toString(),
        flag: json['flag']?.toString(),
        remarks: json['remarks']?.toString(),
      );
}

class LabOrder {
  final int id;
  final String orderNo;
  final String date;
  final String? doctorName;
  final String status;
  final String? notes;
  final List<LabResultItem> items;

  const LabOrder({
    required this.id,
    required this.orderNo,
    required this.date,
    this.doctorName,
    required this.status,
    this.notes,
    required this.items,
  });

  factory LabOrder.fromJson(Map<String, dynamic> json) => LabOrder(
        id: json['id'] as int,
        orderNo: json['order_no']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        doctorName: json['doctor_name']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        notes: json['notes']?.toString(),
        items: (json['items'] as List? ?? [])
            .map((item) => LabResultItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  bool get isCompleted => status == 'completed';
}
