class TimeSlot {
  final String time;
  final bool available;

  const TimeSlot({required this.time, required this.available});

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        time: json['time']?.toString() ?? '',
        available: json['available'] == true,
      );
}
