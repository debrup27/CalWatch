import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/monad_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';

class WalletSetupScreen extends StatefulWidget {
  const WalletSetupScreen({Key? key}) : super(key: key);

  @override
  State<WalletSetupScreen> createState() => _WalletSetupScreenState();
}

class _WalletSetupScreenState extends State<WalletSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _privateKeyController = TextEditingController();
  bool _isLoading = false;
  String? _walletAddress;
  double _balance = 0.0;
  
  @override
  void initState() {
    super.initState();
    _checkExistingWallet();
  }
  
  @override
  void dispose() {
    _privateKeyController.dispose();
    super.dispose();
  }
  
  Future<void> _checkExistingWallet() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final monadService = MonadService();
      await monadService.initialize();
      
      final isSetup = await monadService.isWalletSetup();
      if (isSetup) {
        final address = await monadService.getWalletAddress();
        
        // Try to get balance
        try {
          _balance = await monadService.getBalance();
        } catch (e) {
          print('Error getting balance: $e');
          _balance = 0.0;
        }
        
        setState(() {
          _walletAddress = address;
        });
      }
    } catch (e) {
      print('Error checking wallet: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _setupWallet() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final privateKey = _privateKeyController.text.trim();
      
      final monadService = MonadService();
      await monadService.initialize();
      await monadService.storePrivateKey(privateKey);
      
      final address = await monadService.getWalletAddress();
      
      // Try to get balance
      try {
        _balance = await monadService.getBalance();
      } catch (e) {
        print('Error getting balance: $e');
        _balance = 0.0;
      }
      
      setState(() {
        _walletAddress = address;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet setup successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting up wallet: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _refreshBalance() async {
    if (_walletAddress == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final monadService = MonadService();
      await monadService.initialize();
      
      _balance = await monadService.getBalance();
      
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Balance updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing balance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _estimateGasFee() async {
    if (_walletAddress == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final monadService = MonadService();
      await monadService.initialize();
      
      final gasEstimate = await monadService.estimateGasFee();
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Estimated Gas Fee',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Recording a streak on the Monad blockchain will cost approximately:\n\n'
            '${gasEstimate.getValueInUnit(EtherUnit.gwei)} gwei\n'
            '${gasEstimate.getValueInUnit(EtherUnit.ether)} MONAD',
            style: GoogleFonts.montserrat(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.montserrat(),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error estimating gas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _openBlockExplorer() async {
    if (_walletAddress == null) return;
    
    final url = 'https://explorer.monad.xyz/address/$_walletAddress';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open explorer: $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blockchain Setup',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monad Blockchain Integration',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connect your wallet to record your streaks on the Monad blockchain for permanent, verifiable tracking.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (_walletAddress != null) ...[
                    Card(
                      color: const Color(0xFF0F3460),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Connected Wallet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh, color: Colors.white),
                                  onPressed: _refreshBalance,
                                  tooltip: 'Refresh Balance',
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 8),
                            _buildWalletInfoRow('Address', _walletAddress!),
                            const SizedBox(height: 8),
                            _buildWalletInfoRow('Balance', '$_balance MONAD'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _estimateGasFee,
                                  icon: const Icon(Icons.local_gas_station),
                                  label: const Text('Estimate Gas'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _openBlockExplorer,
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('View in Explorer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Card(
                      color: const Color(0xFF0F3460),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connect Your Wallet',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _privateKeyController,
                                decoration: InputDecoration(
                                  labelText: 'Private Key',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  hintText: 'Enter your Monad wallet private key',
                                  hintStyle: const TextStyle(color: Colors.white30),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white30),
                                  ),
                                  prefixIcon: const Icon(Icons.key, color: Colors.white70),
                                ),
                                style: const TextStyle(color: Colors.white),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a private key';
                                  }
                                  
                                  final cleanValue = value.startsWith('0x') ? value.substring(2) : value;
                                  if (cleanValue.length != 64) {
                                    return 'Private key should be 64 characters (without 0x prefix)';
                                  }
                                  
                                  // Check if key is hexadecimal
                                  final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
                                  if (!hexRegex.hasMatch(cleanValue)) {
                                    return 'Private key should only contain hexadecimal characters';
                                  }
                                  
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _setupWallet,
                                  icon: const Icon(Icons.link),
                                  label: const Text('Connect Wallet'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  Card(
                    color: const Color(0xFF0F3460),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About Blockchain Integration',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 8),
                          _buildBulletPoint('Your streaks will be recorded on the Monad blockchain'),
                          _buildBulletPoint('Each streak update will create a blockchain transaction'),
                          _buildBulletPoint('You\'ll need MONAD tokens for transaction fees'),
                          _buildBulletPoint('Your achievements will be permanently verifiable'),
                          _buildBulletPoint('Currently using Monad Testnet (testnet-rpc.monad.xyz)'),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton.icon(
                              onPressed: () async {
                                const url = 'https://docs.monad.xyz/';
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.info, color: Colors.blue),
                              label: Text(
                                'Learn More About Monad',
                                style: GoogleFonts.poppins(
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildWalletInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 