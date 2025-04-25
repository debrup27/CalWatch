import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StreakService {
  // Singleton pattern
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();
  
  // Shared Preferences keys
  static const String _streakCountKey = 'streak_count';
  static const String _lastStreakDateKey = 'last_streak_date';
  static const String _streakHistoryKey = 'streak_history';
  static const String _penaltyActiveKey = 'penalty_active';
  static const String _missedDateKey = 'missed_date';
  
  // Daily goal tolerance range
  static const int _nutrientToleranceRange = 50;
  
  // Get current streak count
  Future<int> getStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakCountKey) ?? 0;
  }
  
  // Get last streak date
  Future<DateTime?> getLastStreakDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastStreakDateKey);
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }
  
  // Check if penalty is active
  Future<bool> isPenaltyActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_penaltyActiveKey) ?? false;
  }
  
  // Get the date when goal was missed
  Future<DateTime?> getMissedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_missedDateKey);
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }
  
  // Check if user is on streak
  Future<bool> isOnStreak() async {
    final lastDate = await getLastStreakDate();
    if (lastDate == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    // User is on streak if they met goals yesterday or today
    return lastDate.isAtSameMomentAs(today) || lastDate.isAtSameMomentAs(yesterday);
  }
  
  // Check if the user met their nutrition goals for the day
  bool metNutritionGoals(Map<String, dynamic> nutritionData) {
    // Extract all nutrient values and goals
    final caloriesConsumed = nutritionData['calories']['consumed'] as double;
    final calorieGoal = nutritionData['calories']['goal'] as double;
    
    final proteinConsumed = nutritionData['protein']['consumed'] as double;
    final proteinGoal = nutritionData['protein']['goal'] as double;
    
    final carbsConsumed = nutritionData['carbohydrates']['consumed'] as double;
    final carbsGoal = nutritionData['carbohydrates']['goal'] as double;
    
    final fatConsumed = nutritionData['fat']['consumed'] as double;
    final fatGoal = nutritionData['fat']['goal'] as double;
    
    // Check if all nutrients are within tolerance range (±50) of their goals
    final caloriesInRange = (caloriesConsumed >= calorieGoal - _nutrientToleranceRange) && 
                            (caloriesConsumed <= calorieGoal + _nutrientToleranceRange);
    
    final proteinInRange = (proteinConsumed >= proteinGoal - _nutrientToleranceRange) && 
                           (proteinConsumed <= proteinGoal + _nutrientToleranceRange);
    
    final carbsInRange = (carbsConsumed >= carbsGoal - _nutrientToleranceRange) && 
                         (carbsConsumed <= carbsGoal + _nutrientToleranceRange);
    
    final fatInRange = (fatConsumed >= fatGoal - _nutrientToleranceRange) && 
                       (fatConsumed <= fatGoal + _nutrientToleranceRange);
    
    // All nutrients must be within range to meet goals
    return caloriesInRange && proteinInRange && carbsInRange && fatInRange;
  }
  
  // Update streak based on today's nutrition data
  Future<Map<String, dynamic>> updateStreak(Map<String, dynamic> nutritionData) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if goals were met using the updated method
    final goalsMet = metNutritionGoals(nutritionData);
    
    // Get current streak count and last update date
    final currentStreak = await getStreakCount();
    final lastStreakDate = await getLastStreakDate();
    final isPenalty = await isPenaltyActive();
    
    // Initialize new streak and if it changed
    int newStreak = currentStreak;
    bool streakChanged = false;
    
    if (goalsMet) {
      // Goals were met today
      if (lastStreakDate == null) {
        // First time meeting goals
        newStreak = 1;
        streakChanged = true;
        await prefs.setBool(_penaltyActiveKey, false);
      } else if (lastStreakDate.isAtSameMomentAs(today)) {
        // Already updated today, no change
        newStreak = currentStreak;
        streakChanged = false;
      } else if (lastStreakDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
        // Last update was yesterday, check for penalty
        if (isPenalty) {
          // Penalty active, don't increment streak but remove penalty
          await prefs.setBool(_penaltyActiveKey, false);
          streakChanged = true; // Mark changed to update history
        } else {
          // No penalty, increment streak normally
          newStreak = currentStreak + 1;
          streakChanged = true;
        }
      } else {
        // Last update was more than a day ago
        if (currentStreak > 0) {
          // Missed at least one day, apply penalty logic
          final missedDate = await getMissedDate();
          if (missedDate != null && missedDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
            // Yesterday's goal was missed, today's is met, but don't increment due to penalty
            newStreak = 1; // Reset to 1 since they're starting fresh
            await prefs.setBool(_penaltyActiveKey, false); // Remove penalty after serving it
          } else {
            // Multiple days missed or different pattern, reset streak
            newStreak = 1;
            await prefs.setBool(_penaltyActiveKey, false);
          }
        } else {
          // Streak was already 0, just start fresh
          newStreak = 1;
          await prefs.setBool(_penaltyActiveKey, false);
        }
        streakChanged = true;
      }
      
      // Update last streak date to today
      if (streakChanged) {
        await prefs.setString(_lastStreakDateKey, today.toIso8601String());
        await prefs.setInt(_streakCountKey, newStreak);
        
        // Update streak history
        _updateStreakHistory(today, newStreak);
      }
    } else {
      // Goals were NOT met today
      if (lastStreakDate != null && 
          !lastStreakDate.isAtSameMomentAs(today) && 
          currentStreak > 0) {
        // This breaks the streak - reset and activate penalty
        newStreak = 0;
        await prefs.setInt(_streakCountKey, newStreak);
        await prefs.setString(_lastStreakDateKey, today.toIso8601String());
        await prefs.setBool(_penaltyActiveKey, true); // Activate penalty
        await prefs.setString(_missedDateKey, today.toIso8601String()); // Record missed date
        streakChanged = true;
        
        // Update streak history
        _updateStreakHistory(today, newStreak);
      }
    }
    
    return {
      'streakCount': newStreak,
      'isOnStreak': await isOnStreak(),
      'streakChanged': streakChanged,
      'goalsMet': goalsMet,
      'penaltyActive': await isPenaltyActive()
    };
  }
  
  // Update streak history in shared preferences
  Future<void> _updateStreakHistory(DateTime date, int streakCount) async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_streakHistoryKey);
    
    List<Map<String, dynamic>> history = [];
    if (historyString != null) {
      final List<dynamic> decoded = json.decode(historyString);
      history = decoded.map<Map<String, dynamic>>((item) => 
        Map<String, dynamic>.from(item)
      ).toList();
    }
    
    // Add new entry
    history.add({
      'date': date.toIso8601String(),
      'streak': streakCount
    });
    
    // Limit history to last 30 days
    if (history.length > 30) {
      history = history.sublist(history.length - 30);
    }
    
    // Save updated history
    await prefs.setString(_streakHistoryKey, json.encode(history));
  }
  
  // Get streak history
  Future<List<Map<String, dynamic>>> getStreakHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_streakHistoryKey);
    
    if (historyString == null) return [];
    
    final List<dynamic> decoded = json.decode(historyString);
    return decoded.map<Map<String, dynamic>>((item) => 
      Map<String, dynamic>.from(item)
    ).toList();
  }
  
  // Get penalty status with detailed information
  Future<Map<String, dynamic>> getPenaltyStatus() async {
    final isPenalty = await isPenaltyActive();
    final missedDate = await getMissedDate();
    
    return {
      'isPenaltyActive': isPenalty,
      'missedDate': missedDate?.toIso8601String(),
      'reason': isPenalty ? 'Missed daily nutrition goals' : null,
      'message': isPenalty ? 'Complete today\'s goals to clear penalty' : null
    };
  }
  
  // Reset streak (for debugging or admin purposes)
  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_streakCountKey);
    await prefs.remove(_lastStreakDateKey);
    await prefs.remove(_penaltyActiveKey);
    await prefs.remove(_missedDateKey);
  }
} 