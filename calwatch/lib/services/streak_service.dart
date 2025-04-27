import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'monad_service.dart';
import 'stellar_service.dart';
import 'dart:developer' as developer;

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
  
  // Sync with blockchain but don't update local streak
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
      
      // Get blockchain streak (for logging purposes only)
      final blockchainStreak = await monadService.getStreakFromContract();
      
      // Get local streak
      final localStreak = await getStreakCount();
      
      // Get last action day from blockchain
      final lastActionDay = await monadService.getLastActionDayFromContract();
      
      // Get current day
      final today = DateTime.now().millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
      
      print('Blockchain streak: $blockchainStreak, Local streak: $localStreak, Last action day: $lastActionDay, Today: $today');
      
      // No longer update local streak from blockchain
      // Instead, we only record the sync date
      final prefs = await SharedPreferences.getInstance();
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
    final isPenalty = prefs.getBool(_penaltyActiveKey) ?? false;
    
    if (isPenalty) {
      // Get the missed date to check if a full day has passed
      final missedDateStr = prefs.getString(_missedDateKey);
      if (missedDateStr != null) {
        final missedDate = DateTime.parse(missedDateStr);
        final now = DateTime.now();
        
        // Only consider penalty active if the missed date is at least 24 hours ago
        // This prevents the penalty from showing right after midnight
        final timeSinceMissed = now.difference(missedDate);
        if (timeSinceMissed.inHours < 24) {
          // Less than 24 hours have passed since the goal was missed
          // So don't show the penalty yet
          return false;
        }
      }
    }
    
    return isPenalty;
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
    // Removed blockchain sync before updating streak
    // This decouples our local streak from blockchain
    
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
          
          // Removed sync with blockchain - we don't want to get values from it
        }
        
        // NEW: Check if this is a streak milestone that deserves Stellar token reward
        if (newStreak == 3 || newStreak == 7 || newStreak == 10 || 
            newStreak == 15 || newStreak == 21 || newStreak == 25 || newStreak == 30) {
          await _rewardStellarTokens(newStreak);
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
        
        // Still record to blockchain, but don't read values from it
        final blockchainRecord = await _recordStreakOnBlockchain(newStreak, goalsMet, today);
        if (blockchainRecord != null) {
          _saveBlockchainRecord(today, newStreak, blockchainRecord);
        }
      }
    }
    
    // Check if we have any blockchain records
    final blockchainRecords = await getBlockchainRecords();
    
    // Get current streak from blockchain (for reference only)
    int? onChainStreak;
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
    
    try {
      // Reset local streak to 0
      await prefs.setInt(_streakCountKey, 0);
      
      // Update last streak date to today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await prefs.setString(_lastStreakDateKey, today.toIso8601String());
      
      // Clear penalty and missed date
      await prefs.remove(_penaltyActiveKey);
      await prefs.remove(_missedDateKey);
      
      // Update streak history to record the reset
      _updateStreakHistory(today, 0);
      
      // Record the reset on blockchain for tracking purposes only
      final monadService = MonadService();
      final isWalletSetup = await monadService.isWalletSetup();
      
      if (isWalletSetup) {
        await monadService.initialize();
        // Still record to blockchain but don't use its value
        await monadService.recordStreak(0, false, today);
      }
      
      // Note that we're NOT syncing with blockchain after reset
      // This prevents the blockchain from affecting our local streak
    } catch (e) {
      print('Error resetting streak: $e');
    }
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
    
    // Clear penalty if it was active
    final isPenalty = await isPenaltyActive();
    if (isPenalty) {
      await prefs.setBool(_penaltyActiveKey, false);
      await prefs.remove(_missedDateKey);
    }
    
    // Update streak history
    _updateStreakHistory(today, newStreak);
    
    // Record on blockchain if possible, but don't sync back
    Map<String, dynamic>? blockchainRecord;
    try {
      blockchainRecord = await _recordStreakOnBlockchain(newStreak, true, today);
      if (blockchainRecord != null) {
        _saveBlockchainRecord(today, newStreak, blockchainRecord);
      }
    } catch (e) {
      print('Error recording to blockchain: $e');
      // Continue without blockchain recording
    }
    
    return {
      'previousStreak': currentStreak,
      'newStreak': newStreak,
      'change': amount,
      'date': today.toIso8601String(),
      'blockchainRecord': blockchainRecord,
      'penaltyRemoved': isPenalty
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
    
    // If streak is set to 0, activate penalty
    bool penaltyActivated = false;
    if (newStreak == 0 && currentStreak > 0) {
      await prefs.setBool(_penaltyActiveKey, true);
      await prefs.setString(_missedDateKey, today.toIso8601String());
      penaltyActivated = true;
    }
    
    // Update streak history
    _updateStreakHistory(today, newStreak);
    
    // Record on blockchain if possible, but don't sync back
    Map<String, dynamic>? blockchainRecord;
    try {
      blockchainRecord = await _recordStreakOnBlockchain(newStreak, false, today);
      if (blockchainRecord != null) {
        _saveBlockchainRecord(today, newStreak, blockchainRecord);
      }
    } catch (e) {
      print('Error recording to blockchain: $e');
      // Continue without blockchain recording
    }
    
    return {
      'previousStreak': currentStreak,
      'newStreak': newStreak,
      'change': -amount,
      'date': today.toIso8601String(),
      'blockchainRecord': blockchainRecord,
      'penaltyActivated': penaltyActivated
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
    
    // Handle penalty based on streak value
    bool penaltyActivated = false;
    bool penaltyRemoved = false;
    
    // Get current penalty status
    final isPenalty = await isPenaltyActive();
    
    if (newStreak == 0 && currentStreak > 0) {
      // Setting streak to 0 activates penalty
      await prefs.setBool(_penaltyActiveKey, true);
      await prefs.setString(_missedDateKey, today.toIso8601String());
      penaltyActivated = true;
    } else if (newStreak > 0 && isPenalty) {
      // Setting streak to > 0 removes penalty
      await prefs.setBool(_penaltyActiveKey, false);
      await prefs.remove(_missedDateKey);
      penaltyRemoved = true;
    }
    
    // Update streak history
    _updateStreakHistory(today, newStreak);
    
    // Record on blockchain if possible, but don't sync back
    Map<String, dynamic>? blockchainRecord;
    try {
      blockchainRecord = await _recordStreakOnBlockchain(newStreak, true, today);
      if (blockchainRecord != null) {
        _saveBlockchainRecord(today, newStreak, blockchainRecord);
      }
    } catch (e) {
      print('Error recording to blockchain: $e');
      // Continue without blockchain recording
    }
    
    return {
      'previousStreak': currentStreak,
      'newStreak': newStreak,
      'change': newStreak - currentStreak,
      'date': today.toIso8601String(),
      'blockchainRecord': blockchainRecord,
      'penaltyActivated': penaltyActivated,
      'penaltyRemoved': penaltyRemoved
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
  
  // Check if current streak matches reward milestone
  Future<bool> isAtRewardMilestone() async {
    final currentStreak = await getStreakCount();
    developer.log("[StreakService] Checking if streak $currentStreak is at reward milestone");
    return currentStreak == 3 || 
           currentStreak == 7 || 
           currentStreak == 10 || 
           currentStreak == 15 || 
           currentStreak == 21 || 
           currentStreak == 25 || 
           currentStreak == 30;
  }
  
  // Get token amount for specific streak day milestone
  int getTokenAmountForStreak(int streakDays) {
    if (streakDays == 3) return 1;
    if (streakDays == 7) return 3;
    if (streakDays == 10) return 4;
    if (streakDays == 15) return 5;
    if (streakDays == 21) return 7;
    if (streakDays == 25) return 8;
    if (streakDays == 30) return 10;
    return 0;
  }
  
  // NEW: Reward Stellar tokens for streak milestones
  Future<bool> _rewardStellarTokens(int streakDays) async {
    developer.log("[StreakService] Attempting to reward Stellar tokens for streak: $streakDays days");
    try {
      // Initialize Stellar service
      final stellarService = StellarStreakTokenService();
      developer.log("[StreakService] Initializing Stellar service");
      await stellarService.initialize();
      
      // Get current token balance before reward
      final beforeBalance = await stellarService.getUserTokenBalance();
      developer.log("[StreakService] Current token balance before reward: $beforeBalance");
      
      // Get account verification info
      developer.log("[StreakService] Verifying Stellar accounts");
      final accountInfo = await stellarService.verifyAccounts();
      developer.log("[StreakService] Account verification results: $accountInfo");
      
      // Determine token amount based on streak milestone
      int tokenAmount = getTokenAmountForStreak(streakDays);
      
      // Issue reward tokens based on streak milestone
      developer.log("[StreakService] Calling rewardUserForStreak method with $tokenAmount tokens");
      final success = await stellarService.rewardUserForStreak(streakDays);
      
      if (success) {
        // Get new balance
        final afterBalance = await stellarService.getUserTokenBalance();
        developer.log("[StreakService] Successfully rewarded user with $tokenAmount Stellar tokens for $streakDays day streak");
        developer.log("[StreakService] Balance before: $beforeBalance, Balance after: $afterBalance");
      } else {
        developer.log("[StreakService] Failed to reward user with Stellar tokens");
      }
      
      return success;
    } catch (e) {
      developer.log("[StreakService] Error rewarding Stellar tokens: $e", error: e);
      return false;
    }
  }
  
  // Get user's Stellar token balance
  Future<String> getStellarTokenBalance() async {
    try {
      developer.log("[StreakService] Getting Stellar token balance");
      final stellarService = StellarStreakTokenService();
      await stellarService.initialize();
      
      final balance = await stellarService.getUserTokenBalance();
      developer.log("[StreakService] Current token balance: $balance");
      return balance;
    } catch (e) {
      developer.log("[StreakService] Error getting Stellar token balance: $e", error: e);
      return "0";
    }
  }
  
  // Get Stellar account info
  Future<Map<String, String>> getStellarAccountInfo() async {
    try {
      developer.log("[StreakService] Getting Stellar account info");
      final stellarService = StellarStreakTokenService();
      await stellarService.initialize();
      
      final info = await stellarService.getAccountInfo();
      developer.log("[StreakService] Account info: $info");
      return info;
    } catch (e) {
      developer.log("[StreakService] Error getting Stellar account info: $e", error: e);
      return {};
    }
  }
  
  // Debug: Force reward for current streak (for testing)
  Future<Map<String, dynamic>> debugForceReward() async {
    try {
      developer.log("[StreakService] DEBUG: Forcing reward for current streak");
      final currentStreak = await getStreakCount();
      developer.log("[StreakService] Current streak: $currentStreak");
      
      // Create Stellar service
      final stellarService = StellarStreakTokenService();
      await stellarService.initialize();
      
      // Get account verification before reward
      final beforeInfo = await stellarService.verifyAccounts();
      developer.log("[StreakService] DEBUG: Account verification before reward: $beforeInfo");
      
      // Get token balance before reward
      final beforeBalance = await stellarService.getUserTokenBalance();
      developer.log("[StreakService] DEBUG: Token balance before reward: $beforeBalance");
      
      // Force reward regardless of milestone
      developer.log("[StreakService] DEBUG: Forcing reward for streak: $currentStreak");
      bool rewardSuccess = false;
      String rewardError = "";
      int tokenAmount = getTokenAmountForStreak(currentStreak);
      try {
        // First try regular milestone rewards
        rewardSuccess = await _rewardStellarTokens(currentStreak);
        if (!rewardSuccess) {
          // If that fails, try a supported milestone (for testing)
          int testMilestone = 3; // Use 3-day streak as test milestone
          tokenAmount = getTokenAmountForStreak(testMilestone);
          developer.log("[StreakService] DEBUG: Regular reward failed, trying with test milestone: $testMilestone (tokens: $tokenAmount)");
          rewardSuccess = await stellarService.rewardUserForStreak(testMilestone);
        }
      } catch (e) {
        rewardSuccess = false;
        rewardError = e.toString();
        developer.log("[StreakService] DEBUG: Error forcing reward: $e", error: e);
      }
      
      // Get account verification after reward
      final afterInfo = await stellarService.verifyAccounts();
      developer.log("[StreakService] DEBUG: Account verification after reward: $afterInfo");
      
      // Get token balance after reward
      final afterBalance = await stellarService.getUserTokenBalance();
      developer.log("[StreakService] DEBUG: Token balance after reward: $afterBalance");
      
      return {
        'streak': currentStreak,
        'tokenAmount': tokenAmount,
        'rewardSuccess': rewardSuccess,
        'rewardError': rewardError,
        'beforeBalance': beforeBalance,
        'afterBalance': afterBalance,
        'accountInfo': await stellarService.getAccountInfo(),
      };
    } catch (e) {
      developer.log("[StreakService] DEBUG: Error in debugForceReward: $e", error: e);
      return {
        'error': e.toString(),
      };
    }
  }
  
  // Debug: Verify the reward system
  Future<Map<String, dynamic>> debugVerifyRewardSystem() async {
    try {
      developer.log("[StreakService] DEBUG: Verifying reward system");
      final result = <String, dynamic>{};
      
      // Get current streak
      final currentStreak = await getStreakCount();
      result['currentStreak'] = currentStreak;
      
      // Include token amount
      final tokenAmount = getTokenAmountForStreak(currentStreak);
      result['tokenAmount'] = tokenAmount;
      
      // Create Stellar service
      final stellarService = StellarStreakTokenService();
      await stellarService.initialize();
      
      // Get account verification
      result['accountVerification'] = await stellarService.verifyAccounts();
      
      // Check if at milestone
      result['isAtMilestone'] = currentStreak == 3 || 
                               currentStreak == 7 || 
                               currentStreak == 10 || 
                               currentStreak == 15 || 
                               currentStreak == 21 || 
                               currentStreak == 25 || 
                               currentStreak == 30;
      
      // Get cached reward milestone
      final prefs = await SharedPreferences.getInstance();
      result['lastRewardedStreak'] = prefs.getInt('stellar_last_rewarded_streak') ?? 0;
      
      // Get the last rewarded cycle
      result['lastRewardedCycle'] = prefs.getString('stellar_last_rewarded_cycle') ?? '';
      
      // Get current streak cycle ID
      final currentCycleId = await stellarService.getCurrentStreakCycleId();
      result['currentCycleId'] = currentCycleId;
      
      // Check if eligible for reward - now we consider different streak cycles
      final bool isSameCycle = (result['lastRewardedStreak'] == currentStreak && 
                               result['lastRewardedCycle'] == currentCycleId);
      
      // Eligible if at a milestone and not rewarded in this cycle yet
      result['eligibleForReward'] = result['isAtMilestone'] && !isSameCycle;
      
      developer.log("[StreakService] DEBUG: Reward system verification: $result");
      
      return result;
    } catch (e) {
      developer.log("[StreakService] DEBUG: Error verifying reward system: $e", error: e);
      return {
        'error': e.toString(),
      };
    }
  }
  
  // Debug: Repair distributor account
  Future<Map<String, dynamic>> debugRepairDistributorAccount() async {
    try {
      developer.log("[StreakService] DEBUG: Repairing distributor account");
      
      // Create Stellar service
      final stellarService = StellarStreakTokenService();
      await stellarService.initialize();
      
      // Call repair function
      final result = await stellarService.repairDistributorAccount();
      
      developer.log("[StreakService] DEBUG: Distributor account repair result: $result");
      return result;
    } catch (e) {
      developer.log("[StreakService] DEBUG: Error repairing distributor account: $e", error: e);
      return {
        'error': e.toString(),
      };
    }
  }
  
  // Clear streak history
  Future<void> clearStreakHistory() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Clear the streak history but keep the current streak count
      await prefs.setString(_streakHistoryKey, json.encode([]));
      developer.log("[StreakService] Streak history cleared successfully");
    } catch (e) {
      developer.log("[StreakService] Error clearing streak history: $e", error: e);
      throw Exception('Failed to clear streak history: $e');
    }
  }
} 