import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class StellarStreakTokenService {
  // Singleton pattern
  static final StellarStreakTokenService _instance = StellarStreakTokenService._internal();
  factory StellarStreakTokenService() => _instance;
  StellarStreakTokenService._internal();

  // StellarSDK instance
  final StellarSDK sdk = StellarSDK.TESTNET;
  
  // Storage keys
  static const String _issuerSeedKey = 'stellar_issuer_seed';
  static const String _issuerPublicKey = 'stellar_issuer_public';
  static const String _distributorSeedKey = 'stellar_distributor_seed';
  static const String _distributorPublicKey = 'stellar_distributor_public';
  static const String _userSeedKey = 'stellar_user_seed';
  static const String _userPublicKey = 'stellar_user_public';
  static const String _hasTrustlineKey = 'stellar_has_trustline';
  static const String _lastRewardedStreakKey = 'stellar_last_rewarded_streak';
  static const String _lastRewardedCycleKey = 'stellar_last_rewarded_cycle';
  
  // Token details
  static const String _tokenCode = 'STREAK';
  
  bool _isInitialized = false;
  bool _verificationCompleted = false;
  late KeyPair _issuerKeyPair;
  late KeyPair _distributorKeyPair;
  late KeyPair _userKeyPair;
  late Asset _streakToken;
  
  // Cache values
  bool? _userHasTrustline;
  String? _userTokenBalance;
  DateTime _lastLogTime = DateTime.now();
  
  // Rate limit logging
  void _rateLog(String message, {Object? error}) {
    final now = DateTime.now();
    if (now.difference(_lastLogTime).inMilliseconds > 500) { // Only log every 500ms
      developer.log(message, error: error);
      _lastLogTime = now;
    }
  }
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) {
      return; // Skip if already initialized
    }
    
    developer.log("[StellarService] Initializing Stellar service...");
    
    final prefs = await SharedPreferences.getInstance();
    
    // Check if issuer account exists
    if (!prefs.containsKey(_issuerSeedKey)) {
      developer.log("[StellarService] Creating new issuer account");
      // Create issuer account
      _issuerKeyPair = KeyPair.random();
      await prefs.setString(_issuerSeedKey, _issuerKeyPair.secretSeed);
      await prefs.setString(_issuerPublicKey, _issuerKeyPair.accountId);
      
      // Fund on testnet
      try {
        developer.log("[StellarService] Funding issuer account: ${_issuerKeyPair.accountId}");
        // Use the static method instead of creating an instance
        bool funded = await FriendBot.fundTestAccount(_issuerKeyPair.accountId);
        developer.log("[StellarService] Funded issuer account: ${_issuerKeyPair.accountId}, success: $funded");
        
        // Verify account exists only during initial setup
        try {
          final account = await sdk.accounts.account(_issuerKeyPair.accountId);
          developer.log("[StellarService] Issuer account verified: ${account.accountId}, Balance: ${_getBalanceInfo(account)}");
        } catch (e) {
          developer.log("[StellarService] ERROR: Issuer account verification failed: $e", error: e);
        }
      } catch (e) {
        developer.log("[StellarService] ERROR: Funding issuer account failed: $e", error: e);
      }
    } else {
      // Load existing issuer account
      final issuerSeed = prefs.getString(_issuerSeedKey)!;
      _issuerKeyPair = KeyPair.fromSecretSeed(issuerSeed);
      
      // Only verify on first run
      if (!_verificationCompleted) {
        developer.log("[StellarService] Loaded existing issuer account: ${_issuerKeyPair.accountId}");
        
        // Verify account exists
        try {
          final account = await sdk.accounts.account(_issuerKeyPair.accountId);
          developer.log("[StellarService] Issuer account verified: ${account.accountId}");
        } catch (e) {
          developer.log("[StellarService] WARNING: Issuer account might not exist: $e", error: e);
        }
      }
    }
    
    // Check if distributor account exists
    if (!prefs.containsKey(_distributorSeedKey)) {
      developer.log("[StellarService] Creating new distributor account");
      // Create distributor account
      _distributorKeyPair = KeyPair.random();
      await prefs.setString(_distributorSeedKey, _distributorKeyPair.secretSeed);
      await prefs.setString(_distributorPublicKey, _distributorKeyPair.accountId);
      
      // Fund on testnet
      try {
        developer.log("[StellarService] Funding distributor account: ${_distributorKeyPair.accountId}");
        // Use the static method instead of creating an instance
        bool funded = await FriendBot.fundTestAccount(_distributorKeyPair.accountId);
        developer.log("[StellarService] Funded distributor account: ${_distributorKeyPair.accountId}, success: $funded");
        
        // Verify account exists only during initial setup
        try {
          final account = await sdk.accounts.account(_distributorKeyPair.accountId);
          developer.log("[StellarService] Distributor account verified: ${account.accountId}");
        } catch (e) {
          developer.log("[StellarService] ERROR: Distributor account verification failed: $e", error: e);
        }
      } catch (e) {
        developer.log("[StellarService] ERROR: Funding distributor account failed: $e", error: e);
      }
      
      // Setup distribution account (after a delay to ensure funding completes)
      developer.log("[StellarService] Waiting 5 seconds before setting up distributor account...");
      await Future.delayed(Duration(seconds: 5));
      await _setupDistributorAccount();
    } else {
      // Load existing distributor account
      final distributorSeed = prefs.getString(_distributorSeedKey)!;
      _distributorKeyPair = KeyPair.fromSecretSeed(distributorSeed);
      
      // Only verify on first run
      if (!_verificationCompleted) {
        developer.log("[StellarService] Loaded existing distributor account: ${_distributorKeyPair.accountId}");
        
        // Verify account exists and has trustline
        try {
          final account = await sdk.accounts.account(_distributorKeyPair.accountId);
          developer.log("[StellarService] Distributor account verified");
        } catch (e) {
          developer.log("[StellarService] WARNING: Distributor account might not exist: $e", error: e);
        }
      }
    }
    
    // Check if user account exists
    if (!prefs.containsKey(_userSeedKey)) {
      developer.log("[StellarService] Creating new user account");
      // Create user account
      _userKeyPair = KeyPair.random();
      await prefs.setString(_userSeedKey, _userKeyPair.secretSeed);
      await prefs.setString(_userPublicKey, _userKeyPair.accountId);
      
      // Fund on testnet
      try {
        developer.log("[StellarService] Funding user account: ${_userKeyPair.accountId}");
        // Use the static method instead of creating an instance
        bool funded = await FriendBot.fundTestAccount(_userKeyPair.accountId);
        developer.log("[StellarService] Funded user account: ${_userKeyPair.accountId}, success: $funded");
        
        // Verify account exists only during initial setup
        try {
          final account = await sdk.accounts.account(_userKeyPair.accountId);
          developer.log("[StellarService] User account verified: ${account.accountId}");
        } catch (e) {
          developer.log("[StellarService] ERROR: User account verification failed: $e", error: e);
        }
      } catch (e) {
        developer.log("[StellarService] ERROR: Funding user account failed: $e", error: e);
      }
    } else {
      // Load existing user account
      final userSeed = prefs.getString(_userSeedKey)!;
      _userKeyPair = KeyPair.fromSecretSeed(userSeed);
      
      // Only verify on first run
      if (!_verificationCompleted) {
        developer.log("[StellarService] Loaded existing user account: ${_userKeyPair.accountId}");
        
        // Verify account exists - only once
        try {
          await sdk.accounts.account(_userKeyPair.accountId);
          developer.log("[StellarService] User account verified");
          
          // Check for trustline once and cache result
          _userHasTrustline = await _checkUserTrustline();
          developer.log("[StellarService] User has trustline: $_userHasTrustline");
        } catch (e) {
          developer.log("[StellarService] WARNING: User account might not exist: $e", error: e);
        }
      }
    }
    
    // Define streak token
    _streakToken = Asset.createNonNativeAsset(_tokenCode, _issuerKeyPair.accountId);
    
    // Set flags to avoid repeated initializations and verifications
    _isInitialized = true;
    _verificationCompleted = true;
    developer.log("[StellarService] Stellar Streak Token Service initialized successfully");
  }
  
  // Helper method to get balance information - minimize string concatenation
  String _getBalanceInfo(AccountResponse account) {
    List<String> balances = [];
    for (Balance balance in account.balances) {
      if (balance.assetType == 'native') {
        balances.add("XLM: ${balance.balance}");
      } else {
        balances.add("${balance.assetCode}: ${balance.balance}");
      }
    }
    return balances.isEmpty ? "No balances found" : balances.join(", ");
  }
  
  // Set up the distributor account with trustline and initial tokens
  Future<void> _setupDistributorAccount() async {
    developer.log("[StellarService] Setting up distributor account with trustline and initial tokens");
    try {
      // 1. Create trustline
      developer.log("[StellarService] Getting distributor account for trustline creation");
      final distributorAccount = await sdk.accounts.account(_distributorKeyPair.accountId);
      
      final changeTrustOperation = ChangeTrustOperationBuilder(_streakToken, "100000")
          .build();
      
      final Transaction transaction = TransactionBuilder(distributorAccount)
          .addOperation(changeTrustOperation)
          .build();
      
      transaction.sign(_distributorKeyPair, Network.TESTNET);
      final response = await sdk.submitTransaction(transaction);
      developer.log("[StellarService] Distributor trustline created: ${response.success}");
      
      if (!response.success) {
        // Handle case where extras or its properties might be null
        final resultCodes = response.extras?.resultCodes?.operationsResultCodes != null 
            ? response.extras!.resultCodes!.operationsResultCodes.toString()
            : "unknown error";
        developer.log("[StellarService] ERROR: Failed to create distributor trustline: $resultCodes", 
            error: response.extras?.resultCodes?.operationsResultCodes);
        return;
      }
      
      // Wait a moment to ensure trustline is created
      await Future.delayed(Duration(seconds: 2));
      
      // 2. Issue initial tokens to distributor account
      developer.log("[StellarService] Getting issuer account for token issuance");
      final issuerAccount = await sdk.accounts.account(_issuerKeyPair.accountId);
      
      final paymentOperation = PaymentOperationBuilder(
          _distributorKeyPair.accountId, 
          _streakToken, 
          "50000"
      ).build();
      
      final issueTransaction = TransactionBuilder(issuerAccount)
          .addOperation(paymentOperation)
          .build();
      
      issueTransaction.sign(_issuerKeyPair, Network.TESTNET);
      final issueResponse = await sdk.submitTransaction(issueTransaction);
      developer.log("[StellarService] Initial tokens issued to distributor: ${issueResponse.success}");
      
      if (!issueResponse.success) {
        // Handle case where extras or its properties might be null
        final resultCodes = issueResponse.extras?.resultCodes?.operationsResultCodes != null 
            ? issueResponse.extras!.resultCodes!.operationsResultCodes.toString()
            : "unknown error";
        developer.log("[StellarService] ERROR: Failed to issue initial tokens: $resultCodes", 
            error: issueResponse.extras?.resultCodes?.operationsResultCodes);
      }
    } catch (e) {
      developer.log("[StellarService] ERROR: Failed to set up distributor account: $e", error: e);
    }
  }
  
  // Add this new method after _setupDistributorAccount() method
  Future<bool> setupDistributorTokens() async {
    developer.log("[StellarService] Manually setting up distributor tokens");
    
    try {
      // 1. Create trustline
      developer.log("[StellarService] Getting distributor account for trustline creation");
      final distributorAccount = await sdk.accounts.account(_distributorKeyPair.accountId);
      
      // Check if trustline already exists
      bool hasTrustline = false;
      for (Balance balance in distributorAccount.balances) {
        if (balance.assetType != 'native' && 
            balance.assetCode == _tokenCode && 
            balance.assetIssuer == _issuerKeyPair.accountId) {
          hasTrustline = true;
          developer.log("[StellarService] Distributor trustline already exists");
          break;
        }
      }
      
      // If no trustline, create one
      if (!hasTrustline) {
        developer.log("[StellarService] Creating distributor trustline");
        final changeTrustOperation = ChangeTrustOperationBuilder(_streakToken, "100000").build();
        
        final transaction = TransactionBuilder(distributorAccount)
            .addOperation(changeTrustOperation)
            .build();
        
        transaction.sign(_distributorKeyPair, Network.TESTNET);
        final response = await sdk.submitTransaction(transaction);
        
        if (!response.success) {
          final resultCodes = response.extras?.resultCodes?.operationsResultCodes != null 
              ? response.extras!.resultCodes!.operationsResultCodes.toString()
              : "unknown error";
          developer.log("[StellarService] ERROR: Failed to create distributor trustline: $resultCodes", 
              error: response.extras?.resultCodes?.operationsResultCodes);
          return false;
        }
        
        // Wait a moment to ensure trustline is created
        await Future.delayed(Duration(seconds: 2));
      }
      
      // 2. Issue tokens to distributor account
      developer.log("[StellarService] Getting issuer account for token issuance");
      final issuerAccount = await sdk.accounts.account(_issuerKeyPair.accountId);
      
      final paymentOperation = PaymentOperationBuilder(
          _distributorKeyPair.accountId, 
          _streakToken, 
          "50000"
      ).build();
      
      final issueTransaction = TransactionBuilder(issuerAccount)
          .addOperation(paymentOperation)
          .build();
      
      issueTransaction.sign(_issuerKeyPair, Network.TESTNET);
      final issueResponse = await sdk.submitTransaction(issueTransaction);
      
      if (!issueResponse.success) {
        final resultCodes = issueResponse.extras?.resultCodes?.operationsResultCodes != null 
            ? issueResponse.extras!.resultCodes!.operationsResultCodes.toString()
            : "unknown error";
        developer.log("[StellarService] ERROR: Failed to issue tokens: $resultCodes", 
            error: issueResponse.extras?.resultCodes?.operationsResultCodes);
        return false;
      }
      
      developer.log("[StellarService] Successfully issued tokens to distributor");
      return true;
    } catch (e) {
      developer.log("[StellarService] ERROR: Failed to set up distributor tokens: $e", error: e);
      return false;
    }
  }
  
  // Internal method for checking trustline - no logging
  Future<bool> _checkUserTrustline() async {
    try {
      final userAccount = await sdk.accounts.account(_userKeyPair.accountId);
      
      for (Balance balance in userAccount.balances) {
        if (balance.assetType != 'native' && 
            balance.assetCode == _tokenCode && 
            balance.assetIssuer == _issuerKeyPair.accountId) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Setup trustline for user if it doesn't exist
  Future<bool> setupUserTrustline() async {
    _rateLog("[StellarService] Setting up user trustline");
    if (!_isInitialized) {
      await initialize();
    }
    
    final prefs = await SharedPreferences.getInstance();
    final hasTrustline = prefs.getBool(_hasTrustlineKey) ?? false;
    
    if (hasTrustline) {
      _userHasTrustline = true;
      return true;
    }
    
    try {
      _rateLog("[StellarService] Getting user account for trustline creation");
      final userAccount = await sdk.accounts.account(_userKeyPair.accountId);
      
      final changeTrustOperation = ChangeTrustOperationBuilder(_streakToken, "1000")
          .build();
      
      final transaction = TransactionBuilder(userAccount)
          .addOperation(changeTrustOperation)
          .build();
      
      transaction.sign(_userKeyPair, Network.TESTNET);
      final response = await sdk.submitTransaction(transaction);
      
      if (response.success) {
        developer.log("[StellarService] User trustline created successfully");
        await prefs.setBool(_hasTrustlineKey, true);
        _userHasTrustline = true;
        return true;
      } else {
        // Handle case where extras or its properties might be null
        final resultCodes = response.extras?.resultCodes?.operationsResultCodes != null 
            ? response.extras!.resultCodes!.operationsResultCodes.toString()
            : "unknown error";
        developer.log("[StellarService] ERROR: Failed to create user trustline: $resultCodes", 
            error: response.extras?.resultCodes?.operationsResultCodes);
        _userHasTrustline = false;
        return false;
      }
    } catch (e) {
      developer.log("[StellarService] ERROR: Failed to set up user trustline: $e", error: e);
      return false;
    }
  }
  
  // Check if user already has a trustline - use cached value when possible
  Future<bool> hasUserTrustline() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Return cached value if available
    if (_userHasTrustline != null) {
      return _userHasTrustline!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    bool hasTrustlineCached = prefs.getBool(_hasTrustlineKey) ?? false;
    
    // If we've already confirmed a trustline, return true
    if (hasTrustlineCached) {
      _userHasTrustline = true;
      return true;
    }
    
    // Check network only when necessary
    _userHasTrustline = await _checkUserTrustline();
    
    // Update cache if found
    if (_userHasTrustline!) {
      await prefs.setBool(_hasTrustlineKey, true);
    }
    
    return _userHasTrustline!;
  }
  
  // Get token balance for user - cache result
  Future<String> getUserTokenBalance() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final hasTrustline = await hasUserTrustline();
      if (!hasTrustline) {
        _userTokenBalance = "0";
        return "0";
      }
      
      // Return cached value if it exists
      if (_userTokenBalance != null) {
        return _userTokenBalance!;
      }
      
      final userAccount = await sdk.accounts.account(_userKeyPair.accountId);
      
      for (Balance balance in userAccount.balances) {
        if (balance.assetType != 'native' && 
            balance.assetCode == _tokenCode && 
            balance.assetIssuer == _issuerKeyPair.accountId) {
          _userTokenBalance = balance.balance;
          return balance.balance;
        }
      }
      _userTokenBalance = "0";
      return "0";
    } catch (e) {
      _rateLog("[StellarService] ERROR: Failed to get user token balance: $e", error: e);
      return "0";
    }
  }
  
  // Issue streak tokens to user based on streak milestone
  Future<bool> rewardUserForStreak(int streakDays) async {
    developer.log("[StellarService] Attempting to reward user for streak of $streakDays days");
    if (!_isInitialized) {
      await initialize();
    }
    
    final prefs = await SharedPreferences.getInstance();
    final lastRewardedStreak = prefs.getInt(_lastRewardedStreakKey) ?? 0;
    final lastRewardedCycle = prefs.getString(_lastRewardedCycleKey) ?? '';
    
    // Get the current streak cycle identifier (based on when the streak started)
    final cycleId = await _getCurrentStreakCycleId();
    
    // Don't reward if this is the same streak cycle we already rewarded
    if (streakDays == lastRewardedStreak && cycleId == lastRewardedCycle) {
      _rateLog("[StellarService] User already rewarded for this streak cycle: $streakDays in cycle $cycleId");
      return false;
    }
    
    // Check if this is a milestone worth rewarding
    if (streakDays != 3 && streakDays != 7 && streakDays != 30) {
      _rateLog("[StellarService] Not a reward milestone: $streakDays");
      return false;
    }
    
    // Ensure user has a trustline
    final hasTrustline = await hasUserTrustline();
    if (!hasTrustline) {
      developer.log("[StellarService] User has no trustline, attempting to create one");
      final trustlineCreated = await setupUserTrustline();
      if (!trustlineCreated) {
        developer.log("[StellarService] ERROR: Failed to create trustline for user");
        return false;
      }
    }
    
    try {
      // Determine token amount based on streak milestone
      String tokenAmount = "1"; // Default for 3-day streak
      if (streakDays >= 7) tokenAmount = "3";
      if (streakDays >= 30) tokenAmount = "10";
      
      developer.log("[StellarService] Reward amount: $tokenAmount STREAK tokens");
      
      // Load distributor account to verify it has enough tokens
      final distributorAccount = await sdk.accounts.account(_distributorKeyPair.accountId);
      
      // Check distributor balance
      bool hasEnoughTokens = false;
      String currentBalance = "0";
      for (Balance balance in distributorAccount.balances) {
        if (balance.assetType != 'native' && 
            balance.assetCode == _tokenCode && 
            balance.assetIssuer == _issuerKeyPair.accountId) {
          currentBalance = balance.balance;
          if (double.parse(balance.balance) >= double.parse(tokenAmount)) {
            hasEnoughTokens = true;
          }
          break;
        }
      }
      
      if (!hasEnoughTokens) {
        developer.log("[StellarService] ERROR: Distributor doesn't have enough tokens. Has: $currentBalance, needs: $tokenAmount");
        return false;
      }
      
      // Send tokens from distributor to user
      final paymentOperation = PaymentOperationBuilder(
          _userKeyPair.accountId, 
          _streakToken, 
          tokenAmount
      ).build();
      
      final transaction = TransactionBuilder(distributorAccount)
          .addOperation(paymentOperation)
          .build();
      
      transaction.sign(_distributorKeyPair, Network.TESTNET);
      final response = await sdk.submitTransaction(transaction);
      
      if (response.success) {
        developer.log("[StellarService] Successfully rewarded user with $tokenAmount STREAK tokens");
        
        // Store both the streak milestone and the cycle ID
        await prefs.setInt(_lastRewardedStreakKey, streakDays);
        await prefs.setString(_lastRewardedCycleKey, cycleId);
        
        // Clear cached balance so it will be refreshed next time
        _userTokenBalance = null;
        
        return true;
      } else {
        // Handle case where extras or its properties might be null
        final resultCodes = response.extras?.resultCodes?.operationsResultCodes != null 
            ? response.extras!.resultCodes!.operationsResultCodes.toString()
            : "unknown error";
        developer.log("[StellarService] ERROR: Failed to send tokens to user: $resultCodes", 
            error: response.extras?.resultCodes?.operationsResultCodes);
        return false;
      }
    } catch (e) {
      developer.log("[StellarService] ERROR: Failed to reward user: $e", error: e);
      return false;
    }
  }
  
  // Helper method to get the current streak cycle identifier
  Future<String> _getCurrentStreakCycleId() async {
    try {
      // Use the SharedPreferences to get the last date the streak was reset to 0
      final prefs = await SharedPreferences.getInstance();
      final lastStreakDateString = prefs.getString('last_streak_date') ?? DateTime.now().toIso8601String();
      
      // Use the last streak date as the basis for the cycle ID
      final lastStreakDate = DateTime.parse(lastStreakDateString);
      
      // Create a cycle ID that changes when a streak is broken
      // This is necessary so we can reward users again for the same milestone in different cycles
      return '${lastStreakDate.year}${lastStreakDate.month}${lastStreakDate.day}';
    } catch (e) {
      // If there's an error, use the current date as a fallback
      final now = DateTime.now();
      return '${now.year}${now.month}${now.day}';
    }
  }
  
  // Get account information
  Future<Map<String, String>> getAccountInfo() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return {
      'issuerAccount': _issuerKeyPair.accountId,
      'distributorAccount': _distributorKeyPair.accountId,
      'userAccount': _userKeyPair.accountId,
      'assetCode': _tokenCode,
      'userHasTrustline': (await hasUserTrustline()).toString(),
      'userTokenBalance': await getUserTokenBalance(),
    };
  }
  
  // Debug method to verify all accounts - only call this when needed
  Future<Map<String, dynamic>> verifyAccounts() async {
    developer.log("[StellarService] Running full account verification");
    if (!_isInitialized) {
      await initialize();
    }
    
    final result = <String, dynamic>{};
    
    try {
      // Check issuer account
      try {
        final issuerAccount = await sdk.accounts.account(_issuerKeyPair.accountId);
        result['issuerExists'] = true;
        result['issuerBalance'] = _getBalanceInfo(issuerAccount);
      } catch (e) {
        result['issuerExists'] = false;
        result['issuerError'] = e.toString();
      }
      
      // Check distributor account
      try {
        final distributorAccount = await sdk.accounts.account(_distributorKeyPair.accountId);
        result['distributorExists'] = true;
        result['distributorBalance'] = _getBalanceInfo(distributorAccount);
        
        // Check for trustline
        bool hasTrustline = false;
        for (Balance balance in distributorAccount.balances) {
          if (balance.assetType != 'native' && 
              balance.assetCode == _tokenCode && 
              balance.assetIssuer == _issuerKeyPair.accountId) {
            hasTrustline = true;
            result['distributorTokenBalance'] = balance.balance;
            break;
          }
        }
        result['distributorHasTrustline'] = hasTrustline;
      } catch (e) {
        result['distributorExists'] = false;
        result['distributorError'] = e.toString();
      }
      
      // Check user account
      try {
        final userAccount = await sdk.accounts.account(_userKeyPair.accountId);
        result['userExists'] = true;
        result['userBalance'] = _getBalanceInfo(userAccount);
        
        // Check for trustline
        bool hasTrustline = false;
        for (Balance balance in userAccount.balances) {
          if (balance.assetType != 'native' && 
              balance.assetCode == _tokenCode && 
              balance.assetIssuer == _issuerKeyPair.accountId) {
            hasTrustline = true;
            result['userTokenBalance'] = balance.balance;
            break;
          }
        }
        result['userHasTrustline'] = hasTrustline;
      } catch (e) {
        result['userExists'] = false;
        result['userError'] = e.toString();
      }
      
      // Get cached values
      final prefs = await SharedPreferences.getInstance();
      result['cachedHasTrustline'] = prefs.getBool(_hasTrustlineKey) ?? false;
      result['lastRewardedStreak'] = prefs.getInt(_lastRewardedStreakKey) ?? 0;
      
    } catch (e) {
      result['verificationError'] = e.toString();
    }
    
    return result;
  }

  // Add this method in the public methods section
  Future<Map<String, dynamic>> repairDistributorAccount() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // First verify the accounts to see if there's a problem
    final verification = await verifyAccounts();
    final result = <String, dynamic>{};
    result['before'] = verification;
    
    // Check if distributor has a trustline
    if (verification['distributorExists'] == true && 
        verification['distributorHasTrustline'] == false) {
      developer.log("[StellarService] Repairing distributor account - creating trustline");
      
      // Call the method to setup the distributor tokens
      final success = await setupDistributorTokens();
      result['repairAttempted'] = true;
      result['repairSuccess'] = success;
      
      if (success) {
        // Verify again to confirm the fix worked
        await Future.delayed(Duration(seconds: 2)); // Give the network time
        final afterVerification = await verifyAccounts();
        result['after'] = afterVerification;
        
        developer.log("[StellarService] Distributor account repair ${afterVerification['distributorHasTrustline'] == true ? 'succeeded' : 'failed'}");
      }
    } else {
      result['repairAttempted'] = false;
      result['message'] = 'No repair needed or distributor account does not exist';
    }
    
    return result;
  }

  // Public method to get current streak cycle ID
  Future<String> getCurrentStreakCycleId() async {
    return _getCurrentStreakCycleId();
  }
} 