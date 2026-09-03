class Doctor {
  final int id;
  final String name;
  final String? specialization;
  final String? photoUrl;

  const Doctor({required this.id, required this.name, this.specialization, this.photoUrl});

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        specialization: json['specialization']?.toString(),
        photoUrl: json['photo_url']?.toString(),
      );

  String get label => specialization == null || specialization!.isEmpty ? name : '$name · $specialization';
}
