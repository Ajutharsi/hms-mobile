class LabDashboardStats {
  final int pendingOrders;
  final int completedToday;
  final int totalOrders;
  final int labTests;

  const LabDashboardStats({
    required this.pendingOrders,
    required this.completedToday,
    required this.totalOrders,
    required this.labTests,
  });

  factory LabDashboardStats.fromJson(Map<String, dynamic> json) => LabDashboardStats(
        pendingOrders: json['pending_orders'] as int? ?? 0,
        completedToday: json['completed_today'] as int? ?? 0,
        totalOrders: json['total_orders'] as int? ?? 0,
        labTests: json['lab_tests'] as int? ?? 0,
      );
}
