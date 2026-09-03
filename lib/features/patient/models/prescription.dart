class PrescriptionItem {
  final String medicineName;
  final String dosage;
  final String frequency;
  final String duration;
  final String? route;
  final String? instructions;

  const PrescriptionItem({
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.route,
    this.instructions,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) => PrescriptionItem(
        medicineName: json['medicine_name']?.toString() ?? '',
        dosage: json['dosage']?.toString() ?? '',
        frequency: json['frequency']?.toString() ?? '',
        duration: json['duration']?.toString() ?? '',
        route: json['route']?.toString(),
        instructions: json['instructions']?.toString(),
      );
}

class Prescription {
  final int id;
  final String prescriptionNo;
  final String date;
  final String? doctorName;
  final String? doctorSpecialization;
  final String? notes;
  final String status;
  final List<PrescriptionItem> items;

  const Prescription({
    required this.id,
    required this.prescriptionNo,
    required this.date,
    this.doctorName,
    this.doctorSpecialization,
    this.notes,
    required this.status,
    required this.items,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: json['id'] as int,
        prescriptionNo: json['prescription_no']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        doctorName: json['doctor_name']?.toString(),
        doctorSpecialization: json['doctor_specialization']?.toString(),
        notes: json['notes']?.toString(),
        status: json['status']?.toString() ?? 'active',
        items: (json['items'] as List? ?? [])
            .map((item) => PrescriptionItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
