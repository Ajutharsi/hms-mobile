class PharmacyDashboardStats {
  final int totalDrugs;
  final int lowStock;
  final int dispensedToday;
  final int nearExpiry;

  const PharmacyDashboardStats({
    required this.totalDrugs,
    required this.lowStock,
    required this.dispensedToday,
    required this.nearExpiry,
  });

  factory PharmacyDashboardStats.fromJson(Map<String, dynamic> json) => PharmacyDashboardStats(
        totalDrugs: json['total_drugs'] as int? ?? 0,
        lowStock: json['low_stock'] as int? ?? 0,
        dispensedToday: json['dispensed_today'] as int? ?? 0,
        nearExpiry: json['near_expiry'] as int? ?? 0,
      );
}
