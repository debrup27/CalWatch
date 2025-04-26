import 'package:flutter/material.dart';
import '../services/streak_service.dart';

class StellarTokenInfo extends StatefulWidget {
  const StellarTokenInfo({super.key});

  @override
  State<StellarTokenInfo> createState() => _StellarTokenInfoState();
}

class _StellarTokenInfoState extends State<StellarTokenInfo> {
  final StreakService _streakService = StreakService();
  String _tokenBalance = "0";
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = "";
  bool _isAtMilestone = false;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadTokenInfo();
  }

  Future<void> _loadTokenInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // First check if eligible for reward
      final rewardVerification = await _streakService.debugVerifyRewardSystem();
      final isEligibleForReward = rewardVerification['eligibleForReward'] == true;
      _currentStreak = rewardVerification['currentStreak'] ?? 0;
      _isAtMilestone = rewardVerification['isAtMilestone'] == true;
      
      // If eligible, issue reward before getting balance
      if (isEligibleForReward) {
        final rewardResult = await _streakService.debugForceReward();
        final currentStreak = rewardVerification['currentStreak'];
        
        // Show notification about tokens being awarded
        if (rewardResult['rewardSuccess'] == true) {
          final tokensAwarded = _getTokenAmountForStreak(currentStreak);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Congratulations! You earned $tokensAwarded STREAK tokens for your $currentStreak-day streak!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          // Reset milestone status after awarding
          _isAtMilestone = false;
        }
      }

      // Now get the token balance (which will include any newly issued tokens)
      final balance = await _streakService.getStellarTokenBalance();
      
      setState(() {
        _tokenBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Helper method to determine token amount based on streak milestone
  String _getTokenAmountForStreak(int streak) {
    if (streak >= 30) return "10";
    if (streak >= 7) return "3";
    if (streak >= 3) return "1";
    return "0";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Streak Tokens",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadTokenInfo,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_hasError)
              Text(
                "Error loading token info: $_errorMessage",
                style: TextStyle(color: Colors.red),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Balance:",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        "$_tokenBalance STREAK",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_isAtMilestone) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.celebration, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Congratulations! You've reached a $_currentStreak-day streak milestone in your current streak cycle! Refresh to claim your tokens.",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  const Text(
                    "Earn tokens at these streak milestones:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildMilestoneRow("3-day streak", "1 token", _currentStreak == 3),
                  const SizedBox(height: 4),
                  _buildMilestoneRow("7-day streak", "3 tokens", _currentStreak == 7),
                  const SizedBox(height: 4),
                  _buildMilestoneRow("30-day streak", "10 tokens", _currentStreak == 30),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneRow(String milestone, String reward, bool isCurrentMilestone) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (isCurrentMilestone) 
              const Icon(Icons.emoji_events, color: Colors.amber, size: 16)
            else
              const SizedBox(width: 16),
            Text(
              milestone,
              style: TextStyle(
                fontWeight: isCurrentMilestone ? FontWeight.bold : FontWeight.normal,
                color: isCurrentMilestone ? Colors.amber : null,
              ),
            ),
          ],
        ),
        Text(
          reward,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCurrentMilestone ? Colors.amber : null,
          ),
        ),
      ],
    );
  }
} 