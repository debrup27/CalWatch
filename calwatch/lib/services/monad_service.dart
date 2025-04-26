import 'dart:convert';
import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MonadService {
  // Singleton pattern
  static final MonadService _instance = MonadService._internal();
  factory MonadService() => _instance;
  MonadService._internal();
  
  // Monad testnet RPC endpoint
  static const String _rpcUrl = 'https://testnet-rpc.monad.xyz';
  
  // Chain ID for Monad testnet
  static const int _chainId = 10143; // Monad testnet chain ID
  
  // StreakTracker contract address - REPLACE THIS WITH YOUR ACTUAL DEPLOYED CONTRACT ADDRESS
  static const String _streakTrackerContractAddress = '0xdD2a894bf5612A8cEdcC5D0f2b7F6f1539f2A4Be';
  
  // Storage keys for wallet data
  static const String _privateKeyKey = 'monad_private_key';
  static const String _walletAddressKey = 'monad_wallet_address';
  
  // Web3 client
  late Web3Client _client;
  bool _isInitialized = false;
  
  // Initialize web3 client
  Future<void> initialize() async {
    if (!_isInitialized) {
      final httpClient = http.Client();
      _client = Web3Client(_rpcUrl, httpClient);
      _isInitialized = true;
    }
  }
  
  // Check if wallet is set up
  Future<bool> isWalletSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_privateKeyKey);
  }
  
  // Store private key securely
  Future<void> storePrivateKey(String privateKey) async {
    // Remove 0x prefix if present
    final cleanKey = privateKey.startsWith('0x') ? privateKey.substring(2) : privateKey;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_privateKeyKey, cleanKey);
    
    // Generate and store address
    final credentials = EthPrivateKey.fromHex(cleanKey);
    await prefs.setString(_walletAddressKey, credentials.address.hex);
  }
  
  // Get stored private key
  Future<String?> getPrivateKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_privateKeyKey);
  }
  
  // Get stored wallet address
  Future<String?> getWalletAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_walletAddressKey);
  }
  
  // Get credentials from private key
  Future<EthPrivateKey> getCredentials() async {
    final privateKey = await getPrivateKey();
    if (privateKey == null) {
      throw Exception('No private key found. Please set up your wallet first.');
    }
    return EthPrivateKey.fromHex(privateKey);
  }
  
  // Get user's Ethereum address
  Future<EthereumAddress> getUserAddress() async {
    final credentials = await getCredentials();
    return credentials.address;
  }
  
  // Get balance of wallet in Monad
  Future<double> getBalance() async {
    await initialize();
    
    try {
      final credentials = await getCredentials();
      final balance = await _client.getBalance(credentials.address);
      return balance.getValueInUnit(EtherUnit.ether);
    } catch (e) {
      print('Error getting balance: $e');
      rethrow;
    }
  }
  
  // StreakTracker contract ABI - this is the interface definition
  String get _streakTrackerAbi => '''
[
  {
    "inputs": [],
    "name": "recordAction",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "getStreak",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "getLastActionDay",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "internalType": "address", "name": "user", "type": "address"},
      {"indexed": false, "internalType": "uint256", "name": "newStreak", "type": "uint256"}
    ],
    "name": "StreakUpdated",
    "type": "event"
  }
]
''';

  // Get StreakTracker contract
  DeployedContract _getStreakTrackerContract() {
    final contractAddress = EthereumAddress.fromHex(_streakTrackerContractAddress);
    return DeployedContract(
      ContractAbi.fromJson(_streakTrackerAbi, 'StreakTracker'),
      contractAddress,
    );
  }
  
  // Record streak on the StreakTracker contract
  Future<String> recordStreak(int streakCount, bool goalsMet, DateTime date) async {
    await initialize();
    
    try {
      // We only call the contract if goals were met
      if (!goalsMet && streakCount == 0) {
        // For streak breaks, we don't need to call the contract
        // The contract automatically resets streak when days are missed
        return "STREAK_BREAK_NO_TX_NEEDED";
      }
      
      final credentials = await getCredentials();
      final contract = _getStreakTrackerContract();
      final recordActionFunction = contract.function('recordAction');
      
      // Send the transaction to record the daily action
      final txHash = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: recordActionFunction,
          parameters: [], // No parameters needed for recordAction
          maxGas: 150000, // Adjust gas limit as needed
        ),
        chainId: _chainId,
      );
      
      print('Streak recorded on blockchain with txHash: $txHash');
      return txHash;
    } catch (e) {
      print('Failed to record streak on blockchain: $e');
      rethrow;
    }
  }
  
  // Get user's current streak from contract
  Future<int> getStreakFromContract() async {
    await initialize();
    
    try {
      final credentials = await getCredentials();
      final userAddress = credentials.address;
      final contract = _getStreakTrackerContract();
      final getStreakFunction = contract.function('getStreak');
      
      final result = await _client.call(
        contract: contract,
        function: getStreakFunction,
        params: [userAddress],
      );
      
      // Result is a BigInt
      return (result[0] as BigInt).toInt();
    } catch (e) {
      print('Error getting streak from contract: $e');
      rethrow;
    }
  }
  
  // Get user's last action day from contract
  Future<int> getLastActionDayFromContract() async {
    await initialize();
    
    try {
      final credentials = await getCredentials();
      final userAddress = credentials.address;
      final contract = _getStreakTrackerContract();
      final getLastActionDayFunction = contract.function('getLastActionDay');
      
      final result = await _client.call(
        contract: contract,
        function: getLastActionDayFunction,
        params: [userAddress],
      );
      
      // Result is a BigInt representing days since Unix epoch
      return (result[0] as BigInt).toInt();
    } catch (e) {
      print('Error getting last action day from contract: $e');
      rethrow;
    }
  }
  
  // Get estimated gas for streak recording
  Future<EtherAmount> estimateGasFee() async {
    await initialize();
    
    try {
      final credentials = await getCredentials();
      final contract = _getStreakTrackerContract();
      final recordActionFunction = contract.function('recordAction');
      
      // Create the transaction for estimation
      final transaction = Transaction.callContract(
        contract: contract,
        function: recordActionFunction,
        parameters: [],
      );
      
      // Estimate gas
      final estimatedGas = await _client.estimateGas(
        sender: credentials.address,
        to: transaction.to,
        data: transaction.data,
      );
      
      // Get gas price
      final gasPrice = await _client.getGasPrice();
      
      // Calculate fee
      return EtherAmount.inWei(
        estimatedGas * gasPrice.getInWei
      );
    } catch (e) {
      print('Error estimating gas: $e');
      rethrow;
    }
  }
  
  // Get current contract address - for display purposes only
  String getContractAddress() {
    return _streakTrackerContractAddress;
  }
  
  // Close client
  void dispose() {
    if (_isInitialized) {
      _client.dispose();
      _isInitialized = false;
    }
  }
} 