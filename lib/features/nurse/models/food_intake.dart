class FoodIntakePatient {
  final int id;
  final String name;
  final String mrn;
  final String? wardName;
  final String? bedNo;
  final String dietType;
  final String? lastMealType;
  final String? lastMealStatus;
  final int mealsToday;

  const FoodIntakePatient({
    required this.id,
    required this.name,
    required this.mrn,
    this.wardName,
    this.bedNo,
    required this.dietType,
    this.lastMealType,
    this.lastMealStatus,
    required this.mealsToday,
  });

  factory FoodIntakePatient.fromJson(Map<String, dynamic> json) {
    final lastMeal = json['last_meal'] as Map<String, dynamic>?;
    return FoodIntakePatient(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      mrn: json['mrn']?.toString() ?? '',
      wardName: json['ward_name']?.toString(),
      bedNo: json['bed_no']?.toString(),
      dietType: json['diet_type']?.toString() ?? 'not_set',
      lastMealType: lastMeal?['meal_type']?.toString(),
      lastMealStatus: lastMeal?['status']?.toString(),
      mealsToday: json['meals_today'] as int? ?? 0,
    );
  }
}

class FoodLog {
  final int id;
  final String logDate;
  final String mealType;
  final String status;
  final String? quantity;
  final String? notes;
  final String? loggedByName;

  const FoodLog({
    required this.id,
    required this.logDate,
    required this.mealType,
    required this.status,
    this.quantity,
    this.notes,
    this.loggedByName,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) => FoodLog(
        id: json['id'] as int,
        logDate: json['log_date']?.toString() ?? '',
        mealType: json['meal_type']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        quantity: json['quantity']?.toString(),
        notes: json['notes']?.toString(),
        loggedByName: json['logged_by_name']?.toString(),
      );
}

class DietPlan {
  final String dietType;
  final String? restrictions;
  final String? notes;

  const DietPlan({required this.dietType, this.restrictions, this.notes});

  factory DietPlan.fromJson(Map<String, dynamic> json) => DietPlan(
        dietType: json['diet_type']?.toString() ?? 'normal',
        restrictions: json['restrictions']?.toString(),
        notes: json['notes']?.toString(),
      );
}
