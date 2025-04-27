import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/streak_service.dart';
import 'package:intl/intl.dart';

class StellarTokenInfo extends StatefulWidget {
  const StellarTokenInfo({Key? key}) : super(key: key);

  @override
  State<StellarTokenInfo> createState() => _StellarTokenInfoState();
}

class _StellarTokenInfoState extends State<StellarTokenInfo> {
  String _tokenBalance = "0";
  bool _isLoading = true;
  Map<String, String> _accountInfo = {};
  
  @override
  void initState() {
    super.initState();
    _loadTokenInfo();
  }
  
  Future<void> _loadTokenInfo() async {
    try {
      final streakService = StreakService();
      final balance = await streakService.getStellarTokenBalance();
      final accountInfo = await streakService.getStellarAccountInfo();
      
      setState(() {
        _tokenBalance = balance;
        _accountInfo = accountInfo;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading token info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.token,
                  color: Colors.purpleAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Streak Tokens',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Token balance
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amberAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Balance:',
                          style: GoogleFonts.montserrat(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_tokenBalance TOKENS',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Reward explanation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.purpleAccent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.purpleAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Token Rewards',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Earn Stellar-based CALS tokens for reaching streak milestones:',
                            style: GoogleFonts.montserrat(
                              color: Colors.grey[300],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Milestone rewards
                          _buildMilestoneRow('3 days', '1 token'),
                          _buildMilestoneRow('7 days', '3 tokens'),
                          _buildMilestoneRow('10 days', '4 tokens'),
                          _buildMilestoneRow('15 days', '5 tokens'),
                          _buildMilestoneRow('21 days', '7 tokens'),
                          _buildMilestoneRow('25 days', '8 tokens'),
                          _buildMilestoneRow('30 days', '10 tokens'),
                          const SizedBox(height: 8),
                          Text(
                            'Tokens are automatically sent to your wallet when milestones are reached.',
                            style: GoogleFonts.montserrat(
                              color: Colors.grey[400],
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
  
  Widget _buildMilestoneRow(String milestone, String reward) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(
            Icons.circle,
            color: Colors.purpleAccent.withOpacity(0.5),
            size: 8,
          ),
          const SizedBox(width: 8),
          Text(
            milestone,
            style: GoogleFonts.montserrat(
              color: Colors.grey[300],
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            reward,
            style: GoogleFonts.montserrat(
              color: Colors.purpleAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}