import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/streak_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'wallet_setup_screen.dart';

class StreakDebugScreen extends StatefulWidget {
  const StreakDebugScreen({Key? key}) : super(key: key);

  @override
  State<StreakDebugScreen> createState() => _StreakDebugScreenState();
}

class _StreakDebugScreenState extends State<StreakDebugScreen> {
  final StreakService _streakService = StreakService();
  Map<String, dynamic> _streakInfo = {};
  bool _isLoading = false;
  bool _hasWallet = false;
  final TextEditingController _streakValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStreakInfo();
  }

  @override
  void dispose() {
    _streakValueController.dispose();
    super.dispose();
  }

  Future<void> _loadStreakInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final info = await _streakService.debugGetStreakInfo();
      setState(() {
        _streakInfo = info;
        _hasWallet = info['hasWallet'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading streak info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _incrementStreak() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _streakService.debugIncrementStreak();
      await _loadStreakInfo();
      
      final hasBlockchainRecord = result['blockchainRecord'] != null;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasBlockchainRecord 
                ? 'Streak incremented by 1 and recorded on blockchain' 
                : 'Streak incremented by 1'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error incrementing streak: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _decrementStreak() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _streakService.debugDecrementStreak();
      await _loadStreakInfo();
      
      final hasBlockchainRecord = result['blockchainRecord'] != null;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasBlockchainRecord 
                ? 'Streak decremented by 1 and recorded on blockchain' 
                : 'Streak decremented by 1'
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error decrementing streak: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setStreak() async {
    if (_streakValueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a value')),
      );
      return;
    }

    final value = int.tryParse(_streakValueController.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _streakService.debugSetStreak(value);
      await _loadStreakInfo();
      
      final hasBlockchainRecord = result['blockchainRecord'] != null;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasBlockchainRecord 
                ? 'Streak set to $value and recorded on blockchain' 
                : 'Streak set to $value'
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error setting streak: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePenalty() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _streakService.debugTogglePenalty();
      await _loadStreakInfo();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Penalty ${result['newPenaltyStatus'] ? 'activated' : 'deactivated'}'
          ),
        ),
      );
    } catch (e) {
      print('Error toggling penalty: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetStreak() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _streakService.resetStreak();
      await _loadStreakInfo();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Streak reset to 0')),
      );
    } catch (e) {
      print('Error resetting streak: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _navigateToWalletSetup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalletSetupScreen()),
    );
    
    // Refresh data when returning
    _loadStreakInfo();
  }
  
  Future<void> _openExplorer(String txHash) async {
    final url = 'https://explorer.monad.xyz/tx/$txHash';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak Debug'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      backgroundColor: const Color(0xFF16213E),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current streak info
                  _buildInfoCard(),

                  const SizedBox(height: 20),

                  // Controls
                  _buildControls(),

                  const SizedBox(height: 20),
                  
                  // Blockchain status
                  _buildBlockchainCard(),
                  
                  const SizedBox(height: 20),

                  // Streak history
                  _buildHistoryCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: const Color(0xFF0F3460),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Streak Info',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white24),
            _buildInfoRow('Streak Count', '${_streakInfo['streakCount'] ?? 'N/A'}'),
            _buildInfoRow('On Streak', '${_streakInfo['isOnStreak'] ?? 'N/A'}'),
            _buildInfoRow('Last Updated', _formatDate(_streakInfo['lastStreakDate'])),
            _buildInfoRow('Penalty Active', '${_streakInfo['isPenaltyActive'] ?? 'N/A'}'),
            _buildInfoRow('Missed Date', _formatDate(_streakInfo['missedDate'])),
            _buildInfoRow('Wallet Connected', _hasWallet ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      color: const Color(0xFF0F3460),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Controls',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _incrementStreak,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('+ Increment'),
                ),
                ElevatedButton(
                  onPressed: _decrementStreak,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('- Decrement'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _streakValueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Set Streak Value',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _setStreak,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Set'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _togglePenalty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Toggle Penalty'),
                ),
                ElevatedButton(
                  onPressed: _resetStreak,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadStreakInfo,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _navigateToWalletSetup,
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Wallet Setup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBlockchainCard() {
    final blockchainRecords = (_streakInfo['blockchainRecords'] as List<dynamic>? ?? [])
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();
    
    return Card(
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
                  'Blockchain Records',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (!_hasWallet)
                  TextButton.icon(
                    onPressed: _navigateToWalletSetup,
                    icon: const Icon(Icons.link, color: Colors.blue),
                    label: Text(
                      'Connect Wallet',
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(color: Colors.white24),
            if (!_hasWallet)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Wallet not connected',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect a wallet to record streaks on the blockchain',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (blockchainRecords.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No blockchain records yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Streak updates will be recorded on the blockchain',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  ...blockchainRecords.map((record) => _buildTransactionCard(record)).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionCard(Map<String, dynamic> record) {
    final date = DateTime.parse(record['timestamp']);
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Streak: ${record['streakCount']}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: record['goalsMet'] ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: record['goalsMet'] ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  record['goalsMet'] ? 'Goals Met' : 'Goals Missed',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: record['goalsMet'] ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Date: $formattedDate',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'TX: ${_shortenHash(record['txHash'])}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _openExplorer(record['txHash']),
                icon: const Icon(Icons.open_in_new, color: Colors.blue, size: 18),
                tooltip: 'View on Explorer',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    final history = _streakInfo['streakHistory'] as List<dynamic>? ?? [];
    
    return Card(
      color: const Color(0xFF0F3460),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Streak History',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white24),
            history.isEmpty
                ? const Center(
                    child: Text(
                      'No history found',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : Column(
                    children: history.map((entry) {
                      return _buildHistoryRow(
                        _formatDate(entry['date']),
                        '${entry['streak']}',
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white24),
            Text(
              'Raw Data',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Text(
                const JsonEncoder.withIndent('  ').convert(_streakInfo),
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(String date, String streak) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            streak,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }
  
  String _shortenHash(String hash) {
    if (hash.length <= 12) return hash;
    return '${hash.substring(0, 6)}...${hash.substring(hash.length - 6)}';
  }
} 