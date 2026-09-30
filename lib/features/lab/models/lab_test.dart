import 'package:hms_mobile/core/models/json_value.dart';

class LabTest {
  final int id;
  final String? testCode;
  final String testName;
  final String category;
  final String sampleType;
  final double price;
  final String? unit;
  final String? normalRangeMale;
  final String? normalRangeFemale;
  final String? description;
  final String status;

  const LabTest({
    required this.id,
    this.testCode,
    required this.testName,
    required this.category,
    required this.sampleType,
    required this.price,
    this.unit,
    this.normalRangeMale,
    this.normalRangeFemale,
    this.description,
    required this.status,
  });

  factory LabTest.fromJson(Map<String, dynamic> json) => LabTest(
        id: json['id'] as int,
        testCode: json['test_code']?.toString(),
        testName: json['test_name']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        sampleType: json['sample_type']?.toString() ?? '',
        price: asDoubleOr(json['price'], 0),
        unit: json['unit']?.toString(),
        normalRangeMale: json['normal_range_male']?.toString(),
        normalRangeFemale: json['normal_range_female']?.toString(),
        description: json['description']?.toString(),
        status: json['status']?.toString() ?? 'active',
      );
}
