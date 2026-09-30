import 'package:hms_mobile/core/models/json_value.dart';

class Ward {
  final int id;
  final String? wardNo;
  final String name;
  final String type;
  final String? floor;
  final String? building;
  final int totalBeds;
  final int availableBeds;
  final double chargePerDay;

  const Ward({
    required this.id,
    this.wardNo,
    required this.name,
    required this.type,
    this.floor,
    this.building,
    required this.totalBeds,
    required this.availableBeds,
    required this.chargePerDay,
  });

  factory Ward.fromJson(Map<String, dynamic> json) => Ward(
        id: json['id'] as int,
        wardNo: json['ward_no']?.toString(),
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        floor: json['floor']?.toString(),
        building: json['building']?.toString(),
        totalBeds: json['total_beds'] as int? ?? 0,
        availableBeds: json['available_beds'] as int? ?? 0,
        chargePerDay: asDoubleOr(json['charge_per_day'], 0),
      );
}

class Bed {
  final int id;
  final String bedNo;
  final String? type;
  final String status;
  final String? patientName;
  final int? patientId;

  const Bed({
    required this.id,
    required this.bedNo,
    this.type,
    required this.status,
    this.patientName,
    this.patientId,
  });

  bool get isAvailable => status == 'available';

  factory Bed.fromJson(Map<String, dynamic> json) => Bed(
        id: json['id'] as int,
        bedNo: json['bed_no']?.toString() ?? '',
        type: json['type']?.toString(),
        status: json['status']?.toString() ?? '',
        patientName: json['patient_name']?.toString(),
        patientId: json['patient_id'] as int?,
      );
}

class WardDetail {
  final int id;
  final String name;
  final String type;
  final int totalBeds;
  final int availableBeds;
  final List<Bed> beds;

  const WardDetail({
    required this.id,
    required this.name,
    required this.type,
    required this.totalBeds,
    required this.availableBeds,
    required this.beds,
  });

  factory WardDetail.fromJson(Map<String, dynamic> json) => WardDetail(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        totalBeds: json['total_beds'] as int? ?? 0,
        availableBeds: json['available_beds'] as int? ?? 0,
        beds: (json['beds'] as List? ?? []).map((b) => Bed.fromJson(b as Map<String, dynamic>)).toList(),
      );
}
