class PharmacyPatient {
  final int id;
  final String mrn;
  final String name;
  final String? phone;

  const PharmacyPatient({required this.id, required this.mrn, required this.name, this.phone});

  factory PharmacyPatient.fromJson(Map<String, dynamic> json) => PharmacyPatient(
        id: json['id'] as int,
        mrn: json['mrn']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString(),
      );
}
