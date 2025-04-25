import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/monad_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ContractSetupScreen extends StatefulWidget {
  const ContractSetupScreen({Key? key}) : super(key: key);

  @override
  State<ContractSetupScreen> createState() => _ContractSetupScreenState();
}

class _ContractSetupScreenState extends State<ContractSetupScreen> {
  bool _isLoading = false;
  String _contractAddress = '';
  bool _isWalletSetup = false;
  
  @override
  void initState() {
    super.initState();
    _checkExistingContract();
  }
  
  Future<void> _checkExistingContract() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final monadService = MonadService();
      
      // Check if wallet is set up
      _isWalletSetup = await monadService.isWalletSetup();
      
      // Get current contract address
      _contractAddress = monadService.getContractAddress();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking contract: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _openHardhatDeployGuide() async {
    const url = 'https://hardhat.org/tutorial/deploying-to-a-live-network';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open deployment guide'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _openMonadExplorerLink() async {
    final url = 'https://testnet.monadexplorer.com/address/$_contractAddress';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open explorer link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('StreakTracker Contract', style: GoogleFonts.montserrat()),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (!_isWalletSetup) {
      return Scaffold(
        appBar: AppBar(
          title: Text('StreakTracker Contract', style: GoogleFonts.montserrat()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined, 
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'Wallet Setup Required',
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You need to set up your wallet before you can view the StreakTracker contract details.',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('StreakTracker Contract', style: GoogleFonts.montserrat()),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contract Information',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Contract configured and ready to use',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contract Address:',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _contractAddress,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.content_copy, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _contractAddress));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Contract address copied to clipboard'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _openMonadExplorerLink,
                              icon: const Icon(Icons.open_in_new),
                              label: Text(
                                'View on Monad Explorer',
                                style: GoogleFonts.montserrat(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'About StreakTracker Contract',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This smart contract tracks your daily streaks on the Monad blockchain, providing transparent and immutable streak records.',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Features:',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureItem('Records daily actions on blockchain'),
                      _buildFeatureItem('Automatic streak tracking'),
                      _buildFeatureItem('Streak resets on missed days'),
                      _buildFeatureItem('Transparent history via blockchain explorer'),
                      const SizedBox(height: 20),
                      Text(
                        'When you complete your daily nutrition goals, your streak is automatically recorded on the Monad blockchain.',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Technical Information',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contract deployed on Monad Testnet',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Blockchain: Monad',
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Network: Testnet',
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Chain ID: 10143',
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        onPressed: _openHardhatDeployGuide,
                        icon: const Icon(Icons.open_in_new),
                        label: Text(
                          'Learn About Blockchain Deployment',
                          style: GoogleFonts.montserrat(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
} 