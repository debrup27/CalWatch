class FoodEntry {
  final String id;
  final String name;
  final int calories;
  final DateTime dateTime;
  final String mealType; // breakfast, lunch, dinner, snack

  FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.dateTime,
    required this.mealType,
  });
} 