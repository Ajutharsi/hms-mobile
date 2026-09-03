class StaffDashboardStats {
  final int myAssignedWards;
  final int overdueRounds;
  final int myFoodLogsToday;
  final int myFluidLogsToday;

  const StaffDashboardStats({
    required this.myAssignedWards,
    required this.overdueRounds,
    required this.myFoodLogsToday,
    required this.myFluidLogsToday,
  });

  factory StaffDashboardStats.fromJson(Map<String, dynamic> json) => StaffDashboardStats(
        myAssignedWards: json['my_assigned_wards'] as int? ?? 0,
        overdueRounds: json['overdue_rounds'] as int? ?? 0,
        myFoodLogsToday: json['my_food_logs_today'] as int? ?? 0,
        myFluidLogsToday: json['my_fluid_logs_today'] as int? ?? 0,
      );
}
