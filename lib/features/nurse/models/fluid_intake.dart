import 'package:hms_mobile/core/models/json_value.dart';

class FluidIntakePatient {
  final int id;
  final String name;
  final String mrn;
  final String? wardName;
  final String? bedNo;
  final num intake;
  final num output;
  final num balance;

  const FluidIntakePatient({
    required this.id,
    required this.name,
    required this.mrn,
    this.wardName,
    this.bedNo,
    required this.intake,
    required this.output,
    required this.balance,
  });

  factory FluidIntakePatient.fromJson(Map<String, dynamic> json) => FluidIntakePatient(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        mrn: json['mrn']?.toString() ?? '',
        wardName: json['ward_name']?.toString(),
        bedNo: json['bed_no']?.toString(),
        intake: asNum(json['intake']) ?? 0,
        output: asNum(json['output']) ?? 0,
        balance: asNum(json['balance']) ?? 0,
      );
}

class FluidLog {
  final int id;
  final String logDate;
  final String logTime;
  final String flowType;
  final String category;
  final int amountMl;
  final String? notes;
  final String? loggedByName;

  const FluidLog({
    required this.id,
    required this.logDate,
    required this.logTime,
    required this.flowType,
    required this.category,
    required this.amountMl,
    this.notes,
    this.loggedByName,
  });

  factory FluidLog.fromJson(Map<String, dynamic> json) => FluidLog(
        id: json['id'] as int,
        logDate: json['log_date']?.toString() ?? '',
        logTime: json['log_time']?.toString() ?? '',
        flowType: json['flow_type']?.toString() ?? 'intake',
        category: json['category']?.toString() ?? 'oral',
        amountMl: json['amount_ml'] as int? ?? 0,
        notes: json['notes']?.toString(),
        loggedByName: json['logged_by_name']?.toString(),
      );
}
