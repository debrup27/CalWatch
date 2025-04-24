import '../models/food_entry.dart';

class DummyData {
  static List<FoodEntry> getFoodEntries() {
    return [
      FoodEntry(
        id: '1',
        name: 'Oatmeal with Berries',
        calories: 320,
        dateTime: DateTime.now().subtract(const Duration(hours: 8)),
        mealType: 'Breakfast',
      ),
      FoodEntry(
        id: '2',
        name: 'Chicken Salad',
        calories: 450,
        dateTime: DateTime.now().subtract(const Duration(hours: 4)),
        mealType: 'Lunch',
      ),
      FoodEntry(
        id: '3',
        name: 'Protein Bar',
        calories: 180,
        dateTime: DateTime.now().subtract(const Duration(hours: 2)),
        mealType: 'Snack',
      ),
      FoodEntry(
        id: '4',
        name: 'Salmon with Vegetables',
        calories: 520,
        dateTime: DateTime.now().subtract(const Duration(hours: 1)),
        mealType: 'Dinner',
      ),
    ];
  }

  static int getTotalCaloriesToday() {
    final entries = getFoodEntries();
    final now = DateTime.now();
    final todayEntries = entries.where((entry) {
      return entry.dateTime.year == now.year &&
          entry.dateTime.month == now.month &&
          entry.dateTime.day == now.day;
    }).toList();
    
    return todayEntries.fold(0, (sum, entry) => sum + entry.calories);
  }
} 