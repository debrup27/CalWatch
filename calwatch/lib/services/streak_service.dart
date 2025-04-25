import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'monad_service.dart';

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
  static const String _blockchainRecordsKey = 'blockchain_records';
  static const String _lastSyncDateKey = 'last_blockchain_sync_date';
  
  // Daily goal tolerance range
  static const int _nutrientToleranceRange = 50;
  
  // Get current streak count
  Future<int> getStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakCountKey) ?? 0;
  }
  
  // Sync local streak with blockchain if needed
  Future<void> syncWithBlockchain() async {
    try {
      final monadService = MonadService();
      
      // Check if wallet is set up
      final isWalletSetup = await monadService.isWalletSetup();
      if (!isWalletSetup) {
        print('Wallet not set up, skipping blockchain sync');
        return;
      }
      
      // Initialize blockchain service
      await monadService.initialize();
      
      // Get blockchain streak
      final blockchainStreak = await monadService.getStreakFromContract();
      
      // Get local streak
      final localStreak = await getStreakCount();
      
      // Get last action day from blockchain
      final lastActionDay = await monadService.getLastActionDayFromContract();
      
      // Get current day
      final today = DateTime.now().millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
      
      print('Blockchain streak: $blockchainStreak, Local streak: $localStreak, Last action day: $lastActionDay, Today: $today');
      
      // Update local streak if blockchain has a newer record
      final prefs = await SharedPreferences.getInstance();
      if (blockchainStreak != localStreak) {
        await prefs.setInt(_streakCountKey, blockchainStreak);
        print('Updated local streak from blockchain: $blockchainStreak');
      }
      
      // Record last sync date
      await prefs.setString(_lastSyncDateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error syncing with blockchain: $e');
    }
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
    // First sync with blockchain to make sure we have the latest streak data
    await syncWithBlockchain();
    
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
        
        // Record on blockchain if streak changed (only if goals were met)
        final blockchainRecord = await _recordStreakOnBlockchain(newStreak, goalsMet, today);
        if (blockchainRecord != null) {
          _saveBlockchainRecord(today, newStreak, blockchainRecord);
          
          // After recording, sync again to ensure we have latest blockchain data
          await syncWithBlockchain();
        }
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
        
        // No need to record to blockchain - streak breaks are handled automatically
        // by the smart contract when the next recordAction is called
      }
    }
    
    // Check if we have any blockchain records
    final blockchainRecords = await getBlockchainRecords();
    
    // Get current streak from blockchain (may differ from local)
    int onChainStreak = newStreak;
    bool hasWallet = false;
    try {
      final monadService = MonadService();
      hasWallet = await monadService.isWalletSetup();
      if (hasWallet) {
        await monadService.initialize();
        onChainStreak = await monadService.getStreakFromContract();
      }
    } catch (e) {
      print('Error getting blockchain streak: $e');
    }
    
    return {
      'streakCount': newStreak,
      'blockchainStreak': onChainStreak,
      'isOnStreak': await isOnStreak(),
      'streakChanged': streakChanged,
      'goalsMet': goalsMet,
      'penaltyActive': await isPenaltyActive(),
      'hasBlockchainRecords': blockchainRecords.isNotEmpty,
      'latestBlockchainRecord': blockchainRecords.isNotEmpty ? blockchainRecords.last : null,
      'walletSetup': hasWallet,
    };
  }
  
  // Record streak on blockchain (if wallet is set up)
  Future<Map<String, dynamic>?> _recordStreakOnBlockchain(int streakCount, bool goalsMet, DateTime date) async {
    try {
      final monadService = MonadService();
      
      // Check if wallet is set up
      final isWalletSetup = await monadService.isWalletSetup();
      if (!isWalletSetup) {
        print('Wallet not set up, skipping blockchain recording');
        return null;
      }
      
      // Initialize blockchain service
      await monadService.initialize();
      
      // Record streak
      final txHash = await monadService.recordStreak(streakCount, goalsMet, date);
      
      // Return transaction details
      final address = await monadService.getWalletAddress();
      
      return {
        'txHash': txHash,
        'walletAddress': address,
        'streakCount': streakCount,
        'goalsMet': goalsMet,
        'timestamp': DateTime.now().toIso8601String(),
        'recordedDate': date.toIso8601String(),
      };
    } catch (e) {
      print('Error recording streak on blockchain: $e');
      return null;
    }
  }
  
  // Save blockchain record
  Future<void> _saveBlockchainRecord(DateTime date, int streakCount, Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getString(_blockchainRecordsKey);
    
    List<Map<String, dynamic>> records = [];
    if (recordsJson != null) {
      final decoded = json.decode(recordsJson) as List<dynamic>;
      records = decoded.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
    }
    
    // Add new record
    records.add(record);
    
    // Store records
    await prefs.setString(_blockchainRecordsKey, json.encode(records));
  }
  
  // Get blockchain records
  Future<List<Map<String, dynamic>>> getBlockchainRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getString(_blockchainRecordsKey);
    
    if (recordsJson == null) return [];
    
    final decoded = json.decode(recordsJson) as List<dynamic>;
    return decoded.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
  }
  
  // Get last blockchain sync date
  Future<DateTime?> getLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastSyncDateKey);
    if (dateString == null) return null;
    return DateTime.parse(dateString);
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
    
    // Try to sync with blockchain to reset to blockchain state
    await syncWithBlockchain();
  }
  
  // DEBUGGING METHODS
  
  // Force increment streak by a given amount (for debugging)
  Future<Map<String, dynamic>> debugIncrementStreak([int amount = 1]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentStreak = await getStreakCount();
    final newStreak = currentStreak + amount;
    
    await prefs.setInt(_streakCountKey, newStreak);
    
    // Update last streak date to today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await prefs.setString(_lastStreakDateKey, today.toIso8601String());
    
    // Update streak history
    _updateStreakHistory(today, newStreak);
    
    // Record on blockchain if possible
    final blockchainRecord = await _recordStreakOnBlockchain(newStreak, true, today);
    if (blockchainRecord != null) {
      _saveBlockchainRecord(today, newStreak, blockchainRecord);
    }
    
    return {
      'previousStreak': currentStreak,
      'newStreak': newStreak,
      'change': amount,
      'date': today.toIso8601String(),
      'blockchainRecord': blockchainRecord
    };
  }
  
  // Force update streak from blockchain for debugging
  Future<Map<String, dynamic>> debugSyncWithBlockchain() async {
    final beforeStreak = await getStreakCount();
    await syncWithBlockchain();
    final afterStreak = await getStreakCount();
    
    return {
      'beforeSync': beforeStreak,
      'afterSync': afterStreak,
      'changed': beforeStreak != afterStreak,
      'syncDate': DateTime.now().toIso8601String(),
    };
  }
  
  // Force decrement streak by a given amount (for debugging)
  Future<Map<String, dynamic>> debugDecrementStreak([int amount = 1]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentStreak = await getStreakCount();
    final newStreak = (currentStreak - amount) < 0 ? 0 : currentStreak - amount;
    
    await prefs.setInt(_streakCountKey, newStreak);
    
    // Update last streak date to today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await prefs.setString(_lastStreakDateKey, today.toIso8601String());
    
    // Update streak history
    _updateStreakHistory(today, newStreak);
    
    // Record on blockchain if possible
    final blockchainRecord = await _recordStreakOnBlockchain(newStreak, false, today);
    if (blockchainRecord != null) {
      _saveBlockchainRecord(today, newStreak, blockchainRecord);
    }
    
    return {
      'previousStreak': currentStreak,
      'newStreak': newStreak,
      'change': -amount,
      'date': today.toIso8601String(),
      'blockchainRecord': blockchainRecord
    };
  }
  
  // Set streak to a specific value (for debugging)
  Future<Map<String, dynamic>> debugSetStreak(int value) async {
    final prefs = await SharedPreferences.getInstance();
    final currentStreak = await getStreakCount();
    final newStreak = value < 0 ? 0 : value;
    
    await prefs.setInt(_streakCountKey, newStreak);
    
    // Update last streak date to today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await prefs.setString(_lastStreakDateKey, today.toIso8601String());
    
    // Update streak history
    _updateStreakHistory(today, newStreak);
    
    // Record on blockchain if possible
    final blockchainRecord = await _recordStreakOnBlockchain(newStreak, true, today);
    if (blockchainRecord != null) {
      _saveBlockchainRecord(today, newStreak, blockchainRecord);
    }
    
    return {
      'previousStreak': currentStreak,
      'newStreak': newStreak,
      'change': newStreak - currentStreak,
      'date': today.toIso8601String(),
      'blockchainRecord': blockchainRecord
    };
  }
  
  // Toggle penalty status (for debugging)
  Future<Map<String, dynamic>> debugTogglePenalty() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPenalty = await isPenaltyActive();
    
    await prefs.setBool(_penaltyActiveKey, !currentPenalty);
    
    // If activating penalty, set missed date to yesterday
    if (!currentPenalty) {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      await prefs.setString(_missedDateKey, yesterday.toIso8601String());
    }
    
    return {
      'previousPenaltyStatus': currentPenalty,
      'newPenaltyStatus': !currentPenalty,
      'missedDate': !currentPenalty ? DateTime.now().subtract(const Duration(days: 1)).toIso8601String() : null
    };
  }
  
  // Get complete debug info (for debugging)
  Future<Map<String, dynamic>> debugGetStreakInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final streakCount = await getStreakCount();
    final lastStreakDate = await getLastStreakDate();
    final isPenalty = await isPenaltyActive();
    final missedDate = await getMissedDate();
    final streakHistory = await getStreakHistory();
    final blockchainRecords = await getBlockchainRecords();
    final lastSyncDate = await getLastSyncDate();
    
    // Try to get blockchain streak
    int? blockchainStreak;
    try {
      final monadService = MonadService();
      final hasWallet = await monadService.isWalletSetup();
      if (hasWallet) {
        await monadService.initialize();
        blockchainStreak = await monadService.getStreakFromContract();
      }
    } catch (e) {
      print('Error getting blockchain streak: $e');
    }
    
    return {
      'streakCount': streakCount,
      'blockchainStreak': blockchainStreak,
      'lastStreakDate': lastStreakDate?.toIso8601String(),
      'isPenaltyActive': isPenalty,
      'missedDate': missedDate?.toIso8601String(),
      'streakHistory': streakHistory,
      'isOnStreak': await isOnStreak(),
      'hasWallet': await MonadService().isWalletSetup(),
      'blockchainRecords': blockchainRecords,
      'lastSyncDate': lastSyncDate?.toIso8601String(),
      'rawKeys': {
        'streakCountKey': prefs.getInt(_streakCountKey),
        'lastStreakDateKey': prefs.getString(_lastStreakDateKey),
        'penaltyActiveKey': prefs.getBool(_penaltyActiveKey),
        'missedDateKey': prefs.getString(_missedDateKey),
        'lastSyncDateKey': prefs.getString(_lastSyncDateKey),
      }
    };
  }
} 